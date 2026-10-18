import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'graph_controller.dart';
import 'graph_data_menu.dart';
import 'graph_view.dart';
import 'theme.dart';

class GraphEditorScreen extends StatelessWidget {
  const GraphEditorScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (context) => GraphController(),
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.primary,
          ),
          body: const Center(
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GraphDataMenu(),
                    SizedBox(width: 30),
                    GraphView(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
