import 'dart:math';

import '../domain/arrow.dart';
import '../domain/board.dart';
import '../domain/board_shape.dart';
import '../domain/direction.dart';
import '../domain/grid_point.dart';

enum LevelDifficulty { easy, medium, hard, expert }

extension LevelDifficultyX on LevelDifficulty {
  (int min, int max) get arrowCount => switch (this) {
    LevelDifficulty.easy => (3, 6),
    LevelDifficulty.medium => (7, 12),
    LevelDifficulty.hard => (12, 18),
    LevelDifficulty.expert => (16, 26),
  };

  (int min, int max) get pathLength => (4, 12);

  double get diagonalChance => 0;

  double get turnBias => 0.7;
}

/// Soft palette (original game colors).
const arrowPalette = <int>[
  0xFF4CAF50,
  0xFF2196F3,
  0xFFFF7043,
  0xFFAB47BC,
  0xFFFFCA28,
  0xFF26A69A,
  0xFFEF5350,
  0xFF5C6BC0,
];

class LevelData {
  const LevelData({required this.arrows, required this.shape});
  final List<Arrow> arrows;
  final BoardShape shape;
}

class LevelScaling {
  const LevelScaling({
    required this.arrowCount,
    required this.pathLength,
    required this.diagonalChance,
    required this.turnBias,
    required this.difficulty,
    required this.featureBlocks,
    required this.nestedBias,
  });

  final int arrowCount;
  final (int min, int max) pathLength;
  final double diagonalChance;
  final double turnBias;
  final LevelDifficulty difficulty;
  final int featureBlocks;
  final double nestedBias;

  factory LevelScaling.forLevel(int level) {
    final l = level < 1 ? 1 : level;
    // L1=32, then +32 each level (dense interlocking packs).
    final desired = 32 + (l - 1) * 32;
    final difficulty = switch (l) {
      1 => LevelDifficulty.medium,
      2 => LevelDifficulty.hard,
      _ => LevelDifficulty.expert,
    };
    return LevelScaling(
      arrowCount: desired,
      pathLength: (6, 16 + l * 2),
      diagonalChance: 0,
      turnBias: min(0.94, 0.64 + l * 0.05),
      difficulty: difficulty,
      featureBlocks: min(12, 3 + l * 2),
      nestedBias: min(0.85, 0.35 + l * 0.08),
    );
  }

  static (int columns, int rows) boardSizeForLevel(int level) {
    final desired = 32 + (max(1, level) - 1) * 32;
    return boardSizeForArrowCount(desired);
  }

  static (int columns, int rows) boardSizeForArrowCount(int arrows) {
    var cols = 24;
    var rows = 32;
    // Iconic silhouettes use ~35–70% of the bbox — oversize the grid.
    final needed = (arrows * 8.4).ceil() + 96;
    while (cols * rows < needed && (cols < 56 || rows < 72)) {
      if (cols < 56) cols += 2;
      if (rows < 72) rows += 2;
    }
    return (cols, rows);
  }
}

/// Dense winding-snake generator constrained to iconic board silhouettes.
class LevelGenerator {
  LevelGenerator({
    required this.columns,
    required this.rows,
    required int seed,
    required this.level,
    this.difficulty = LevelDifficulty.medium,
    this.targetArrowCount,
    this.featureBlocks = 3,
    this.nestedBias = 0.35,
  }) : _seed = seed,
       _random = Random(seed);

  factory LevelGenerator.forLevel({
    required int columns,
    required int rows,
    required int level,
  }) {
    final scaling = LevelScaling.forLevel(level);
    return LevelGenerator(
      columns: columns,
      rows: rows,
      seed: level * 9827 + 17,
      level: level,
      difficulty: scaling.difficulty,
      targetArrowCount: scaling.arrowCount,
      featureBlocks: scaling.featureBlocks,
      nestedBias: scaling.nestedBias,
    );
  }

  final int columns;
  final int rows;
  final int level;
  final int _seed;
  final LevelDifficulty difficulty;
  final int? targetArrowCount;
  final int featureBlocks;
  final double nestedBias;
  final Random _random;

