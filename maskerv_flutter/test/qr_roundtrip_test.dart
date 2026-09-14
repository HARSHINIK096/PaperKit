import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maskerv_flutter/features/qr_tools/models/qr_parsed_payload.dart';
import 'package:maskerv_flutter/features/qr_tools/services/qr_image_decoder.dart';
import 'package:qr/qr.dart';

void main() {
  test('Pure Dart QR generation and zxing_lib decoding roundtrip test', () {
    const originalText = 'https://maskerv.app/docs';

    // 1. Generate QR matrix with qr package
    final qrCode = QrCode.fromData(
      data: originalText,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final qrImage = QrImage(qrCode);
    final moduleCount = qrImage.moduleCount;

    // 2. Render to bitmap pixels using image package
    const scale = 8;
    const quietZone = 4;
    final imgSize = (moduleCount + (quietZone * 2)) * scale;
    final image = img.Image(width: imgSize, height: imgSize);

    // Fill white
    img.fill(image, color: img.ColorRgb8(255, 255, 255));

    // Draw dark modules
    for (int y = 0; y < moduleCount; y++) {
      for (int x = 0; x < moduleCount; x++) {
        if (qrImage.isDark(y, x)) {
          final px = (x + quietZone) * scale;
          final py = (y + quietZone) * scale;
          img.fillRect(image, x1: px, y1: py, x2: px + scale, y2: py + scale, color: img.ColorRgb8(0, 0, 0));
        }
      }
    }

    final pngBytes = Uint8List.fromList(img.encodePng(image));

    // 3. Decode directly using pure Dart QrImageDecoder (zxing_lib)
    final decodedPayload = QrImageDecoder.decodeBytes(pngBytes);

    expect(decodedPayload, isNotNull);
    expect(decodedPayload!.type, QrPayloadType.url);
    expect(decodedPayload.rawData, originalText);
    expect(decodedPayload.domain, 'maskerv.app');
  });
}
