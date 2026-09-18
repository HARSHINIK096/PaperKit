import 'package:flutter/material.dart';
import '../../core/constants/app_tools.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/tool_card.dart';

class AIToolsHubScreen extends StatelessWidget {
  const AIToolsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'AI Document Intelligence',
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: AppTools.aiTools.length,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 115,
          mainAxisExtent: 105,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          return ToolCard(tool: AppTools.aiTools[index]);
        },
      ),
    );
  }
}