  final Set<GridPoint> _occupied = {};
  late BoardShape _shape;

  LevelData generate() {
    LevelData? best;
    for (var attempt = 0; attempt < 8; attempt++) {
      _occupied.clear();
      _shape = BoardShape.forLevel(
        columns: columns,
        rows: rows,
        level: level,
        seed: _seed + attempt * 97,
      );
      final arrows = _generateDense();
      if (arrows == null || arrows.isEmpty) continue;
      final data = LevelData(arrows: arrows, shape: _shape);
      if (best == null || arrows.length > best.arrows.length) best = data;
      final playable = _shape.cellCount;
      final fill = _cellCount(arrows) / playable;
      if (fill >= 0.68 && arrows.length >= 10) return data;
    }
    if (best != null && best.arrows.length >= 3) return best;
    _shape = BoardShape.forLevel(
      columns: columns,
      rows: rows,
      level: level,
      seed: _seed,
    );
    return LevelData(arrows: _fallback(), shape: _shape);
  }

  int _cellCount(List<Arrow> arrows) =>
      arrows.fold(0, (s, a) => s + a.points.length);

  bool _isFree(int x, int y) =>
      _shape.contains(x, y) && !_occupied.contains(GridPoint(x, y));

  List<Arrow>? _generateDense() {
    final drafts = <Arrow>[];

    // Reverse-constructed winding snakes (reference-style dense packs).
    drafts.addAll(_fillWithWindingSnakes());
    drafts.addAll(_fillWithWindingSnakesShort());

    // Tiny leftover runs (≥2) via reverse construction only — no bands.
    var stall = 0;
    while (_freeCount() >= 2 && stall < 40) {
      final placed = _placeEscapableSnake(4, 2);
      if (placed == null) {
        stall++;
        continue;
      }
      stall = 0;
      drafts.add(placed);
    }

    if (drafts.length < 3) return null;

    final finalized = <Arrow>[
      for (var i = 0; i < drafts.length; i++)
        drafts[i].syncedFacing().copyWith(
          id: i,
          colorValue: arrowPalette[i % arrowPalette.length],
        ),
    ];

    if (!_isGreedilySolvable(finalized)) return null;
    return _shuffleIds(finalized);
  }

  List<Arrow> _fillWithWindingSnakesShort() {
    final arrows = <Arrow>[];
    var guard = 0;
    while (guard < _shape.cellCount && _freeCount() >= 3) {
      guard++;
      final placed = _placeEscapableSnake(8, 3);
      if (placed == null) break;
      arrows.add(placed);
    }
    return arrows;
  }

  /// Grow multi-turn snakes via reverse construction (always greedily solvable).
  List<Arrow> _fillWithWindingSnakes() {
    final arrows = <Arrow>[];
    final maxLen = min(84, 20 + level * 10);
    final minLen = level <= 1 ? 4 : 5;
    var guard = 0;
    final budget = _shape.cellCount;

    while (guard < budget * 3 && _freeCount() >= minLen) {
      guard++;
      final placed = _placeEscapableSnake(maxLen, minLen);
      if (placed == null) break;
      arrows.add(placed);
      if (arrows.length >= (targetArrowCount ?? 160) * 2) break;
    }
    return arrows;
  }

  int _freeCount() {
    var n = 0;
    for (final p in _shape.playable) {
      if (!_occupied.contains(p)) n++;
    }
    return n;
  }

