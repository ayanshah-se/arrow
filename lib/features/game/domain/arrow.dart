import 'direction.dart';
import 'grid_point.dart';

/// A colored snake path on the grid. Escape direction is fixed at the head.
class Arrow {
  const Arrow({
    required this.id,
    required this.points,
    required this.direction,
    required this.colorValue,
  });

  final int id;
  final List<GridPoint> points;

  /// Stored escape facing — should match [facing] from the tip segment.
  final Direction direction;

  /// ARGB color as 0xAARRGGBB — keeps domain free of Flutter types.
  final int colorValue;

  GridPoint get head => points.last;
  GridPoint get tail => points.first;

  /// Direction of the last body segment (head triangle + escape must match this).
  Direction get facing {
    if (points.length < 2) return direction;
    final a = points[points.length - 2];
    final b = points.last;
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    if (dx > 0) return Direction.right;
    if (dx < 0) return Direction.left;
    if (dy > 0) return Direction.down;
    if (dy < 0) return Direction.up;
    return direction;
  }

  Arrow copyWith({
    int? id,
    List<GridPoint>? points,
    Direction? direction,
    int? colorValue,
  }) => Arrow(
    id: id ?? this.id,
    points: points ?? this.points,
    direction: direction ?? this.direction,
    colorValue: colorValue ?? this.colorValue,
  );

  /// Rebuild with [direction] forced to the tip segment.
  Arrow syncedFacing() => copyWith(direction: facing);

  @override
  String toString() =>
      'Arrow(id: $id, len: ${points.length}, dir: $direction)';
}
