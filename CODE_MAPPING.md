// CODE IMPLEMENTATION MAPPING
// ===========================
// Maps specification requirements to actual code locations

// ============================================================================
// REQUIREMENT 1: Arrow Structure
// ============================================================================
// "Each arrow/path has: ID, color, cells, direction, head/end, tail, state"
//
// CODE LOCATION: lib/features/game/models/arrow_path.dart
// 
// class ArrowPath {
//   final int id;                        // ← Unique ID
//   final List<GridPoint> points;        // ← Series of grid cells
//   final Color color;                   // ← Color
//   final MoveDirection direction;       // ← Direction arrow can escape
//   
//   GridPoint get head => points.last;   // ← Head/end point (escape point)
//   GridPoint get tail => points.first;  // ← Tail/start point
// }
//
// Active/removed state:
// - Tracked in ArrowBoard.arrows list
// - If in list → active
// - If removed from list → removed
//
// CODE: lib/features/game/logic/arrow_board.dart
//   List<ArrowPath> arrows = [];  // Only active arrows stored here

// ============================================================================
// REQUIREMENT 2: Objective
// ============================================================================
// "The objective is to remove every arrow from the board."
//
// CODE LOCATION: lib/features/game/logic/arrow_board.dart
//
// bool isLevelComplete() => arrows.isEmpty;
//
// CALLED FROM: lib/features/game/game/arrow_madness_game.dart
//   if (_board.isLevelComplete()) {
//     Future.delayed(Duration(milliseconds: 500), onLevelComplete);
//   }
//
// HANDLED BY: lib/features/game/controllers/game_controller.dart
//   void _onLevelComplete() {
//     isLevelComplete.value = true;
//     game.pauseEngine();
//   }
//   
//   void nextLevel() {
//     level.value++;
//     game.loadLevel(level.value);
//     game.resumeEngine();
//   }

// ============================================================================
// REQUIREMENT 3: Escape Rule
// ============================================================================
// "An arrow can move/escape only in the direction its arrowhead points."
//
// CODE LOCATION: lib/features/game/logic/arrow_board.dart
//
// List<(int, int)> getCellsInEscapePath(ArrowPath arrow) {
//   final cells = <(int, int)>[];
//   var x = arrow.head.x;        // Start at arrow HEAD
//   var y = arrow.head.y;
//
//   // Start from one cell BEYOND the head
//   x += arrow.direction.dx;     // Only moves in ARROW'S DIRECTION
//   y += arrow.direction.dy;     // No other directions allowed
//
//   // Continue until we exit the board
//   while (isInBounds(x, y)) {
//     cells.add((x, y));
//     x += arrow.direction.dx;   // Continue in SAME DIRECTION only
//     y += arrow.direction.dy;
//   }
//
//   return cells;
// }

