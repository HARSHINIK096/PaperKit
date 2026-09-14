import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';

class ArchiveEngine {
  // Create Archive (ZIP, TAR, TAR.GZ) from list of files
  static Future<File> createArchive({
    required List<File> files,
    required String archiveName,
    String format = 'zip',
    String? password,
  }) async {
    final archive = Archive();

    for (final file in files) {
      final bytes = await file.readAsBytes();
      final fileName = file.uri.pathSegments.last;
      archive.addFile(ArchiveFile(fileName, bytes.length, bytes));
    }

    List<int>? encodedBytes;
    String extension = '.zip';

    final fmt = format.toLowerCase().trim();
    if (fmt == 'tar') {
      encodedBytes = TarEncoder().encode(archive);
      extension = '.tar';
    } else if (fmt == 'tar.gz' || fmt == 'tgz') {
      final tarBytes = TarEncoder().encode(archive);
      encodedBytes = GZipEncoder().encode(tarBytes);
      extension = '.tar.gz';
    } else if (fmt == 'tar.bz2' || fmt == 'tbz') {
      final tarBytes = TarEncoder().encode(archive);
      encodedBytes = BZip2Encoder().encode(tarBytes);
      extension = '.tar.bz2';
    } else if (fmt == 'gz') {
      final tarBytes = TarEncoder().encode(archive);
      encodedBytes = GZipEncoder().encode(tarBytes);
      extension = '.gz';
    } else if (fmt == 'bz2') {
      final tarBytes = TarEncoder().encode(archive);
      encodedBytes = BZip2Encoder().encode(tarBytes);
      extension = '.bz2';
    } else {
      encodedBytes = ZipEncoder(password: password).encode(archive);
      extension = '.zip';
    }

    final outputDir = await getApplicationDocumentsDirectory();
    final cleanName = archiveName.endsWith(extension)
        ? archiveName
        : '$archiveName$extension';
    final outputFile = File('${outputDir.path}/$cleanName');
    await outputFile.writeAsBytes(encodedBytes);

    return outputFile;
  }

  // Legacy alias for compatibility
  static Future<File> createZip({
    required List<File> files,
    required String archiveName,
  }) => createArchive(files: files, archiveName: archiveName, format: 'zip');

  // Extract Archive (ZIP, TAR, GZ, BZ2)
  static Future<List<File>> extractArchive(File archiveFile, {String? password}) async {
    final bytes = await archiveFile.readAsBytes();
    final outputDir = await getApplicationDocumentsDirectory();
    final targetExtractDir = Directory(
      '${outputDir.path}/extracted_${DateTime.now().millisecondsSinceEpoch}',
    );
    if (!await targetExtractDir.exists()) {
      await targetExtractDir.create(recursive: true);
    }

    final List<File> extractedFiles = [];
    final fileName = archiveFile.uri.pathSegments.last.toLowerCase();

    late Archive archive;

    try {
      if (fileName.endsWith('.tar.gz') || fileName.endsWith('.tgz')) {
        final decompressedGzip = GZipDecoder().decodeBytes(bytes);
        archive = TarDecoder().decodeBytes(decompressedGzip);
      } else if (fileName.endsWith('.tar')) {
        archive = TarDecoder().decodeBytes(bytes);
      } else if (fileName.endsWith('.tar.bz2') || fileName.endsWith('.tbz')) {
        final decompressedBz2 = BZip2Decoder().decodeBytes(bytes);
        archive = TarDecoder().decodeBytes(decompressedBz2);
      } else if (fileName.endsWith('.gz')) {
        final decompressed = GZipDecoder().decodeBytes(bytes);
        final rawName = fileName.replaceAll('.gz', '');
        final outFile = File('${targetExtractDir.path}/$rawName');
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(decompressed);
        return [outFile];
      } else {
        // ZIP
        archive = ZipDecoder().decodeBytes(bytes, password: password);
      }
    } catch (e) {
      // Fallback ZipDecoder attempt if extension check failed
      try {
        archive = ZipDecoder().decodeBytes(bytes, password: password);
      } catch (e2) {
        throw Exception('Archive decoding failed. If password-protected or unsupported format, verify password and format.');
      }
    }

    for (final file in archive) {
      final fname = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        final outFile = File('${targetExtractDir.path}/$fname');
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(data);
        extractedFiles.add(outFile);
      }
    }

    return extractedFiles;
  }
}
