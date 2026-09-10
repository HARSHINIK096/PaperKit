import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';

class ArchiveEngine {
  // Create ZIP from list of files
  static Future<File> createZip({
    required List<File> files,
    required String archiveName,
  }) async {
    final archive = Archive();

    for (final file in files) {
      final bytes = await file.readAsBytes();
      final fileName = file.uri.pathSegments.last;
      archive.addFile(ArchiveFile(fileName, bytes.length, bytes));
    }

    final zipEncoder = ZipEncoder();
    final encodedZip = zipEncoder.encode(archive);

    final outputDir = await getApplicationDocumentsDirectory();
    final outputFile = File('${outputDir.path}/$archiveName.zip');
    await outputFile.writeAsBytes(encodedZip);

    return outputFile;
  }

  // Extract Archive (ZIP, TAR, GZ)
  static Future<List<File>> extractArchive(File archiveFile) async {
    final bytes = await archiveFile.readAsBytes();
    final outputDir = await getApplicationDocumentsDirectory();
    final targetExtractDir = Directory('${outputDir.path}/extracted_${DateTime.now().millisecondsSinceEpoch}');
    if (!await targetExtractDir.exists()) {
      await targetExtractDir.create(recursive: true);
    }

    final List<File> extractedFiles = [];
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        final outFile = File('${targetExtractDir.path}/$filename');
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(data);
        extractedFiles.add(outFile);
      }
    }

    return extractedFiles;
  }
}
