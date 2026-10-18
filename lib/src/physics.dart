import 'dart:math';
import 'dart:ui';

class Physics {
  static final _random = Random();

  final List<Offset> points;
  final List<(int, int)> edges;
  final Offset? gravityCenter;
  final double chargeStrength;
  final double edgeStrength;
  final double gravityStrength;
  final double idealEdgeDistance;
  final double repulsionDistance;

  Physics({
    required this.points,
    required this.edges,
    this.gravityCenter,
    this.chargeStrength = 10,
    this.edgeStrength = 15,
    this.gravityStrength = 0.007,
    this.idealEdgeDistance = 140,
    this.repulsionDistance = 140,
  });

  List<Offset> calculateVectors() {
    final vectors = List.filled(points.length, Offset.zero);
    final center = gravityCenter;

    _calculateAttractions(vectors);
    if (center != null) _gravitateTowards(vectors, center);

    return vectors;
  }

  List<List<bool>> _buildAdjacencyMatrix() {
    final matrix = List.generate(
      points.length,
      (_) => List.filled(points.length, false),
    );

    for (final (first, second) in edges) {
      matrix[first][second] = true;
      matrix[second][first] = true;
    }

    return matrix;
  }

  void _calculateAttractions(List<Offset> vectors) {
    final adjacent = _buildAdjacencyMatrix();

    for (var i = 0; i < points.length; i++) {
      for (var j = i + 1; j < points.length; j++) {
        final dist = (points[j] - points[i]).distance;

        if (adjacent[i][j]) {
          final force = _force(edgeStrength, dist, idealEdgeDistance);
          _updateVectors(vectors, i, j, force);
        } else if (dist < repulsionDistance) {
          final force = _force(chargeStrength, dist, repulsionDistance);
          _updateVectors(vectors, i, j, force);
        }
      }
    }
  }

  double _force(double strength, double dist, double restDistance) =>
      dist < 1e-9 ? 1000 : strength * (dist - restDistance) / dist;

  void _updateVectors(List<Offset> vectors, int i, int j, double force) {
    var delta = points[j] - points[i];
    if (delta.distance < 1e-9) {
      delta = Offset.fromDirection(_random.nextDouble() * 2 * pi);
    }

    final pull = delta / delta.distance * force;
    vectors[i] += pull;
    vectors[j] -= pull;
  }

  void _gravitateTowards(List<Offset> vectors, Offset center) {
    for (var i = 0; i < points.length; i++) {
      vectors[i] += (center - points[i]) * gravityStrength;
    }
  }
}