// ============================================================================
// REQUIREMENT 4: Tap Detection & Validation Flow
// ============================================================================
// "When player taps arrow: (10 steps)"
//
// STEP 1: Determine arrow's head position
// CODE: lib/features/game/game/arrow_madness_game.dart
//   ArrowPath? _pathAt(Offset position) {
//     // Find which arrow was tapped based on position
//     // Returns the ArrowPath reference
//   }
//
//   @override
//   void onTapDown(TapDownEvent event) {
//     final path = _pathAt(event.localPosition.toOffset());
//     if (path != null) {
//       onPathSelected(path);  // Callback to controller
//     }
//   }
//
// STEP 2-3: Look from head in direction, check cells to boundary
// CODE: lib/features/game/logic/arrow_board.dart
//   List<(int, int)> getCellsInEscapePath(ArrowPath arrow) {
//     // Returns ALL cells from head to boundary
//   }
//
// STEP 4: If another active arrow blocks route, cannot move
// CODE: lib/features/game/logic/arrow_board.dart
//   Set<(int, int)> getBlockingCells(ArrowPath arrow) {
//     final blocking = <(int, int)>{};
//     
//     for (final cell in getCellsInEscapePath(arrow)) {
//       final occupier = getArrowAt(cell.$1, cell.$2);
//       // If occupied by ANOTHER arrow (not self), it blocks
//       if (occupier != null && occupier.id != arrow.id) {
//         blocking.add(cell);
//       }
//     }
//     return blocking;
//   }
//
// STEP 5: If route is clear, animate arrow moving outside board
// CODE: lib/features/game/game/arrow_madness_game.dart
//   bool removePath(ArrowPath path) {
//     if (!_board.canArrowEscape(path)) {
//       onArrowBlocked(path);
//       return false;
//     }
//     
//     // If can escape:
//     _removingPaths.add(_RemovingPath(path));  // Start animation
//   }
//
// Animation rendering: lib/features/game/game/arrow_madness_game.dart
//   void _drawRemovingPath(Canvas canvas, ArrowPath path, double progress, ...) {
//     // Retracts path from head toward tail (0.22 second duration)
//     // Reads as path being "eaten" away toward origin
//   }
//
// STEP 6: Remove arrow from logical board
// CODE: lib/features/game/logic/arrow_board.dart
//   bool removeArrow(ArrowPath arrow) {
//     final removed = arrows.remove(arrow);
//     if (removed) {
//       for (final point in arrow.points) {
//         _occupancyMap.remove((point.x, point.y));
//       }
//     }
//     return removed;
//   }
//
// CALLED FROM: lib/features/game/game/arrow_madness_game.dart
//   _board.removeArrow(path);
//
// STEP 7: Update occupied cells
// CODE: Automatic - occupancy map is updated in removeArrow()
//   Each cell occupied by arrow is removed from _occupancyMap
//
// STEP 8: Previously blocked arrows may now become available
// CODE: Automatic - next tap calls canArrowEscape() with fresh occupancy
//   
// STEP 9: Check all arrows removed
// CODE: lib/features/game/logic/arrow_board.dart
//   if (_board.isLevelComplete()) {
//     onLevelComplete();
//   }
//
// STEP 10: Load next level
// CODE: lib/features/game/controllers/game_controller.dart
//   void nextLevel() {
//     level.value++;
//     lives.value = 3;
//     combo.value = 1;
//     isLevelComplete.value = false;
//     game.loadLevel(level.value);
//     game.resumeEngine();
//   }

// ============================================================================
// REQUIREMENT 5: CORE RULE (Most Important)
// ============================================================================
// "Can this arrow travel from its head to outside the board 
//  without colliding with any remaining active arrow?"
//
// CODE IMPLEMENTATION: lib/features/game/logic/arrow_board.dart
//
// bool canArrowEscape(ArrowPath arrow) {
//   return getBlockingCells(arrow).isEmpty;
// }
//
// EXPLANATION:
// - getBlockingCells() returns set of cells that would block escape
// - If set is empty → no blocking cells → can escape
// - If set is not empty → at least one blocking cell → cannot escape
//
// FULL LOGIC CHAIN:
// 1. getCellsInEscapePath(arrow)
//    → All cells from arrow.head in arrow.direction until boundary
// 
// 2. getBlockingCells(arrow)
//    → For each cell, check if occupied by DIFFERENT arrow
//    → Return set of blocking cells (empty = can escape)
// 
// 3. canArrowEscape(arrow)
//    → true if getBlockingCells().isEmpty
//    → false if any blocking cells exist

// ============================================================================
// REQUIREMENT 6: Grid Occupancy System (Efficient)
// ============================================================================
// "Implement this efficiently using a grid occupancy system."
//
// CODE LOCATION: lib/features/game/logic/arrow_board.dart
//
// class ArrowBoard {
//   final Map<(int, int), int> _occupancyMap = {};  // GridPoint → ArrowID
// }
//
// Operations:
//
// Add arrow:
//   void addArrow(ArrowPath arrow) {
//     arrows.add(arrow);
//     for (final point in arrow.points) {
//       _occupancyMap[(point.x, point.y)] = arrow.id;  // O(1) insert
//     }
//   }
//
// Get occupier:
//   ArrowPath? getArrowAt(int x, int y) {
//     final id = _occupancyMap[(x, y)];  // O(1) lookup
//     if (id == null) return null;
//     return getArrowById(id);           // O(n) search by ID (n = arrows)
//   }
//
// Remove arrow:
//   bool removeArrow(ArrowPath arrow) {
//     arrows.remove(arrow);              // O(n) list search
//     for (final point in arrow.points) {
//       _occupancyMap.remove((point.x, point.y));  // O(1) each
//     }
//   }
//
// EFFICIENCY: Hash map provides O(1) occupancy lookups during escape check

