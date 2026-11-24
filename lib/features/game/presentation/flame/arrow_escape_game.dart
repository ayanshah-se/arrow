import 'dart:math';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../data/level_generator.dart';
import '../../domain/arrow.dart';
import '../../domain/board.dart';
import '../../domain/direction.dart';
import '../../domain/grid_point.dart';

/// Flame board: light skin, snake-slither escape / block anims, zoom + pan.
class ArrowEscapeGame extends FlameGame
    with TapCallbacks, ScaleDetector, ScrollDetector {
  ArrowEscapeGame({
    required this.onArrowTapped,
    required this.onArrowEscaped,
    required this.onArrowBlocked,
    required this.onLevelComplete,
  });

  static const baseColumns = 18;
  static const baseRows = 26;
  static const maxHearts = 3;
  static const _slitherBaseDuration = 0.38;
  static const _blockDuration = 0.55;
  static const minZoom = 0.55;
  static const maxZoom = 3.2;

  /// Back-compat for tests / callers that expect a default size.
  static int get columns => baseColumns;
  static int get rows => baseRows;

  final ValueChanged<Arrow> onArrowTapped;
  final ValueChanged<Arrow> onArrowEscaped;
  final ValueChanged<Arrow> onArrowBlocked;
  final VoidCallback onLevelComplete;

  late Board _board;
  List<Arrow> _arrows = const [];
  final List<_SlitheringArrow> _slithering = [];
  final Map<int, _BlockedState> _blocked = {};
  LevelData? _levelCache;
  int _cachedLevel = -1;

  int _columns = baseColumns;
  int _rows = baseRows;

  bool showGrid = true;
  double zoom = 1.0;
  Offset pan = Offset.zero;

  bool _suppressTap = false;
  bool _inputLocked = false;
  double _zoomAtScaleStart = 1.0;

  Arrow? _pressArrow;
  Offset? _pressScreen;
  int? _pressedId;
  final List<Arrow> _escapedStack = [];
  bool _lastWasBlocked = false;

  List<Arrow> get arrows => List.unmodifiable(_arrows);

  bool canEscape(Arrow arrow) => _board.canEscape(arrow);

  bool get isLevelComplete => _board.isComplete && _slithering.isEmpty;

  void setInputLocked(bool locked) => _inputLocked = locked;

  void toggleGrid() => showGrid = !showGrid;

  void resetCamera() {
    zoom = 1.0;
    pan = Offset.zero;
  }

  void zoomBy(double factor) {
    zoom = (zoom * factor).clamp(minZoom, maxZoom);
  }

  void zoomIn() => zoomBy(1.18);

  void zoomOut() => zoomBy(1 / 1.18);

  void loadLevel(int level) {
    final size = LevelScaling.boardSizeForLevel(level);
    _columns = size.$1;
    _rows = size.$2;
    resetCamera();

    if (_cachedLevel == level && _levelCache != null) {
      _applyCachedLevel();
      return;
    }

    final data = LevelGenerator.forLevel(
      columns: _columns,
      rows: _rows,
      level: level,
    ).generate();
    _levelCache = data;
    _cachedLevel = level;
    _applyCachedLevel();
  }

  /// Restore the current puzzle instantly (no regeneration).
  void resetLevel() {
    if (_levelCache == null) {
      loadLevel(_cachedLevel > 0 ? _cachedLevel : 1);
      return;
    }
    _applyCachedLevel();
  }

  void _applyCachedLevel() {
    final data = _levelCache!;
    _columns = data.shape.columns;
    _rows = data.shape.rows;
    _slithering.clear();
    _blocked.clear();
    _escapedStack.clear();
    _lastWasBlocked = false;
    _clearPress();
    _board = Board(columns: _columns, rows: _rows, shape: data.shape);
    _arrows = [for (final a in data.arrows) a.syncedFacing()];
    for (final arrow in _arrows) {
      _board.addArrow(arrow);
    }
  }

  /// Attempt to remove [arrow]. Returns true if it escaped.
  bool tryRemove(Arrow arrow) {
    if (_inputLocked) return false;

    Arrow? live;
    for (final a in _arrows) {
      if (a.id == arrow.id) {
        live = a;
        break;
      }
    }
    if (live == null) return false;

    onArrowTapped(live);

    if (!_board.canEscape(live)) {
      _blocked[live.id] = _BlockedState();
      _lastWasBlocked = true;
      onArrowBlocked(live);
      return false;
    }

    _arrows = _arrows.where((a) => a.id != live!.id).toList();
    _board.removeArrow(live);
    _blocked.remove(live.id);

    final duration =
        (_slitherBaseDuration + live.points.length * 0.028).clamp(0.35, 0.85);
    _slithering.add(
      _SlitheringArrow(arrow: live.syncedFacing(), duration: duration),
    );
    _escapedStack.add(live);
    _lastWasBlocked = false;
    onArrowEscaped(live);
    return true;
  }

  bool get canUndo => _escapedStack.isNotEmpty || _lastWasBlocked;

  bool get willUndoBlocked => _lastWasBlocked;

  /// Undo a miss-tap: put the last escaped arrow back, or clear a blocked flash.
  bool undoLast() {
    if (_lastWasBlocked) {
      _lastWasBlocked = false;
      _blocked.clear();
      _clearPress();
      return true;
    }
    if (_escapedStack.isEmpty) return false;
    final arrow = _escapedStack.removeLast();
    _slithering.removeWhere((s) => s.arrow.id == arrow.id);
    if (_arrows.any((a) => a.id == arrow.id)) return true;
    _arrows = [..._arrows, arrow];
    _board.addArrow(arrow);
    _clearPress();
    return true;
  }

  void _clearPress() {
    _pressArrow = null;
    _pressScreen = null;
    _pressedId = null;
  }

  @override
  Color backgroundColor() => const Color(0xFFF3F0E8);

  @override
  void update(double dt) {
    super.update(dt);

    for (final entry in _blocked.entries.toList()) {
      entry.value.elapsed += dt;
      if (entry.value.elapsed >= _blockDuration) {
        _blocked.remove(entry.key);
      }
    }

    for (var i = _slithering.length - 1; i >= 0; i--) {
      final item = _slithering[i];
      item.progress += dt / item.duration;
      if (item.progress >= 1.0) {
        _slithering.removeAt(i);
        if (_board.isComplete && _slithering.isEmpty) {
          onLevelComplete();
        }
      }
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_inputLocked || _suppressTap) return;
    _pressScreen = event.localPosition.toOffset();
    _pressArrow = _hitTest(_screenToWorld(_pressScreen!));
    _pressedId = _pressArrow?.id;
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (_inputLocked || _suppressTap) {
      _clearPress();
      return;
    }
    final screen = event.localPosition.toOffset();
    if (_pressScreen != null && (screen - _pressScreen!).distance > 18) {
      _clearPress();
      return;
    }
    final world = _screenToWorld(screen);
    final arrow = _hitTest(world);
    final target =
        (arrow != null && _pressArrow != null && arrow.id == _pressArrow!.id)
        ? arrow
        : null;
    _clearPress();
    if (target != null) tryRemove(target);
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _clearPress();
  }

  @override
  void onScaleStart(ScaleStartInfo info) {
    _zoomAtScaleStart = zoom;
    if (info.pointerCount > 1) {
      _suppressTap = true;
      _clearPress();
    }
  }

  @override
  void onScaleUpdate(ScaleUpdateInfo info) {
    // Use Flutter's combined [scale] — Flame's scale.global.x is only
    // horizontalScale and often stays ~1 on trackpads / some devices.
    final scale = info.raw.scale;
    if (info.pointerCount >= 2 || (scale - 1.0).abs() > 0.01) {
      _suppressTap = true;
      zoom = (_zoomAtScaleStart * scale).clamp(minZoom, maxZoom);
    }

    final delta = info.raw.focalPointDelta;
    if (delta != Offset.zero &&
        (info.pointerCount >= 2 || zoom > 1.02 || scale != 1.0)) {
      pan += delta;
      if (delta.distance > 2) {
        _suppressTap = true;
        _clearPress();
      }
    }
  }

  @override
  void onScaleEnd(ScaleEndInfo info) {
    Future<void>.delayed(const Duration(milliseconds: 80), () {
      _suppressTap = false;
    });
  }

  @override
  void onScroll(PointerScrollInfo info) {
    // Mouse wheel / trackpad scroll zoom (desktop + emulators).
    final dy = info.scrollDelta.global.y;
    if (dy == 0) return;
    final factor = dy > 0 ? 0.92 : 1.08;
    zoom = (zoom * factor).clamp(minZoom, maxZoom);
  }

  Offset _screenToWorld(Offset screen) {
    final center = Offset(size.x / 2, size.y / 2);
    return (screen - center - pan) / zoom + center;
  }

  Arrow? _hitTest(Offset world) {
    final layout = _layout();
    final hitRadius = max(10.0, layout.cell * 0.42);
    Arrow? best;
    var bestDist = hitRadius;
    var second = hitRadius;
    for (final arrow in _arrows) {
      var dist = double.infinity;
      for (var i = 1; i < arrow.points.length; i++) {
        final from = _cellCenter(arrow.points[i - 1], layout);
        final to = _cellCenter(arrow.points[i], layout);
        dist = min(dist, _distToSegment(world, from, to));
      }
      if (dist < bestDist) {
        second = bestDist;
        bestDist = dist;
        best = arrow;
      } else if (dist < second) {
        second = dist;
      }
    }
    // Ambiguous cluster — ignore rather than hitting the neighbor.
    if (best != null && second - bestDist < layout.cell * 0.12) {
      return null;
    }
    return best;
  }

  double _distToSegment(Offset p, Offset a, Offset b) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final len2 = dx * dx + dy * dy;
    if (len2 == 0) return (p - a).distance;
    final t = (((p.dx - a.dx) * dx + (p.dy - a.dy) * dy) / len2).clamp(
      0.0,
      1.0,
    );
    return (p - Offset(a.dx + dx * t, a.dy + dy * t)).distance;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (size.x <= 0 || size.y <= 0) return;

    canvas.save();
    final center = Offset(size.x / 2, size.y / 2);
    canvas.translate(center.dx + pan.dx, center.dy + pan.dy);
    canvas.scale(zoom);
    canvas.translate(-center.dx, -center.dy);

    final layout = _layout();
    _drawBoard(canvas, layout);

    for (final arrow in _arrows) {
      final blocked = _blocked[arrow.id];
      _drawArrow(
        canvas,
        arrow,
        layout,
        shake: blocked == null
            ? 0
            : sin(blocked.elapsed * 40) *
                  3 *
                  (1 - blocked.elapsed / _blockDuration),
        flashRed: blocked != null,
        flashAlpha: blocked == null
            ? 0
            : (1 - blocked.elapsed / _blockDuration).clamp(0.0, 1.0),
        pressed: arrow.id == _pressedId,
      );
      if (blocked != null) {
        _drawProhibition(canvas, arrow, layout, blocked.elapsed);
      }
    }

    for (final slither in _slithering) {
      _drawSlitheringSnake(canvas, slither, layout);
    }

    canvas.restore();
  }

  /// Snake slides along its body then out in the escape direction (not a fly).
  void _drawSlitheringSnake(
    Canvas canvas,
    _SlitheringArrow slither,
    _BoardLayout layout,
  ) {
    final arrow = slither.arrow;
    if (arrow.points.length < 2) return;

    final t = Curves.easeInOutCubic.transform(slither.progress.clamp(0.0, 1.0));
    final track = _buildEscapeTrack(arrow, layout);
    if (track.length < 2) return;

    final lengths = <double>[0];
    var total = 0.0;
    for (var i = 1; i < track.length; i++) {
      total += (track[i] - track[i - 1]).distance;
      lengths.add(total);
    }
    if (total <= 0) return;

    // Body length along original path only.
    var bodyLen = 0.0;
    for (var i = 1; i < arrow.points.length; i++) {
      bodyLen += (_cellCenter(arrow.points[i], layout) -
              _cellCenter(arrow.points[i - 1], layout))
          .distance;
    }

    final exitLen = total - bodyLen;
    final headDist = bodyLen + t * exitLen;
    final tailDist = max(0.0, headDist - bodyLen);

    final visible = _samplePolyline(track, lengths, total, tailDist, headDist);
    if (visible.length < 2) return;

    final color = Color(arrow.colorValue);
    final stroke = Paint()
      ..color = color
      ..strokeWidth = max(2.4, layout.cell * 0.28)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(visible.first.dx, visible.first.dy);
    for (final p in visible.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, stroke);
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.18)
        ..strokeWidth = max(1.2, layout.cell * 0.11)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    final tip = visible.last;
    final prev = visible[visible.length - 2];
    final dir = tip - prev;
    final dLen = dir.distance;
    if (dLen > 0.1) {
      _drawHeadAt(
        canvas,
        tip,
        Offset(dir.dx / dLen, dir.dy / dLen),
        layout.cell,
        color,
      );
    }
  }

  /// Tail → head → continued steps off the board along escape direction.
  List<Offset> _buildEscapeTrack(Arrow arrow, _BoardLayout layout) {
    final track = <Offset>[
      for (final p in arrow.points) _cellCenter(p, layout),
    ];

    final dx = arrow.facing.dx.toDouble();
    final dy = arrow.facing.dy.toDouble();
    final len = sqrt(dx * dx + dy * dy);
    final step = Offset(dx / len * layout.cell, dy / len * layout.cell);
    final exitSteps = max(_columns, _rows) + 6;
    var tip = track.last;
    for (var i = 0; i < exitSteps; i++) {
      tip += step;
      track.add(tip);
    }
    return track;
  }

  List<Offset> _samplePolyline(
    List<Offset> track,
    List<double> lengths,
    double total,
    double fromDist,
    double toDist,
  ) {
    final start = fromDist.clamp(0.0, total);
    final end = toDist.clamp(0.0, total);
    if (end - start < 0.5) return const [];

    final points = <Offset>[_pointAt(track, lengths, start)];
    for (var i = 1; i < lengths.length; i++) {
      if (lengths[i] <= start) continue;
      if (lengths[i] >= end) break;
      points.add(track[i]);
    }
    points.add(_pointAt(track, lengths, end));
    return points;
  }

  Offset _pointAt(List<Offset> track, List<double> lengths, double dist) {
    if (dist <= 0) return track.first;
    if (dist >= lengths.last) return track.last;
    for (var i = 1; i < lengths.length; i++) {
      if (dist <= lengths[i]) {
        final seg = lengths[i] - lengths[i - 1];
        final u = seg <= 0 ? 0.0 : (dist - lengths[i - 1]) / seg;
        return Offset.lerp(track[i - 1], track[i], u)!;
      }
    }
    return track.last;
  }

  void _drawBoard(Canvas canvas, _BoardLayout layout) {
    // Shape is defined by the arrows only — no board fill or border.
    // Optional faint dot grid (reference-style coordinate field).
    if (!showGrid) return;

    final dot = Paint()..color = const Color(0x22000000);
    final r = max(0.7, layout.cell * 0.06);
    for (var y = 0; y < _rows; y++) {
      for (var x = 0; x < _columns; x++) {
        final c = Offset(
          layout.origin.dx + (x + 0.5) * layout.cell,
          layout.origin.dy + (y + 0.5) * layout.cell,
        );
        canvas.drawCircle(c, r, dot);
      }
    }
  }

  void _drawArrow(
    Canvas canvas,
    Arrow arrow,
    _BoardLayout layout, {
    double shake = 0,
    bool flashRed = false,
    double flashAlpha = 0,
    double opacity = 1,
    bool pressed = false,
  }) {
    if (arrow.points.length < 2) return;

    final base = Color(arrow.colorValue);
    final color = Color.lerp(
      base,
      const Color(0xFFE53935),
      flashRed ? flashAlpha * 0.85 : 0,
    )!.withValues(alpha: opacity);

    final stroke = Paint()
      ..color = color
      ..strokeWidth = max(2.4, layout.cell * (pressed ? 0.38 : 0.28))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    // Stop the stroke before the tip so the triangle reads as the head,
    // not a round cap that can look like it points back into the body.
    final bodyEnd = arrow.points.length >= 3
        ? arrow.points.length - 1
        : arrow.points.length;
    final first = Offset(
      _cellCenter(arrow.points.first, layout).dx + shake,
      _cellCenter(arrow.points.first, layout).dy,
    );
    path.moveTo(first.dx, first.dy);
    for (var i = 1; i < bodyEnd; i++) {
      final c = _cellCenter(arrow.points[i], layout);
      path.lineTo(c.dx + shake, c.dy);
    }
    // Connect into the tip center under the head.
    final tipCenter = _cellCenter(arrow.points.last, layout);
    path.lineTo(tipCenter.dx + shake, tipCenter.dy);
    canvas.drawPath(path, stroke);

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.18 * opacity)
        ..strokeWidth = max(1.2, layout.cell * 0.11)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Draw head along tip facing (never toward the body).
    if (arrow.points.length >= 2) {
      final tip = arrow.points.last;
      final ux = arrow.facing.dx.toDouble();
      final uy = arrow.facing.dy.toDouble();
      final len = sqrt(ux * ux + uy * uy);
      if (len > 0) {
        _drawHeadAt(
          canvas,
          Offset(
            _cellCenter(tip, layout).dx + shake,
            _cellCenter(tip, layout).dy,
          ),
          Offset(ux / len, uy / len),
          layout.cell,
          color,
        );
      }
    }
  }

  void _drawHeadAt(
    Canvas canvas,
    Offset tip,
    Offset unitDir,
    double cell,
    Color color,
  ) {
    final ux = unitDir.dx;
    final uy = unitDir.dy;
    final size = cell * 0.52;

    final p1 = Offset(tip.dx + ux * size, tip.dy + uy * size);
    final p2 = Offset(
      tip.dx - ux * size * 0.35 - uy * size * 0.55,
      tip.dy - uy * size * 0.35 + ux * size * 0.55,
    );
    final p3 = Offset(
      tip.dx - ux * size * 0.35 + uy * size * 0.55,
      tip.dy - uy * size * 0.35 - ux * size * 0.55,
    );

    final head = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..close();

    canvas.drawPath(
      head,
      Paint()..color = Color.lerp(color, const Color(0xFF000000), 0.28)!,
    );
  }

  void _drawProhibition(
    Canvas canvas,
    Arrow arrow,
    _BoardLayout layout,
    double elapsed,
  ) {
    final alpha = (1 - elapsed / _blockDuration).clamp(0.0, 1.0);
    final tip = _cellCenter(arrow.head, layout);
    final r = layout.cell * 0.55;
    final paint = Paint()
      ..color = const Color(0xFFE53935).withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(tip, r, paint);
    canvas.drawLine(
      Offset(tip.dx - r * 0.65, tip.dy - r * 0.65),
      Offset(tip.dx + r * 0.65, tip.dy + r * 0.65),
      paint,
    );
  }

  _BoardLayout _layout() {
    const padding = 18.0;
    final cell = min(
      (size.x - padding * 2) / _columns,
      (size.y - padding * 2) / _rows,
    );
    return _BoardLayout(
      cell,
      Offset((size.x - cell * _columns) / 2, (size.y - cell * _rows) / 2),
    );
  }

  Offset _cellCenter(GridPoint p, _BoardLayout layout) => Offset(
    layout.origin.dx + (p.x + 0.5) * layout.cell,
    layout.origin.dy + (p.y + 0.5) * layout.cell,
  );
}

class _BoardLayout {
  const _BoardLayout(this.cell, this.origin);
  final double cell;
  final Offset origin;
}

class _SlitheringArrow {
  _SlitheringArrow({required this.arrow, required this.duration});

  final Arrow arrow;
  final double duration;
  double progress = 0;
}

class _BlockedState {
  double elapsed = 0;
}
