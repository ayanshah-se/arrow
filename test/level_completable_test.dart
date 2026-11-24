import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:arrows/features/game/data/level_generator.dart';
import 'package:arrows/features/game/domain/arrow.dart';
import 'package:arrows/features/game/domain/board.dart';
import 'package:arrows/features/game/domain/direction.dart';
import 'package:arrows/features/game/domain/grid_point.dart';

void main() {
  test('levels 1-5 pack near target and are greedily completable', () {
    for (final level in [1, 2, 3, 4, 5]) {
      final size = LevelScaling.boardSizeForLevel(level);
      final data = LevelGenerator.forLevel(
        columns: size.$1,
        rows: size.$2,
        level: level,
      ).generate();
      final arrows = data.arrows;
      final playable = data.shape.cellCount;

      expect(
        arrows.length,
        greaterThanOrEqualTo(max(6, playable ~/ 25)),
        reason:
            'L$level got ${arrows.length}, want dense pack '
            'on ${data.shape.kind.name} ($playable cells)',
      );

      final cells = arrows.fold<int>(0, (s, a) => s + a.points.length);
      final fill = cells / playable;
      expect(
        fill,
        greaterThan(0.5),
        reason: 'L$level fill ${fill.toStringAsFixed(2)} too sparse',
      );

      final board = Board(
        columns: size.$1,
        rows: size.$2,
        shape: data.shape,
      );
      for (final a in arrows) {
        board.addArrow(a);
      }

      var removed = 0;
      while (board.arrows.isNotEmpty) {
        final free = board.arrows.where(board.canEscape).toList();
        expect(
          free,
          isNotEmpty,
          reason: 'L$level stuck after $removed/${arrows.length}',
        );
        board.removeArrow(free.first);
        removed++;
      }
    }
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('legacy unsolvable-style layout is not used; peel order works', () {
    // The old broken fallback blocked every arrow; this layout must stay free.
    final arrows = <Arrow>[
      Arrow(
        id: 0,
        points: const [GridPoint(1, 2), GridPoint(2, 2), GridPoint(3, 2)],
        direction: Direction.left,
        colorValue: arrowPalette[0],
      ),
      Arrow(
        id: 1,
        points: const [GridPoint(5, 2), GridPoint(6, 2), GridPoint(7, 2)],
        direction: Direction.right,
        colorValue: arrowPalette[1],
      ),
      Arrow(
        id: 2,
        points: const [GridPoint(4, 0), GridPoint(4, 1), GridPoint(4, 2)],
        direction: Direction.down,
        colorValue: arrowPalette[2],
      ),
    ];
    final board = Board(columns: 18, rows: 26);
    for (final a in arrows) {
      board.addArrow(a);
    }
    expect(board.arrows.where(board.canEscape), isNotEmpty);
    while (board.arrows.isNotEmpty) {
      final free = board.arrows.where(board.canEscape).toList();
      expect(free, isNotEmpty);
      board.removeArrow(free.first);
    }
  });
}
