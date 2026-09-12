import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

extension PlatformFileExt on PlatformFile {
  /// Safely checks if the file has valid picked content without throwing on Flutter Web.
  bool get hasValidFile {
    if (kIsWeb) {
      return bytes != null && bytes!.isNotEmpty;
    }
    return (path != null && path!.isNotEmpty) || (bytes != null && bytes!.isNotEmpty);
  }

  /// Safely gets the file path on non-web platforms, returning null on Web without accessing .path.
  String? get safePath {
    if (kIsWeb) return null;
    return path;
  }

  /// Safely returns a File instance on non-web platforms, or null on Web.
  File? get asFile {
    if (kIsWeb) return null;
    final p = safePath;
    if (p == null || p.isEmpty) return null;
    return File(p);
  }
}
