import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'graph_controller.dart';
import 'theme.dart';

class GraphView extends StatelessWidget {
  const GraphView({super.key});

  @override
  Widget build(BuildContext context) {
    final graph = Provider.of<GraphController>(context, listen: false);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary),
      ),
      width: 800,
      height: 800,
      child: LayoutBuilder(
        builder: (context, constraints) {
          graph.box = (Offset.zero & constraints.biggest).deflate(20);

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onPanDown: (details) => graph.startDrag(details.localPosition),
            onPanUpdate: (details) => graph.drag(details.delta),
            onPanEnd: (_) => graph.endDrag(),
            onPanCancel: graph.endDrag,
            child: CustomPaint(painter: GraphPainter(graph)),
          );
        },
      ),
    );
  }
}

class GraphPainter extends CustomPainter {
  final GraphController graph;

  const GraphPainter(this.graph) : super(repaint: graph);

  @override
  void paint(Canvas canvas, Size size) {
    final edgePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final vertexPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    final path = Path();

    for (final edge in graph.edges) {
      final source = graph.positionOf(edge.source);
      final target = graph.positionOf(edge.target);
      final control = graph.controlPoint(edge);

      path
        ..moveTo(source.dx, source.dy)
        ..quadraticBezierTo(control.dx, control.dy, target.dx, target.dy);
    }

    canvas.drawPath(path, edgePaint);

    for (final vertex in graph.vertices) {
      final position = graph.positionOf(vertex);
      canvas.drawCircle(position, GraphController.vertexRadius, vertexPaint);

      final textSpan = TextSpan(
        text: vertex.label.toString(),
        style: AppFonts.font18,
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final textOffset = Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      );

      textPainter
        ..paint(canvas, textOffset)
        ..dispose();
    }
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) =>
      oldDelegate.graph != graph;
}
