import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_tools.dart';
import '../../core/models/tool_item.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/tool_card.dart';

class CategoryHubScreen extends StatelessWidget {
  final String categoryId;

  const CategoryHubScreen({super.key, required this.categoryId});

  ToolCategory get _category {
    switch (categoryId.toLowerCase()) {
      case 'pdf':
        return ToolCategory.pdf;
      case 'ai':
        return ToolCategory.ai;
      case 'security':
        return ToolCategory.security;
      case 'image':
        return ToolCategory.image;
      case 'video':
      case 'audio':
      case 'media':
        return ToolCategory.video;
      case 'archive':
        return ToolCategory.archive;
      default:
        return ToolCategory.pdf;
    }
  }

  String get _categoryTitle {
    switch (_category) {
      case ToolCategory.pdf:
        return 'PDF Tools Hub';
      case ToolCategory.ai:
        return 'AI Intelligence Hub';
      case ToolCategory.security:
        return 'Security & Privacy Hub';
      case ToolCategory.image:
        return 'Image Processing Hub';
      case ToolCategory.video:
      case ToolCategory.audio:
      case ToolCategory.media:
        return 'Media & Video Hub';
      case ToolCategory.archive:
        return 'Archive Studio Hub';
      default:
        return 'Tools Hub';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tools = AppTools.allTools.where((t) {
      if (categoryId.toLowerCase() == 'media' ||
          categoryId.toLowerCase() == 'video' ||
          categoryId.toLowerCase() == 'audio') {
        return t.category == ToolCategory.video ||
            t.category == ToolCategory.audio ||
            t.category == ToolCategory.media;
      }
      return t.category == _category;
    }).toList();

    return AppShell(
      title: _categoryTitle,
      actions: [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ],
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tools.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.15,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          return ToolCard(tool: tools[index]);
        },
      ),
    );
  }
}
