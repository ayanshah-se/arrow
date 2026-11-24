import 'dart:math';

import 'grid_point.dart';

/// Iconic silhouettes matching Maze Madness–style reference levels.
enum BoardShapeKind {
  rectangle,
  guitar,
  rocket,
  trophy,
  butterfly,
  mountain,
  strip,
  heart,
  islands,
  ring,
}

/// Playable silhouette inside the grid bounding box. Changes every level.
class BoardShape {
  BoardShape({
    required this.columns,
    required this.rows,
    required this.kind,
    required Set<GridPoint> playable,
  }) : playable = Set.unmodifiable(playable);

  final int columns;
  final int rows;
  final BoardShapeKind kind;
  final Set<GridPoint> playable;

  bool contains(int x, int y) => playable.contains(GridPoint(x, y));
  bool containsPoint(GridPoint p) => playable.contains(p);

  int get cellCount => playable.length;

  factory BoardShape.forLevel({
    required int columns,
    required int rows,
    required int level,
    required int seed,
  }) {
    final kinds = BoardShapeKind.values;
    final kind = kinds[(level - 1) % kinds.length];
    final playable = _build(kind, columns, rows, Random(seed));
    // Guarantee a usable area.
    if (playable.length < max(40, (columns * rows) ~/ 8)) {
      return BoardShape(
        columns: columns,
        rows: rows,
        kind: BoardShapeKind.rectangle,
        playable: {
          for (var y = 0; y < rows; y++)
            for (var x = 0; x < columns; x++) GridPoint(x, y),
        },
      );
    }
    return BoardShape(
      columns: columns,
      rows: rows,
      kind: kind,
      playable: playable,
    );
  }

