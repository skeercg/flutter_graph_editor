import 'dart:collection';
import 'dart:math';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'models.dart';
import 'physics.dart';

class GraphController extends ChangeNotifier {
  static const double vertexRadius = 20;

  static const _idlePauseThreshold = 0.05;
  static const _bendDistance = vertexRadius + 10;
  static const _maxSagitta = 2.5 * vertexRadius;
  static const _bendDuration = Duration(milliseconds: 200);

  final _positions = <Vertex, Offset>{};
  final _edges = <Edge>[];
  final _sagittas = <Edge, Sagitta>{};
  final _random = Random();
  late final _ticker = Ticker(_runForces);

  Rect _box = Rect.zero;
  Vertex? _dragged;
  Duration _lastTick = Duration.zero;

  Iterable<Vertex> get vertices => _positions.keys;

  UnmodifiableListView<Edge> get edges => UnmodifiableListView<Edge>(_edges);

  Rect get box => _box;

  set box(Rect value) {
    if (value == _box) return;
    _box = value;
    _unpauseIdle();
  }

  Offset positionOf(Vertex vertex) => _positions[vertex]!;

  void setEdges(List<(int?, int?)> pairs) {
    final vertices = {
      for (final (x, y) in pairs)
        for (final label in [x, y].whereType<int>()) Vertex(label),
    };

    _positions.removeWhere((vertex, _) => !vertices.contains(vertex));
    for (final vertex in vertices) {
      _positions.putIfAbsent(vertex, _randomPosition);
    }

    _edges
      ..clear()
      ..addAll([
        for (final (x, y) in pairs)
          if (x != null && y != null && x != y) Edge(Vertex(x), Vertex(y)),
      ]);
    _sagittas.removeWhere((edge, _) => !_edges.contains(edge));

    _unpauseIdle();
    notifyListeners();
  }

  Offset controlPoint(Edge edge) {
    final source = positionOf(edge.source);
    final target = positionOf(edge.target);
    final middle = (source + target) / 2;
    final delta = target - source;
    if (delta.distance < 1e-9) return middle;

    final normal = Offset(-delta.dy, delta.dx) / delta.distance;
    return middle + normal * (2 * (_sagittas[edge]?.current ?? 0));
  }

  void startDrag(Offset position) => _dragged = _vertexAt(position);

  void drag(Offset delta) {
    final vertex = _dragged;
    if (vertex == null) return;

    _positions[vertex] = _boundCoords(positionOf(vertex) + delta);
    _unpauseIdle();
  }

  void endDrag() {
    if (_dragged == null) return;

    _dragged = null;
    _unpauseIdle();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _unpauseIdle() {
    if (_ticker.isActive) return;

    _lastTick = Duration.zero;
    _ticker.start();
  }

  void _pauseIdle() => _ticker.stop();

  void _runForces(Duration elapsed) {
    final vertices = _positions.keys.toList();
    final points = _positions.values.toList();
    final index = {for (final (i, vertex) in vertices.indexed) vertex: i};

    final vectors = Physics(
      points: points,
      edges: [
        for (final edge in _edges) (index[edge.source]!, index[edge.target]!),
      ],
      gravityCenter: _dragged == null ? _box.center : null,
    ).calculateVectors();

    var maxDelta = 0.0;
    for (final (i, vertex) in vertices.indexed) {
      if (vertex == _dragged) continue;

      final position = _boundCoords(points[i] + vectors[i]);
      maxDelta = max(maxDelta, (position - points[i]).distance);
      _positions[vertex] = position;
    }

    final bending = _bendEdges(elapsed - _lastTick);
    _lastTick = elapsed;

    if (maxDelta < _idlePauseThreshold && !bending) _pauseIdle();
    notifyListeners();
  }

  bool _bendEdges(Duration frameTime) {
    final step =
        _maxSagitta * frameTime.inMicroseconds / _bendDuration.inMicroseconds;
    var bending = false;

    for (final edge in {..._edges}) {
      final sagitta = _sagittas[edge] ?? const Sagitta(0, 0);
      final current = sagitta.current +
          (sagitta.target - sagitta.current).clamp(-step, step);

      final side = _obstructedSide(edge);
      var target = sagitta.target;
      if (side == 0) {
        target = 0;
      } else if (current == 0) {
        target = -side * _maxSagitta;
      }

      _sagittas[edge] = Sagitta(current, target);
      bending |= current != target;
    }

    return bending;
  }

  int _obstructedSide(Edge edge) {
    final start = positionOf(edge.source);
    final direction = positionOf(edge.target) - start;
    final length = direction.distance;
    if (length < 1e-9) return 0;

    for (final vertex in _positions.keys) {
      if (vertex == edge.source || vertex == edge.target) continue;

      final offset = positionOf(vertex) - start;
      final along =
          (offset.dx * direction.dx + offset.dy * direction.dy) / length;
      final across =
          (direction.dx * offset.dy - direction.dy * offset.dx) / length;

      if (across.abs() <= _bendDistance && along >= 0 && along <= length) {
        return across > 0 ? 1 : -1;
      }
    }

    return 0;
  }

  Vertex? _vertexAt(Offset position) {
    Vertex? hit;
    for (final vertex in _positions.keys) {
      if ((positionOf(vertex) - position).distance <= vertexRadius) {
        hit = vertex;
      }
    }

    return hit;
  }

  Offset _boundCoords(Offset coords) {
    final area = _box.deflate(vertexRadius);

    return Offset(
      min(max(coords.dx, area.left), area.right),
      min(max(coords.dy, area.top), area.bottom),
    );
  }

  Offset _randomPosition() => Offset(
        _box.left + _random.nextDouble() * _box.width,
        _box.top + _random.nextDouble() * _box.height,
      );
}
