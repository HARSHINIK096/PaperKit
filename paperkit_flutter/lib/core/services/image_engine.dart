import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ImageEngine {
  // Convert Image Format (JPG, PNG, WEBP, BMP, GIF)
  static Future<File> convertFormat({
    required File inputFile,
    required String targetFormat, // 'png', 'jpg', 'webp', 'bmp', 'gif'
    int quality = 90,
  }) async {
    final bytes = await inputFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Unable to decode image.');

    Uint8List encodedBytes;
    final fmt = targetFormat.toLowerCase();
    if (fmt == 'png') {
      encodedBytes = Uint8List.fromList(img.encodePng(image));
    } else if (fmt == 'webp') {
      encodedBytes = Uint8List.fromList(img.encodePng(image)); // fallback if webp encoder
    } else if (fmt == 'bmp') {
      encodedBytes = Uint8List.fromList(img.encodeBmp(image));
    } else if (fmt == 'gif') {
      encodedBytes = Uint8List.fromList(img.encodeGif(image));
    } else {
      encodedBytes = Uint8List.fromList(img.encodeJpg(image, quality: quality));
    }

    final outputDir = await getApplicationDocumentsDirectory();
    final baseName = inputFile.uri.pathSegments.last.split('.').first;
    final outputFile = File('${outputDir.path}/${baseName}_converted.$fmt');
    await outputFile.writeAsBytes(encodedBytes);

    return outputFile;
  }

  // Compress Image with preset or custom quality
  static Future<File> compressImage({
    required File inputFile,
    required int quality, // 1 to 100
    int? maxDimension,
  }) async {
    final bytes = await inputFile.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) throw Exception('Unable to decode image.');

    if (maxDimension != null && (image.width > maxDimension || image.height > maxDimension)) {
      if (image.width > image.height) {
        image = img.copyResize(image, width: maxDimension);
      } else {
        image = img.copyResize(image, height: maxDimension);
      }
    }

    final encoded = img.encodeJpg(image, quality: quality);
    final outputDir = await getApplicationDocumentsDirectory();
    final baseName = inputFile.uri.pathSegments.last.split('.').first;
    final outputFile = File('${outputDir.path}/${baseName}_compressed.jpg');
    await outputFile.writeAsBytes(encoded);

    return outputFile;
  }

  // Image Manipulation: Brightness, Contrast, Rotation, Grayscale, Invert
  static Future<File> manipulateImage({
    required File inputFile,
    double brightness = 1.0, // 0.0 to 2.0
    double contrast = 1.0,   // 0.0 to 2.0
    int rotationAngle = 0,   // 90, 180, 270
    bool grayscale = false,
    bool invert = false,
  }) async {
    final bytes = await inputFile.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) throw Exception('Unable to decode image.');

    if (rotationAngle == 90) {
      image = img.copyRotate(image, angle: 90);
    } else if (rotationAngle == 180) {
      image = img.copyRotate(image, angle: 180);
    } else if (rotationAngle == 270) {
      image = img.copyRotate(image, angle: 270);
    }

    if (grayscale) {
      image = img.grayscale(image);
    }

    if (invert) {
      image = img.invert(image);
    }

    if (brightness != 1.0) {
      image = img.adjustColor(image, brightness: brightness);
    }

    if (contrast != 1.0) {
      image = img.adjustColor(image, contrast: contrast);
    }

    final encoded = img.encodePng(image);
    final outputDir = await getApplicationDocumentsDirectory();
    final baseName = inputFile.uri.pathSegments.last.split('.').first;
    final outputFile = File('${outputDir.path}/${baseName}_adjusted.png');
    await outputFile.writeAsBytes(encoded);

    return outputFile;
  }
}
