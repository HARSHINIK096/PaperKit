import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/qrcode.dart';
import 'package:zxing_lib/zxing.dart';
import '../models/qr_parsed_payload.dart';
import 'qr_payload_parser.dart';

class QrImageDecoder {
  const QrImageDecoder._();

  /// Decodes a QR code from a file and returns the structured [QrParsedPayload], or null if not found.
  static Future<QrParsedPayload?> decodeFile(File file) async {
    final bytes = await file.readAsBytes();
    return decodeBytes(bytes);
  }

  /// Decodes a QR code from raw image bytes.
  static QrParsedPayload? decodeBytes(Uint8List bytes) {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final width = image.width;
      final height = image.height;
      final pixels = Int32List(width * height);

      int index = 0;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final pixel = image.getPixel(x, y);
          pixels[index++] = (pixel.a.toInt() << 24) |
              (pixel.r.toInt() << 16) |
              (pixel.g.toInt() << 8) |
              pixel.b.toInt();
        }
      }

      final source = RGBLuminanceSource(width, height, pixels);
      final binarizer = HybridBinarizer(source);
      final bitmap = BinaryBitmap(binarizer);
      final reader = QRCodeReader();

      final result = reader.decode(bitmap);
      final rawText = result.text;
      if (rawText.isEmpty) return null;

      return QrPayloadParser.parse(rawText);
    } catch (_) {
      return null;
    }
  }
}
