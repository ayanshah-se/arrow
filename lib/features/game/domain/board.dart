import 'arrow.dart';
import 'board_shape.dart';
import 'direction.dart';
import 'grid_point.dart';

/// Occupancy map + escape-ray validation for the arrow puzzle.
class Board {
  Board({
    required this.columns,
    required this.rows,
    BoardShape? shape,
  }) : shape =
           shape ??
           BoardShape(
             columns: columns,
             rows: rows,
             kind: BoardShapeKind.rectangle,
             playable: {
               for (var y = 0; y < rows; y++)
                 for (var x = 0; x < columns; x++) GridPoint(x, y),
             },
           );

  final int columns;
  final int rows;
  final BoardShape shape;

  final List<Arrow> _arrows = [];
  final Map<(int, int), int> _occupancy = {};

  List<Arrow> get arrows => List.unmodifiable(_arrows);

  int get arrowCount => _arrows.length;

  bool get isComplete => _arrows.isEmpty;

  Arrow? arrowById(int id) {
    for (final arrow in _arrows) {
      if (arrow.id == id) return arrow;
    }
    return null;
  }

  bool isInBounds(int x, int y) =>
      x >= 0 && x < columns && y >= 0 && y < rows;

  bool isPlayable(int x, int y) => shape.contains(x, y);

  bool isPlayablePoint(GridPoint p) => shape.containsPoint(p);

  bool isInBoundsPoint(GridPoint p) => isInBounds(p.x, p.y);

  Arrow? arrowAt(int x, int y) {
    final id = _occupancy[(x, y)];
    if (id == null) return null;
    return arrowById(id);
  }

  void clear() {
    _arrows.clear();
    _occupancy.clear();
  }

  void addArrow(Arrow arrow) {
    _arrows.add(arrow);
    for (final point in arrow.points) {
      _occupancy[(point.x, point.y)] = arrow.id;
    }
  }

  bool removeArrow(Arrow arrow) {
    final removed = _arrows.remove(arrow);
    if (!removed) {
      final byId = arrowById(arrow.id);
      if (byId == null) return false;
      _arrows.remove(byId);
      for (final point in byId.points) {
        _occupancy.remove((point.x, point.y));
      }
      return true;
    }
    for (final point in arrow.points) {
      _occupancy.remove((point.x, point.y));
    }
    return true;
  }

  bool removeById(int id) {
    final arrow = arrowById(id);
    if (arrow == null) return false;
    return removeArrow(arrow);
  }

  /// Escape ray through the full grid; leaving the board bounds counts as free.
  /// (Must not stop at silhouette holes — otherwise facing arrows look blocked
  /// but are still escapable.)
  List<GridPoint> escapeRay(Arrow arrow) {
    final dir = arrow.facing;
    final cells = <GridPoint>[];
    var x = arrow.head.x + dir.dx;
    var y = arrow.head.y + dir.dy;
    while (isInBounds(x, y)) {
      cells.add(GridPoint(x, y));
      x += dir.dx;
      y += dir.dy;
    }
    return cells;
  }

  Set<GridPoint> blockingCells(Arrow arrow) {
    final blocking = <GridPoint>{};
    final self = {for (final p in arrow.points) p};
    for (final cell in escapeRay(arrow)) {
      // Own body on the ray = tip faces its own tail / fold — not escapable.
      if (self.contains(cell)) {
        blocking.add(cell);
        continue;
      }
      final occupier = arrowAt(cell.x, cell.y);
      if (occupier != null && occupier.id != arrow.id) {
        blocking.add(cell);
      }
    }
    return blocking;
  }

  bool canEscape(Arrow arrow) => blockingCells(arrow).isEmpty;

  Board copy() {
    final copy = Board(columns: columns, rows: rows, shape: shape);
    for (final arrow in _arrows) {
      copy.addArrow(arrow);
    }
    return copy;
  }
}