  static Set<GridPoint> _build(
    BoardShapeKind kind,
    int cols,
    int rows,
    Random random,
  ) {
    bool inside(int x, int y) {
      final u = cols <= 1 ? 0.5 : x / (cols - 1);
      final v = rows <= 1 ? 0.5 : y / (rows - 1);
      switch (kind) {
        case BoardShapeKind.rectangle:
          return true;
        case BoardShapeKind.guitar:
          return _guitar(u, v);
        case BoardShapeKind.rocket:
          return _rocket(u, v);
        case BoardShapeKind.trophy:
          return _trophy(u, v);
        case BoardShapeKind.butterfly:
          return _butterfly(u, v);
        case BoardShapeKind.mountain:
          return _mountain(u, v);
        case BoardShapeKind.strip:
          return _strip(u, v, random);
        case BoardShapeKind.heart:
          return _heart(u, v);
        case BoardShapeKind.islands:
          return _islands(u, v);
        case BoardShapeKind.ring:
          return _ring(u, v);
      }
    }

    final cells = <GridPoint>{};
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        if (inside(x, y)) cells.add(GridPoint(x, y));
      }
    }
    return cells;
  }

  /// Diagonal guitar: rounded body + thin neck + headstock.
  static bool _guitar(double u, double v) {
    // Rotate so neck runs bottom-left → top-right.
    final cx = u - 0.42;
    final cy = v - 0.58;
    final ang = -0.55;
    final xr = cx * cos(ang) - cy * sin(ang);
    final yr = cx * sin(ang) + cy * cos(ang);

    // Body (figure-8-ish double circle).
    final bodyLower = _ellipse(xr + 0.02, yr - 0.08, 0.28, 0.22);
    final bodyUpper = _ellipse(xr + 0.02, yr + 0.12, 0.22, 0.18);
    final body = bodyLower || bodyUpper;

    // Neck.
    final neck = xr > 0.05 &&
        xr < 0.55 &&
        yr.abs() < 0.055 + 0.02 * (xr / 0.55);

    // Headstock.
    final head = xr > 0.48 &&
        xr < 0.72 &&
        yr > -0.14 &&
        yr < 0.12 &&
        (xr - 0.55).abs() + (yr.abs() * 0.6) < 0.16;

    return body || neck || head;
  }

  /// Vertical rocket / fighter: nose, fuselage, wings, twin engines.
  static bool _rocket(double u, double v) {
    final x = (u - 0.5).abs();
    // Nose taper.
    if (v < 0.18) {
      return x < 0.06 + 0.22 * (v / 0.18);
    }
    // Upper fuselage.
    if (v < 0.42) {
      return x < 0.14 + 0.06 * ((v - 0.18) / 0.24);
    }
    // Wings + mid body.
    if (v < 0.72) {
      final wing = x < 0.18 + 0.32 * ((v - 0.42) / 0.30);
      final body = x < 0.20;
      return wing || body;
    }
    // Twin engines / fins at bottom with center gap.
    if (v < 0.92) {
      final left = u > 0.18 && u < 0.40;
      final right = u > 0.60 && u < 0.82;
      final keel = x < 0.10 && v < 0.82;
      return left || right || keel;
    }
    return false;
  }

  /// Trophy / cup: bowl, handles, stem, base.
  static bool _trophy(double u, double v) {
    final x = (u - 0.5).abs();
    // Bowl.
    if (v < 0.38) {
      final bowl = x < 0.34 - 0.08 * (v / 0.38) && v > 0.06;
      final rim = v < 0.12 && x < 0.38;
      return bowl || rim;
    }
    // Handles.
    if (v >= 0.10 && v < 0.42) {
      final left = u > 0.08 && u < 0.20 && v > 0.14 && v < 0.36;
      final right = u > 0.80 && u < 0.92 && v > 0.14 && v < 0.36;
      if (left || right) return true;
    }
    // Stem.
    if (v >= 0.38 && v < 0.72) {
      return x < 0.08 + 0.04 * ((v - 0.38) / 0.34);
    }
    // Pedestal / base.
    if (v >= 0.72 && v < 0.94) {
      final t = (v - 0.72) / 0.22;
      return x < 0.12 + 0.28 * t;
    }
    return false;
  }

  /// Butterfly: body + four wing lobes.
  static bool _butterfly(double u, double v) {
    final x = u - 0.5;
    final y = v - 0.5;
    final ax = x.abs();

    // Thin body.
    if (ax < 0.05 && y.abs() < 0.42) return true;

    // Upper wings.
    final upper = _ellipse(ax - 0.28, y + 0.18, 0.30, 0.26) && y < 0.12;
    // Lower wings.
    final lower = _ellipse(ax - 0.22, y - 0.20, 0.24, 0.22) && y > -0.05;

    // Antennae tips.
    final antenna = ax < 0.10 && y > 0.40 && y < 0.48;

    return upper || lower || antenna;
  }

  /// Jagged mountain / peaks silhouette.
  static bool _mountain(double u, double v) {
    // Three peaks with stepped slopes.
    final peak1 = 0.55 - 1.8 * (u - 0.22).abs();
    final peak2 = 0.78 - 2.2 * (u - 0.50).abs();
    final peak3 = 0.60 - 1.9 * (u - 0.78).abs();
    final ridge = max(peak1, max(peak2, peak3));
    final floor = 0.12 + 0.04 * sin(u * pi * 4);
    final yTop = 1.0 - (0.08 + ridge.clamp(0.0, 0.85));
    return v >= yTop && v <= 1.0 - floor;
  }

  /// Wide horizontal strip with wavy edges (reference band levels).
  static bool _strip(double u, double v, Random random) {
    final mid = 0.50 + 0.04 * sin(u * pi * 3 + random.nextDouble() * 0.01);
    final half = 0.16 + 0.05 * sin(u * pi * 5);
    return (v - mid).abs() <= half;
  }

  /// Classic heart silhouette.
  static bool _heart(double u, double v) {
    final x = (u - 0.5) * 2.2;
    final y = (0.42 - v) * 2.4;
    return pow(x * x + y * y - 1, 3) - x * x * y * y * y <= 0;
  }

  /// Disconnected mountain islands / clustered peaks.
  static bool _islands(double u, double v) {
    bool peak(double cx, double cy, double rx, double ry) =>
        _ellipse(u - cx, v - cy, rx, ry);

    return peak(0.28, 0.28, 0.22, 0.18) ||
        peak(0.72, 0.26, 0.20, 0.16) ||
        peak(0.50, 0.52, 0.26, 0.20) ||
        peak(0.30, 0.74, 0.22, 0.16) ||
        peak(0.70, 0.76, 0.24, 0.17);
  }

  /// Thick outer ring / frame (border-snake levels).
  static bool _ring(double u, double v) {
    final x = (u - 0.5).abs() / 0.48;
    final y = (v - 0.5).abs() / 0.48;
    final outer = max(x, y) <= 1.0;
    final inner = max(x, y) <= 0.62;
    return outer && !inner;
  }

  static bool _ellipse(double dx, double dy, double rx, double ry) {
    if (rx <= 0 || ry <= 0) return false;
    final nx = dx / rx;
    final ny = dy / ry;
    return nx * nx + ny * ny <= 1.0;
  }
}