  /// Places one snake whose head can escape through currently free cells.
  Arrow? _placeEscapableSnake(int maxLen, int minLen) {
    final candidates = <(GridPoint, Direction, int)>[];
    for (final p in _shape.playable) {
      if (_occupied.contains(p)) continue;
      for (final d in DirectionX.cardinal) {
        final back = GridPoint(p.x - d.dx, p.y - d.dy);
        if (!_isFree(back.x, back.y)) continue;
        // Prefer a short straight stem so the tip clearly points out, not at a fold.
        final back2 = GridPoint(p.x - 2 * d.dx, p.y - 2 * d.dy);
        if (minLen >= 3 && !_isFree(back2.x, back2.y)) continue;
        if (!_rayClear(p, d)) continue;
        // Rank: fewer steps to leave the board = clearer outward tip.
        var dist = 0;
        var x = p.x + d.dx;
        var y = p.y + d.dy;
        while (x >= 0 && x < columns && y >= 0 && y < rows) {
          dist++;
          x += d.dx;
          y += d.dy;
        }
        candidates.add((p, d, dist));
      }
    }
    if (candidates.isEmpty) return null;
    candidates.shuffle(_random);
    // Later levels bury heads deeper so more arrows block the peel order.
    if (level <= 1) {
      candidates.sort((a, b) => a.$3.compareTo(b.$3));
    } else {
      candidates.sort((a, b) => b.$3.compareTo(a.$3));
    }

    for (final (head, escapeDir, _) in candidates.take(min(80, candidates.length))) {
      final body = _growBackward(head, escapeDir, maxLen);
      if (body.length < minLen) continue;
      final arrow = Arrow(
        id: -1,
        points: body,
        direction: escapeDir,
        colorValue: 0,
      ).syncedFacing();
      if (arrow.facing != escapeDir) continue;
      if (_pointsOntoOwnBody(arrow)) continue;
      if (!_rayClear(arrow.head, arrow.facing)) continue;
      _occupied.addAll(body);
      return arrow;
    }
    return null;
  }

  bool _rayClear(GridPoint head, Direction d) {
    var x = head.x + d.dx;
    var y = head.y + d.dy;
    var steps = 0;
    // Full grid ray — same rule as Board.escapeRay.
    while (x >= 0 && x < columns && y >= 0 && y < rows && steps < 120) {
      if (_occupied.contains(GridPoint(x, y))) return false;
      x += d.dx;
      y += d.dy;
      steps++;
    }
    return true;
  }

  /// Cells on the escape ray from [head] (exclusive) until leaving the board.
  Set<GridPoint> _escapeRayCells(GridPoint head, Direction d) {
    final cells = <GridPoint>{};
    var x = head.x + d.dx;
    var y = head.y + d.dy;
    var steps = 0;
    while (x >= 0 && x < columns && y >= 0 && y < rows && steps < 120) {
      cells.add(GridPoint(x, y));
      x += d.dx;
      y += d.dy;
      steps++;
    }
    return cells;
  }

  /// True when the tip's escape ray hits this arrow's own body.
  bool _pointsOntoOwnBody(Arrow a) {
    if (a.points.length < 2) return true;
    final self = {for (final p in a.points) p};
    final dir = a.facing;
    var x = a.head.x + dir.dx;
    var y = a.head.y + dir.dy;
    var steps = 0;
    while (x >= 0 && x < columns && y >= 0 && y < rows && steps < 120) {
      if (self.contains(GridPoint(x, y))) return true;
      x += dir.dx;
      y += dir.dy;
      steps++;
    }
    return false;
  }

