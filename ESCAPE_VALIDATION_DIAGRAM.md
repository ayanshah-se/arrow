// ESCAPE VALIDATION LOGIC - VISUAL FLOW
// ======================================

// EXAMPLE SCENARIO:
// Board: 12 columns x 30 rows
// 
// Arrow A (RED):   Points: [P0, P1, P2, P3], Direction: RIGHT
// Arrow B (GREEN): Points: [P4, P5, P6], Direction: DOWN
//
// Board visualization (TOP VIEW):
//
//  0   1   2   3   4   5   6   7   8   9  10  11
// +---+---+---+---+---+---+---+---+---+---+---+---+
// |   | R | R | R | R→|   |   |   |   |   |   |   |  0
// +---+---+---+---+---+---+---+---+---+---+---+---+
// |   |   |   |   |   |   |   |   |   |   |   |   |  1
// +---+---+---+---+---+---+---+---+---+---+---+---+
// |   |   | G |   |   |   |   |   |   |   |   |   |  2
// +---+---+---+---+---+---+---+---+---+---+---+---+
// |   |   | G |   |   |   |   |   |   |   |   |   |  3
// +---+---+---+---+---+---+---+---+---+---+---+---+
// |   |   | G |   |   |   |   |   |   |   |   |   |  4
// +---+---+---+---+---+---+---+---+---+---+---+---+
// ...
//
// WHERE:
//   R = Arrow A cells
//   R→ = Arrow A HEAD at (4, 0)
//   G = Arrow B cells
//   G↓ = Arrow B HEAD (not shown, at col 2)

// ESCAPE CHECK: Can Arrow A escape?
// ==================================
//
// Step 1: Find Arrow A's head
//   head = arrow.head = arrow.points.last = GridPoint(4, 0)
//
// Step 2: Determine escape direction
//   direction = arrow.direction = MoveDirection.RIGHT
//   dx = 1, dy = 0
//
// Step 3: Get cells from head to boundary (in escape direction)
//   getCellsInEscapePath(arrow):
//     x = 4, y = 0
//     
//     // Start from one cell beyond head
//     x += 1  →  x = 5
//     y += 0  →  y = 0
//     
//     Cells to check: [(5,0), (6,0), (7,0), (8,0), (9,0), (10,0), (11,0)]
//     (Stop at x=12 because isInBounds(12, 0) == false)
//
// Step 4: For each cell in escape path, check if occupied by OTHER arrow
//   getBlockingCells(arrow):
//     blocking = {}
//     
//     for (5,0): occupier = getArrowAt(5, 0) = null → not blocked
//     for (6,0): occupier = getArrowAt(6, 0) = null → not blocked
//     for (7,0): occupier = getArrowAt(7, 0) = null → not blocked
//     ...
//     
//     Result: blocking = {} (empty set)
//
// Step 5: Can arrow escape?
//   canArrowEscape(arrow):
//     return getBlockingCells(arrow).isEmpty  // true
//
// RESULT: Arrow A CAN ESCAPE ✓

// BLOCKED EXAMPLE: Can Arrow B escape?
// =====================================
//
// Arrow B: Points: [P4(2,2), P5(2,3), P6(2,4)], Direction: DOWN
// Head: (2, 4)
//
// Escape path: [(2,5), (2,6), (2,7), ..., (2,29)]
//
// But imagine Arrow C occupies (2,5):
//   getBlockingCells(arrow B):
//     for (2,5): occupier = getArrowAt(2, 5) = Arrow C
//               occupier.id != arrow B.id → blocking.add((2,5))
//     ...
//     Result: blocking = {(2,5), ...}
//
// canArrowEscape(arrow B):
//   return getBlockingCells(arrow).isEmpty  // false
//
// RESULT: Arrow B CANNOT ESCAPE ✗

// SELF-COLLISION PROTECTION
// ===========================
//
// Critical: Arrow must not block itself!
//
// Example: Arrow A has cells at (1,0), (2,0), (3,0), (4,0)
// If Arrow A is at boundary and tries to escape RIGHT:
//
//   Escape path: [(5,0), (6,0), ...]  // Starts AFTER head
//   
//   For each cell in escape path:
//     (5,0): occupier = getArrowAt(5, 0) = null (Arrow A cells are at x≤4)
//     
// RESULT: Arrow A's own cells don't block it ✓
//
// Protection is in getBlockingCells():
//   if (occupier != null && occupier.id != arrow.id):
//     blocking.add(cell)
//   ^^^^^^^^^^^^^^^^^^^^^ Only OTHER arrows count as blocks

// REMOVED ARROW SCENARIO
// ======================
//
// Initial state:
//   Arrow A at (1,0)-(4,0), direction RIGHT, can escape
//   Arrow B at (5,0), direction UNKNOWN, blocks A if B doesn't move
//
// Wait, correction - let me re-read:
// If Arrow B starts at (5,0) and is in the escape path:
//
//   Arrow A escape path: [(5,0), (6,0), ...]
//   Arrow B occupies: (5,0)
//   
//   canArrowEscape(A) = false (blocked by B)
//
// User taps Arrow B first (assuming B can escape):
//   B escapes → removed from board
//   _occupancyMap[(5,0)] is removed
//
// Now user taps Arrow A:
//   canArrowEscape(A):
//     getBlockingCells(A):
//       for (5,0): occupier = getArrowAt(5,0) = null (B is gone!)
//     Result: blocking = {} (empty)
//   
//   canArrowEscape(A) = true ✓
//   A can now escape because B is gone!

// OCCUPANCY MAP EFFICIENCY
// =========================
//
// Time Complexity:
//   addArrow(arrow):         O(n) where n = arrow.points.length
//   removeArrow(arrow):      O(n)
//   getArrowAt(x, y):        O(1)  ← Fast lookup!
//   canArrowEscape(arrow):   O(m) where m = cells from head to boundary
//
// Space Complexity:
//   _occupancyMap:           O(total_cells_occupied)
//
// Total cells possible: 12 × 30 = 360
// With 20 arrows: ~6000 cells total = minimal overhead

// FLOW DIAGRAM
// ============
//
// Player taps arrow
//         ↓
// ArrowMadnessGame.onTapDown()
//         ↓
// ArrowMadnessGame.removePath(arrow)
//         ↓
//    [VALIDATION]
//    canArrowEscape(arrow)?
//         ↙         ↘
//       YES          NO
//        ↓            ↓
//   [ESCAPE]    [BLOCKED]
//        ↓            ↓
//   Remove from    Show feedback
//   board          (red X, shake)
//        ↓            ↓
//   Update       Reset combo
//   occupancy    to 1
//        ↓            ↓
//   Add score   Return to game
//   Increment   (no lives lost)
//   combo
//        ↓
//   [LEVEL CHECK]
//   isLevelComplete()?
//        ↙         ↘
//       YES         NO
//        ↓           ↓
//   Show overlay  Continue game
//   "Level OK"    (ready for
//   Load next     next tap)
//   level
