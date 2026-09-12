import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  /// Shares a file directly via native system share sheet (WhatsApp, Telegram, Drive, etc.)
  static Future<void> shareFile({
    required String filePath,
    String? subject,
    String? text,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File does not exist at path: $filePath');
    }
    final xFile = XFile(filePath);
    await Share.shareXFiles(
      [xFile],
      subject: subject ?? 'Shared from PaperKit',
      text: text ?? 'Here is your document exported from PaperKit.',
    );
  }

  /// Shares multiple files at once
  static Future<void> shareMultipleFiles({
    required List<String> filePaths,
    String? subject,
    String? text,
  }) async {
    final xFiles = <XFile>[];
    for (final path in filePaths) {
      if (await File(path).exists()) {
        xFiles.add(XFile(path));
      }
    }
    if (xFiles.isEmpty) {
      throw Exception('No valid files found to share.');
    }
    await Share.shareXFiles(
      xFiles,
      subject: subject ?? 'Shared Documents from PaperKit',
      text: text ?? 'Here are your documents exported from PaperKit.',
    );
  }

  /// Opens a file with the system default viewer application
  static Future<OpenResult> openFile(String filePath) async {
    return await OpenFilex.open(filePath);
  }

  /// Shares plain text (e.g. citations, summary text, audit logs)
  static Future<void> shareText({
    required String content,
    String? subject,
  }) async {
    await Share.share(
      content,
      subject: subject ?? 'Shared from PaperKit',
    );
  }
}
