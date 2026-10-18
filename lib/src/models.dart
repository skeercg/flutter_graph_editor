import 'package:flutter/foundation.dart';

@immutable
class Vertex {
  final int label;

  const Vertex(this.label);

  @override
  bool operator ==(covariant Vertex other) => other.label == label;

  @override
  int get hashCode => label.hashCode;
}

@immutable
class Edge {
  final Vertex source;
  final Vertex target;

  const Edge(this.source, this.target);

  @override
  bool operator ==(covariant Edge other) =>
      other.source == source && other.target == target;

  @override
  int get hashCode => Object.hash(source, target);
}

@immutable
class Sagitta {
  final double current;
  final double target;

  const Sagitta(this.current, this.target);

  @override
  bool operator ==(covariant Sagitta other) =>
      other.current == current && other.target == target;

  @override
  int get hashCode => Object.hash(current, target);
}