  /// Grow from head backward into free space (high turn bias).
  List<GridPoint> _growBackward(GridPoint head, Direction escapeDir, int maxLen) {
    final path = <GridPoint>[head]; // will reverse at end → tail…head
    // Never place body on the escape ray — that makes the tip face its own body.
    final forbidden = _escapeRayCells(head, escapeDir);
    // Straight stem of 2 cells opposite escape so the head clearly faces out.
    final back = escapeDir.opposite;
    final stem = <GridPoint>[];
    for (var i = 1; i <= 2; i++) {
      final p = GridPoint(head.x + back.dx * i, head.y + back.dy * i);
      if (!_isFree(p.x, p.y) || forbidden.contains(p)) {
        // Fall back to a single stem cell for short arrows.
        if (i == 1) return path;
        break;
      }
      stem.add(p);
    }
    path.addAll(stem);
    var dir = back;
    final turnBias = min(0.94, 0.68 + level * 0.04);
    final used = <GridPoint>{...path};

    while (path.length < maxLen) {
      final cur = path.last;
      final options = <Direction>[];
      for (final d in DirectionX.cardinal) {
        final nx = cur.x + d.dx;
        final ny = cur.y + d.dy;
        final np = GridPoint(nx, ny);
        if (_isFree(nx, ny) && !used.contains(np) && !forbidden.contains(np)) {
          options.add(d);
        }
      }
      if (options.isEmpty) break;

      Direction next;
      final forwardOk = options.contains(dir);
      final turns =
          options.where((d) => d != dir && d != dir.opposite).toList();
      // Keep a short straight stem at the tip, then zigzag hard.
      final nearTip = path.length <= 3;
      final bias = nearTip ? turnBias * 0.35 : turnBias;
      if (forwardOk && turns.isNotEmpty && _random.nextDouble() < bias) {
        next = turns[_random.nextInt(turns.length)];
      } else if (forwardOk) {
        next = dir;
      } else {
        next = options[_random.nextInt(options.length)];
      }

      final np = GridPoint(cur.x + next.dx, cur.y + next.dy);
      path.add(np);
      used.add(np);
      dir = next;
    }

    // path grew head → tail; reverse so points.last is head.
    return path.reversed.toList();
  }

  List<Arrow> _shuffleIds(List<Arrow> arrows) {
    final shuffled = arrows.toList()..shuffle(_random);
    return [
      for (var i = 0; i < shuffled.length; i++)
        shuffled[i].syncedFacing().copyWith(
          id: i,
          colorValue: arrowPalette[i % arrowPalette.length],
        ),
    ];
  }

  bool _isGreedilySolvable(List<Arrow> arrows) {
    final board = Board(columns: columns, rows: rows, shape: _shape);
    for (final a in arrows) {
      board.addArrow(a);
    }
    // Newest-first peel matches reverse construction.
    for (final a in arrows.reversed) {
      final live = board.arrowById(a.id);
      if (live == null) return false;
      if (!board.canEscape(live)) return false;
      board.removeArrow(live);
    }
    return board.isComplete;
  }

  Direction _directionFromSegment(GridPoint a, GridPoint b) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    if (dx > 0) return Direction.right;
    if (dx < 0) return Direction.left;
    if (dy > 0) return Direction.down;
    return Direction.up;
  }

  List<Arrow> _fallback() {
    final cells = _shape.playable.toList()
      ..sort((a, b) => a.y != b.y ? a.y.compareTo(b.y) : a.x.compareTo(b.x));
    if (cells.length < 6) {
      return [
        Arrow(
          id: 0,
          points: const [GridPoint(0, 0), GridPoint(1, 0), GridPoint(2, 0)],
          direction: Direction.right,
          colorValue: arrowPalette[0],
        ),
      ];
    }
    final mid = cells[cells.length ~/ 2];
    List<GridPoint> run(int dx, int dy) {
      final pts = <GridPoint>[];
      for (var i = 0; i < 3; i++) {
        final p = GridPoint(mid.x + dx * i, mid.y + dy * i);
        if (!_shape.containsPoint(p)) break;
        pts.add(p);
      }
      return pts;
    }

    final candidates = [
      run(1, 0),
      run(-1, 0),
      run(0, 1),
      run(0, -1),
    ];
    final arrows = <Arrow>[];
    for (final pts in candidates) {
      if (pts.length < 2) continue;
      arrows.add(
        Arrow(
          id: arrows.length,
          points: pts,
          direction: _directionFromSegment(pts[pts.length - 2], pts.last),
          colorValue: arrowPalette[arrows.length % arrowPalette.length],
        ).syncedFacing(),
      );
      if (arrows.length >= 3) break;
    }
    return arrows.isEmpty
        ? [
            Arrow(
              id: 0,
              points: cells.take(3).toList(),
              direction: Direction.right,
              colorValue: arrowPalette[0],
            ).syncedFacing(),
          ]
        : arrows;
  }

  static LevelDifficulty difficultyForLevel(int level) =>
      LevelScaling.forLevel(level).difficulty;

  static int arrowCountForLevel(int level) =>
      LevelScaling.forLevel(level).arrowCount;
}
