import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:arrows/features/game/data/level_generator.dart';
import 'package:arrows/features/game/data/progress_service.dart';
import 'package:arrows/features/game/domain/arrow.dart';
import 'package:arrows/features/game/domain/board.dart';
import 'package:arrows/features/game/domain/board_shape.dart';
import 'package:arrows/features/game/domain/direction.dart';
import 'package:arrows/features/game/domain/grid_point.dart';
import 'package:arrows/features/game/domain/solver.dart';
import 'package:arrows/features/game/presentation/controllers/game_controller.dart';

void main() {
  group('Board escape rules', () {
    test('arrow escapes when ray is clear', () {
      final board = Board(columns: 10, rows: 10);
      final arrow = Arrow(
        id: 0,
        points: const [GridPoint(1, 1), GridPoint(2, 1), GridPoint(3, 1)],
        direction: Direction.right,
        colorValue: 0xFF00FF00,
      );
      board.addArrow(arrow);
      expect(board.canEscape(arrow), isTrue);
      expect(board.escapeRay(arrow), isNotEmpty);
    });

    test('other arrow on ray blocks escape', () {
      final board = Board(columns: 10, rows: 10);
      final a = Arrow(
        id: 0,
        points: const [GridPoint(0, 2), GridPoint(1, 2), GridPoint(2, 2)],
        direction: Direction.right,
        colorValue: 0xFF00FF00,
      );
      final blocker = Arrow(
        id: 1,
        points: const [GridPoint(5, 2), GridPoint(5, 3)],
        direction: Direction.down,
        colorValue: 0xFFFF0000,
      );
      board.addArrow(a);
      board.addArrow(blocker);

      expect(board.canEscape(a), isFalse);
      expect(board.blockingCells(a), contains(const GridPoint(5, 2)));

      board.removeArrow(blocker);
      expect(board.canEscape(a), isTrue);
    });

    test('heads facing each other across a silhouette hole are both blocked', () {
      final playable = <GridPoint>{
        for (var x = 0; x <= 3; x++) GridPoint(x, 2),
        for (var x = 6; x <= 9; x++) GridPoint(x, 2),
      };
      final shape = BoardShape(
        columns: 10,
        rows: 5,
        kind: BoardShapeKind.strip,
        playable: playable,
      );
      final board = Board(columns: 10, rows: 5, shape: shape);
      final left = Arrow(
        id: 0,
        points: const [GridPoint(1, 2), GridPoint(2, 2), GridPoint(3, 2)],
        direction: Direction.right,
        colorValue: 0xFF00FF00,
      ).syncedFacing();
      final right = Arrow(
        id: 1,
        points: const [GridPoint(8, 2), GridPoint(7, 2), GridPoint(6, 2)],
        direction: Direction.left,
        colorValue: 0xFFFF0000,
      ).syncedFacing();
      board.addArrow(left);
      board.addArrow(right);

      expect(left.facing, Direction.right);
      expect(right.facing, Direction.left);
      expect(board.canEscape(left), isFalse);
      expect(board.canEscape(right), isFalse);
    });

    test('tip facing own body is not escapable', () {
      // Head at (1,0) faces left into own cell (0,0).
      final facesOwn = Arrow(
        id: 0,
        points: const [
          GridPoint(0, 0),
          GridPoint(0, 1),
          GridPoint(1, 1),
          GridPoint(2, 1),
          GridPoint(2, 0),
          GridPoint(1, 0),
        ],
        direction: Direction.left,
        colorValue: 0xFF00FF00,
      ).syncedFacing();
      expect(facesOwn.facing, Direction.left);
      final board = Board(columns: 8, rows: 8)..addArrow(facesOwn);
      expect(board.canEscape(facesOwn), isFalse);
    });

    test('level complete when board empty', () {
      final board = Board(columns: 5, rows: 5);
      expect(board.isComplete, isTrue);
      final arrow = Arrow(
        id: 0,
        points: const [GridPoint(0, 0), GridPoint(1, 0)],
        direction: Direction.right,
        colorValue: 0xFF0000FF,
      );
      board.addArrow(arrow);
      expect(board.isComplete, isFalse);
      board.removeArrow(arrow);
      expect(board.isComplete, isTrue);
    });
  });

  group('LevelSolver', () {
    test('detects solvable and unsolvable configs', () {
      final solvable = Board(columns: 8, rows: 8);
      solvable.addArrow(
        Arrow(
          id: 0,
          points: const [GridPoint(1, 1), GridPoint(2, 1)],
          direction: Direction.right,
          colorValue: 0xFF00FF00,
        ),
      );
      expect(LevelSolver.isSolvable(solvable), isTrue);

      final stuck = Board(columns: 6, rows: 6);
      // Two arrows head-to-head blocking each other on the same row.
      stuck.addArrow(
        Arrow(
          id: 0,
          points: const [GridPoint(1, 2), GridPoint(2, 2)],
          direction: Direction.right,
          colorValue: 0xFF00FF00,
        ),
      );
      stuck.addArrow(
        Arrow(
          id: 1,
          points: const [GridPoint(4, 2), GridPoint(3, 2)],
          direction: Direction.left,
          colorValue: 0xFFFF0000,
        ),
      );
      // id0 ray hits (3,2) occupied by id1; id1 ray hits (2,2) occupied by id0.
      expect(LevelSolver.isSolvable(stuck), isFalse);
    });
  });

  group('LevelGenerator', () {
    test('generates non-empty solvable levels for early difficulties', () {
      for (var level = 1; level <= 2; level++) {
        final size = LevelScaling.boardSizeForLevel(level);
        final data = LevelGenerator.forLevel(
          columns: size.$1,
          rows: size.$2,
          level: level,
        ).generate();
        expect(data.arrows, isNotEmpty, reason: 'level $level');
        expect(
          data.arrows.length,
          greaterThanOrEqualTo(3),
          reason: 'level $level arrow count',
        );

        final board = Board(
          columns: size.$1,
          rows: size.$2,
          shape: data.shape,
        );
        for (final a in data.arrows) {
          board.addArrow(a);
        }
        var removed = 0;
        while (board.arrows.isNotEmpty) {
          final free = board.arrows.where(board.canEscape).toList();
          expect(free, isNotEmpty, reason: 'L$level stuck at $removed');
          board.removeArrow(free.first);
          removed++;
        }
      }
    });

    test('arrow count jumps by +32 each level', () {
      expect(LevelScaling.forLevel(1).arrowCount, 32);
      expect(LevelScaling.forLevel(2).arrowCount, 64);
      expect(LevelScaling.forLevel(3).arrowCount, 96);
      expect(LevelScaling.forLevel(4).arrowCount, 128);

      for (var level = 1; level < 5; level++) {
        final a = LevelScaling.forLevel(level);
        final b = LevelScaling.forLevel(level + 1);
        expect(b.arrowCount - a.arrowCount, 32);
      }
    });

    test('arrow heads never point into their own body', () {
      for (var level = 1; level <= 5; level++) {
        final size = LevelScaling.boardSizeForLevel(level);
        final data = LevelGenerator.forLevel(
          columns: size.$1,
          rows: size.$2,
          level: level,
        ).generate();
        for (final a in data.arrows) {
          expect(a.facing, a.direction, reason: 'L$level id=${a.id}');
          final self = a.points.toSet();
          var x = a.head.x + a.facing.dx;
          var y = a.head.y + a.facing.dy;
          while (x >= 0 &&
              x < size.$1 &&
              y >= 0 &&
              y < size.$2) {
            expect(
              self.contains(GridPoint(x, y)),
              isFalse,
              reason: 'L$level id=${a.id} tip faces own body at ($x,$y)',
            );
            x += a.facing.dx;
            y += a.facing.dy;
          }
        }
      }
    });

    test('each level uses a distinct board shape kind', () {
      final kinds = <Object>{};
      for (var level = 1; level <= BoardShapeKind.values.length; level++) {
        final size = LevelScaling.boardSizeForLevel(level);
        final data = LevelGenerator.forLevel(
          columns: size.$1,
          rows: size.$2,
          level: level,
        ).generate();
        kinds.add(data.shape.kind);
      }
      expect(kinds.length, BoardShapeKind.values.length);
    });
  });

  group('GameController hearts', () {
    test('blocked taps cost hearts and reach game over', () async {
      SharedPreferences.setMockInitialValues({});
      await progressService.initialize();

      final controller = GameController()..onInit();
      controller.startGame();

      final blocked = controller.game.arrows.where(
        (a) => !controller.game.canEscape(a),
      );
      if (blocked.isEmpty) {
        // Rare: every arrow free — skip heart drain assert.
        return;
      }

      final target = blocked.first;
      final before = controller.game.arrows.length;

      for (var i = 0; i < GameController.maxHearts; i++) {
        final escaped = controller.game.tryRemove(target);
        expect(escaped, isFalse);
      }

      expect(controller.game.arrows.length, before);
      expect(controller.hearts.value, 0);
      expect(controller.isGameOver.value, isTrue);
    });

    test('undo restores a miss-tapped blocked arrow heart', () async {
      SharedPreferences.setMockInitialValues({});
      await progressService.initialize();

      final controller = GameController()..onInit();
      controller.startGame();

      final blocked = controller.game.arrows.where(
        (a) => !controller.game.canEscape(a),
      );
      if (blocked.isEmpty) return;

      controller.game.tryRemove(blocked.first);
      expect(controller.hearts.value, GameController.maxHearts - 1);
      expect(controller.canUndo.value, isTrue);

      controller.undo();

      expect(controller.hearts.value, GameController.maxHearts);
      expect(controller.isGameOver.value, isFalse);
    });

    test('clearing escapable arrows empties the board', () async {
      SharedPreferences.setMockInitialValues({});
      await progressService.initialize();

      final controller = GameController()..onInit();
      controller.startGame();

      var guard = 0;
      while (controller.game.arrows.isNotEmpty && guard < 200) {
        guard++;
        final escapable = controller.game.arrows
            .where(controller.game.canEscape)
            .toList();
        if (escapable.isEmpty) break;
        controller.game.tryRemove(escapable.first);
      }

      expect(controller.game.arrows, isEmpty);
    });

    test('next level advances and restores hearts', () async {
      SharedPreferences.setMockInitialValues({});
      await progressService.initialize();

      final controller = GameController()..onInit();
      controller.startGame();
      controller.hearts.value = 1;
      controller.isLevelComplete.value = true;

      controller.nextLevel();

      expect(controller.level.value, 2);
      expect(controller.hearts.value, GameController.maxHearts);
      expect(controller.isLevelComplete.value, isFalse);
      expect(controller.game.arrows, isNotEmpty);
    });
  });
}
