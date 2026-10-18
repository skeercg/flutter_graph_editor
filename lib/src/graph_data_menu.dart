import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'graph_controller.dart';
import 'models.dart';
import 'theme.dart';

const _editorPadding = EdgeInsets.symmetric(vertical: 5);

class GraphDataMenu extends StatefulWidget {
  const GraphDataMenu({super.key});

  @override
  State<GraphDataMenu> createState() => _GraphDataMenuState();
}

class _GraphDataMenuState extends State<GraphDataMenu> {
  late final TextEditingController _textEditingController;
  int _linesCount = 1;
  GraphType _graphType = GraphType.undirected;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController()
      ..addListener(() {
        setState(() {
          _linesCount = _textEditingController.text.split('\n').length;

          final edges = _textEditingController.text.split('\n').map((e) {
            final vertices = e.split(' ').map(int.tryParse).whereType<int>();
            return (vertices.firstOrNull, vertices.elementAtOrNull(1));
          }).toList();

          Provider.of<GraphController>(context, listen: false).setEdges(edges);
        });
      });
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge!.merge(AppFonts.font14);
    final strutStyle = StrutStyle.fromTextStyle(style, forceStrutHeight: true);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final type in GraphType.values)
              ChoiceChip(
                label: Text(type.label),
                selected: _graphType == type,
                showCheckmark: false,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: _graphType == type ? Colors.white : null,
                ),
                onSelected: (_) => setState(() => _graphType = type),
              ),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Graph Data:'),
        SizedBox(
          height: 350,
          child: SingleChildScrollView(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: AppColors.secondary,
                  width: 40,
                  constraints: const BoxConstraints(minHeight: 350),
                  padding: _editorPadding.copyWith(right: 10),
                  child: Text(
                    List.generate(_linesCount, (i) => '${i + 1}').join('\n'),
                    textAlign: TextAlign.end,
                    style: style,
                    strutStyle: strutStyle,
                  ),
                ),
                Container(
                  width: 320,
                  constraints: const BoxConstraints(minHeight: 350),
                  padding: _editorPadding,
                  child: TextField(
                    controller: _textEditingController,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    maxLines: null,
                    style: style,
                    strutStyle: strutStyle,
                    cursorColor: Colors.black,
                    scrollPadding: const EdgeInsets.only(top: 5, bottom: 5),
                    decoration: null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