// ============================================================================
// REQUIREMENT 7: Escape Validation Excludes Self
// ============================================================================
// "An arrow must not block itself."
//
// CODE LOCATION: lib/features/game/logic/arrow_board.dart
//
// Set<(int, int)> getBlockingCells(ArrowPath arrow) {
//   final blocking = <(int, int)>{};
//   
//   for (final cell in getCellsInEscapePath(arrow)) {
//     final occupier = getArrowAt(cell.$1, cell.$2);
//     
//     // CRITICAL CHECK:
//     if (occupier != null && occupier.id != arrow.id) {
//                               ^^^^^^^^^^^^^^^^^^^^^^^^
//                               Only OTHER arrows count as blocks
//         blocking.add(cell);
//     }
//   }
//   
//   return blocking;
// }
//
// WHY THIS WORKS:
// - getCellsInEscapePath() starts from ONE CELL BEYOND head
// - Arrow's own cells (from tail to head) are NOT in escape path
// - Therefore arrow cannot collide with its own cells

// ============================================================================
// REQUIREMENT 8: Board Bounds Checking
// ============================================================================
// "Continue checking until reaching board boundary."
//
// CODE LOCATION: lib/features/game/logic/arrow_board.dart
//
// bool isInBounds(int x, int y) {
//   return x >= 0 && x < columns && y >= 0 && y < rows;
// }
//
// USED IN: getCellsInEscapePath()
//   while (isInBounds(x, y)) {
//     cells.add((x, y));
//     x += arrow.direction.dx;
//     y += arrow.direction.dy;
//   }
//   // Loop stops when isInBounds returns false = at boundary

// ============================================================================
// REQUIREMENT 9: Blocked Arrow Feedback
// ============================================================================
// "If blocked: give subtle shake animation and visual feedback"
//
// CODE LOCATION: lib/features/game/game/arrow_madness_game.dart
//
// When blocked:
//   bool removePath(ArrowPath path) {
//     if (!_board.canArrowEscape(path)) {
//       _blockedArrows[path.id] = _BlockedArrowState(0.0);  // Start animation
//       onArrowBlocked(path);  // Callback to controller
//       return false;
//     }
//   }
//
// Controller response:
// lib/features/game/controllers/game_controller.dart
//   void _onArrowBlocked(ArrowPath path) {
//     combo.value = 1;  // Reset combo (no lives lost)
//   }
//
// Visual feedback:
// lib/features/game/game/arrow_madness_game.dart
//   void _drawBlockedArrowIndicator(
//     Canvas canvas,
//     ArrowPath arrow,
//     double elapsed,
//     double cell,
//     Offset origin,
//   ) {
//     // Shake animation: oscillate position
//     final shakePhase = elapsed * 12;
//     final shakeAmount = sin(shakePhase) * 3.0;
//     
//     // Red outline around entire path
//     // Prohibition symbol (circle + slash) on arrow head
//     // Fades out over 0.6 seconds
//   }

// ============================================================================
// REQUIREMENT 10: Level Solvability
// ============================================================================
// "Levels MUST be solvable. Generate guaranteed solvable levels."
//
// CODE LOCATION: lib/features/game/logic/level_solver.dart
//
// static bool isSolvable(ArrowBoard board) {
//   // Copy board state
//   final testBoard = _copyBoard(board);
//   // Try to solve using recursive removal
//   return _canSolveRecursively(testBoard);
// }
//
// USED IN: lib/features/game/services/level_generator.dart
//
// List<ArrowPath>? _generateSolvableLevel() {
//   // Build arrows
//   final testBoard = ArrowBoard(...);
//   for (final newArrow in candidates) {
//     testBoard.addArrow(newArrow);
//     // VALIDATE: Only accept if still solvable
//     if (LevelSolver.isSolvable(testBoard)) {
//       // Accept this arrow
//     } else {
//       // Reject and try different arrow
//     }
//   }
// }

// ============================================================================
// SUMMARY VERIFICATION
// ============================================================================
//
// ✓ Requirement 1: Arrow structure with all fields
// ✓ Requirement 2: Objective = remove all arrows
// ✓ Requirement 3: Escape only in arrow's direction
// ✓ Requirement 4: 10-step tap flow fully implemented
// ✓ Requirement 5: Core rule = canArrowEscape() with occupancy check
// ✓ Requirement 6: Efficient grid occupancy (hash map)
// ✓ Requirement 7: Arrow excludes self from blocking check
// ✓ Requirement 8: Board bounds checking
// ✓ Requirement 9: Blocked arrow visual feedback
// ✓ Requirement 10: Level solvability validation
//
// CORE GAME MECHANICS: FULLY VERIFIED ✓
