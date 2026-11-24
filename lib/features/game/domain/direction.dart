enum Direction {
  up,
  down,
  left,
  right,
  upLeft,
  upRight,
  downLeft,
  downRight,
}

extension DirectionX on Direction {
  int get dx => switch (this) {
    Direction.left || Direction.upLeft || Direction.downLeft => -1,
    Direction.right || Direction.upRight || Direction.downRight => 1,
    _ => 0,
  };

  int get dy => switch (this) {
    Direction.up || Direction.upLeft || Direction.upRight => -1,
    Direction.down || Direction.downLeft || Direction.downRight => 1,
    _ => 0,
  };

  bool get isDiagonal => dx != 0 && dy != 0;

  Direction get opposite => switch (this) {
    Direction.up => Direction.down,
    Direction.down => Direction.up,
    Direction.left => Direction.right,
    Direction.right => Direction.left,
    Direction.upLeft => Direction.downRight,
    Direction.downRight => Direction.upLeft,
    Direction.upRight => Direction.downLeft,
    Direction.downLeft => Direction.upRight,
  };

  static const cardinal = [
    Direction.up,
    Direction.down,
    Direction.left,
    Direction.right,
  ];

  static const diagonal = [
    Direction.upLeft,
    Direction.upRight,
    Direction.downLeft,
    Direction.downRight,
  ];
}
