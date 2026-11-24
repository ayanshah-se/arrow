import 'arrow.dart';
import 'board.dart';

/// Checks whether every arrow can be removed in some order.
class LevelSolver {
  LevelSolver._();

  static bool isSolvable(Board board) {
    return _solve(board.copy(), <String>{});
  }

  /// Returns arrow ids in removal order, or empty if unsolvable.
  static List<int> solutionOrder(Board board) {
    final steps = <int>[];
    if (_findPath(board.copy(), steps)) return steps;
    return const [];
  }

  static bool _solve(Board board, Set<String> visited) {
    if (board.isComplete) return true;

    final key = _stateKey(board);
    if (!visited.add(key)) return false;

    final escapable = board.arrows.where(board.canEscape).toList();
    if (escapable.isEmpty) return false;

    for (final arrow in escapable) {
      final next = board.copy()..removeArrow(arrow);
      if (_solve(next, visited)) return true;
    }
    return false;
  }

  static bool _findPath(Board board, List<int> steps) {
    if (board.isComplete) return true;

    final escapable = board.arrows.where(board.canEscape).toList();
    if (escapable.isEmpty) return false;

    for (final arrow in escapable) {
      final next = board.copy()..removeArrow(arrow);
      steps.add(arrow.id);
      if (_findPath(next, steps)) return true;
      steps.removeLast();
    }
    return false;
  }

  static String _stateKey(Board board) {
    final ids = board.arrows.map((a) => a.id).toList()..sort();
    return ids.join(',');
  }

  /// Arrows that can escape right now.
  static List<Arrow> escapable(Board board) =>
      board.arrows.where(board.canEscape).toList();
}
