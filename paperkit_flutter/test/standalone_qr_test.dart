import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:maskerv_flutter/features/qr_tools/models/qr_parsed_payload.dart';
import 'package:maskerv_flutter/features/qr_tools/services/qr_image_decoder.dart';
import 'package:maskerv_flutter/features/qr_tools/services/qr_payload_parser.dart';
import 'package:qr/qr.dart';

void main() {
  print('=== STARTING STANDALONE QR ENGINE TESTS ===');

  // 1. Test Wi-Fi parsing
  const wifiRaw = 'WIFI:T:WPA;S:CoffeeShop_5G;P:Latte12345;H:false;;';
  final wifi = QrPayloadParser.parse(wifiRaw);
  assert(wifi.type == QrPayloadType.wifi, 'Wi-Fi type match');
  assert(wifi.ssid == 'CoffeeShop_5G', 'SSID match');
  assert(wifi.password == 'Latte12345', 'Password match');
  assert(wifi.securityType == 'WPA', 'Security match');
  print('[PASS] Wi-Fi Parser');

  // 2. Test vCard parsing
  const vcardRaw = '''BEGIN:VCARD
VERSION:3.0
N:Lovelace;Ada;;;
FN:Ada Lovelace
ORG:Analytical Engine
TEL;TYPE=CELL:+44123456789
EMAIL:ada@lovelace.org
END:VCARD''';
  final vcard = QrPayloadParser.parse(vcardRaw);
  assert(vcard.type == QrPayloadType.vcard, 'vCard type match');
  assert(vcard.contactName == 'Ada Lovelace', 'Contact name match');
  assert(vcard.phone == '+44123456789', 'Phone match');
  assert(vcard.email == 'ada@lovelace.org', 'Email match');
  print('[PASS] vCard Parser');

  // 3. Test URL & Security check
  final secureUrl = QrPayloadParser.parse('https://maskerv.app/tools');
  assert(secureUrl.type == QrPayloadType.url && !secureUrl.isSuspiciousUrl, 'Secure URL match');

  final insecureUrl = QrPayloadParser.parse('http://192.168.1.1/admin');
  assert(insecureUrl.type == QrPayloadType.url && insecureUrl.isSuspiciousUrl, 'Suspicious URL match');
  print('[PASS] URL Parser & Security');

  // 4. Test Phone, Email, SMS, Geo, Calendar
  final tel = QrPayloadParser.parse('tel:+15551234567');
  assert(tel.type == QrPayloadType.phone && tel.phone == '+15551234567', 'Tel match');

  final email = QrPayloadParser.parse('mailto:support@maskerv.app?subject=Hello');
  assert(email.type == QrPayloadType.email && email.email == 'support@maskerv.app', 'Email match');

  final geo = QrPayloadParser.parse('geo:37.7749,-122.4194');
  assert(geo.type == QrPayloadType.geo && geo.latitude == 37.7749, 'Geo match');

  final event = QrPayloadParser.parse('BEGIN:VEVENT\nSUMMARY:Conference\nLOCATION:Hall A\nEND:VEVENT');
  assert(event.type == QrPayloadType.calendar && event.eventTitle == 'Conference', 'Event match');
  print('[PASS] Telephony, Email, Geo, and Calendar Parsers');

  // 5. Test Pure Dart QR Generation & zxing_lib Decoding Roundtrip
  const testString = 'https://maskerv.app/test-roundtrip-verified';
  final qrCode = QrCode.fromData(data: testString, errorCorrectLevel: QrErrorCorrectLevel.M);
  final qrImg = QrImage(qrCode);
  final count = qrImg.moduleCount;

  const scale = 8;
  const qZone = 4;
  final dim = (count + (qZone * 2)) * scale;
  final image = img.Image(width: dim, height: dim);
  img.fill(image, color: img.ColorRgb8(255, 255, 255));

  for (int y = 0; y < count; y++) {
    for (int x = 0; x < count; x++) {
      if (qrImg.isDark(y, x)) {
        img.fillRect(
          image,
          x1: (x + qZone) * scale,
          y1: (y + qZone) * scale,
          x2: (x + qZone + 1) * scale,
          y2: (y + qZone + 1) * scale,
          color: img.ColorRgb8(0, 0, 0),
        );
      }
    }
  }

  final pngBytes = Uint8List.fromList(img.encodePng(image));
  final decoded = QrImageDecoder.decodeBytes(pngBytes);
  assert(decoded != null, 'Decoded must not be null');
  assert(decoded!.rawData == testString, 'Decoded rawData matches original');
  assert(decoded!.domain == 'maskerv.app', 'Decoded domain matches');
  print('[PASS] Pure Dart QR Matrix Generation & zxing_lib Decoding Roundtrip');

  print('=== ALL STANDALONE QR ENGINE TESTS PASSED! ===');
}
