import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';

/// Representation of a target tool in the connected tools pipeline.
class ConnectedToolDescriptor {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final String routeName;

  const ConnectedToolDescriptor({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.routeName,
  });
}

/// Global Data Bridge for chaining inputs and outputs between MaskerV tools.
class ToolDataBridge {
  static final ToolDataBridge _instance = ToolDataBridge._internal();
  factory ToolDataBridge() => _instance;
  ToolDataBridge._internal();

  File? _activeFile;
  String? _activeTextContent;
  String? _sourceToolId;
  Map<String, dynamic>? _activeMetadata;

  File? get activeFile => _activeFile;
  String? get activeTextContent => _activeTextContent;
  String? get sourceToolId => _sourceToolId;
  Map<String, dynamic>? get activeMetadata => _activeMetadata;

  void setPayload({
    File? file,
    String? textContent,
    required String sourceToolId,
    Map<String, dynamic>? metadata,
  }) {
    _activeFile = file;
    _activeTextContent = textContent;
    _sourceToolId = sourceToolId;
    _activeMetadata = metadata;
  }

  void clearPayload() {
    _activeFile = null;
    _activeTextContent = null;
    _sourceToolId = null;
    _activeMetadata = null;
  }

  /// Get connected target tools for a given source tool ID.
  List<ConnectedToolDescriptor> getConnectedTools(String sourceToolId) {
    const allDescriptors = [
      ConnectedToolDescriptor(
        id: 'quiz-generator',
        name: 'Quiz Generator',
        description: 'Generate MCQ, True/False & Short Answer study tests',
        icon: LucideIcons.clipboardCheck,
        color: AppColors.toolRed,
        routeName: '/quiz-generator',
      ),
      ConnectedToolDescriptor(
        id: 'flashcards',
        name: 'Flashcard Maker',
        description: 'Create spaced repetition study & recall cards',
        icon: LucideIcons.layers,
        color: AppColors.toolOrange,
        routeName: '/flashcards',
      ),
      ConnectedToolDescriptor(
        id: 'mind-map',
        name: 'Mind Map Generator',
        description: 'Build visual hierarchical concept trees',
        icon: LucideIcons.gitFork,
        color: AppColors.toolPurple,
        routeName: '/mind-map',
      ),
      ConnectedToolDescriptor(
        id: 'pdf-summarizer',
        name: 'AI Document Summarizer',
        description: 'Synthesize complex papers into core insights',
        icon: LucideIcons.fileText,
        color: AppColors.toolBlue,
        routeName: '/pdf-summarizer',
      ),
      ConnectedToolDescriptor(
        id: 'dual-pane-reader',
        name: 'Dual-Pane Reader',
        description: 'Compare with reference notes side-by-side',
        icon: LucideIcons.columns,
        color: AppColors.toolTeal,
        routeName: '/dual-pane-reader',
      ),
      ConnectedToolDescriptor(
        id: 'translate-pdf',
        name: 'AI Document Translator',
        description: 'Translate document contents to 20+ languages',
        icon: LucideIcons.languages,
        color: AppColors.toolGreen,
        routeName: '/translate-pdf',
      ),
      ConnectedToolDescriptor(
        id: 'p2p-share',
        name: 'AirShare P2P Beam',
        description: 'Share document & results to nearby devices offline',
        icon: LucideIcons.wifi,
        color: AppColors.toolPink,
        routeName: '/p2p-share',
      ),
    ];

    // Filter out the current tool so users chain to a different tool
    return allDescriptors.where((tool) => tool.id != sourceToolId).toList();
  }
}
