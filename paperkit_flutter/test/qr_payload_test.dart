import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maskerv_flutter/features/qr_tools/models/qr_content_type.dart';
import 'package:maskerv_flutter/features/qr_tools/models/qr_design_config.dart';
import 'package:maskerv_flutter/features/qr_tools/models/qr_parsed_payload.dart';
import 'package:maskerv_flutter/features/qr_tools/services/qr_payload_formatter.dart';
import 'package:maskerv_flutter/features/qr_tools/services/qr_payload_parser.dart';
import 'package:maskerv_flutter/features/qr_tools/services/qr_export_service.dart';
import 'package:maskerv_flutter/features/qr_tools/widgets/qr_readability_badge.dart';

void main() {
  group('QrPayloadFormatter Tests', () {
    test('Formats URL with https scheme', () {
      final formatted = QrPayloadFormatter.format(
        type: QrContentType.url,
        values: {'url': 'paperkit.app'},
      );
      expect(formatted, 'https://paperkit.app');
    });

    test('Formats Wi-Fi configuration payload correctly', () {
      final formatted = QrPayloadFormatter.format(
        type: QrContentType.wifi,
        values: {
          'ssid': 'Lab_Network',
          'password': 'Pass;word:123',
          'type': 'WPA',
          'hidden': 'false',
        },
      );
      expect(formatted.startsWith('WIFI:T:WPA;S:Lab_Network;P:Pass\\;word\\:123;H:false;;'), isTrue);
    });

    test('Formats vCard contact card correctly', () {
      final formatted = QrPayloadFormatter.format(
        type: QrContentType.vcard,
        values: {
          'firstName': 'Marie',
          'lastName': 'Curie',
          'organization': 'Sorbonne',
          'phone': '+33123456789',
          'email': 'marie@curie.org',
        },
      );
      expect(formatted.contains('BEGIN:VCARD'), isTrue);
      expect(formatted.contains('FN:Marie Curie'), isTrue);
      expect(formatted.contains('TEL;TYPE=CELL:+33123456789'), isTrue);
      expect(formatted.contains('EMAIL:marie@curie.org'), isTrue);
      expect(formatted.contains('END:VCARD'), isTrue);
    });

    test('Formats Social handles to actual URLs', () {
      final github = QrPayloadFormatter.format(
        type: QrContentType.github,
        values: {'username': 'paperkit-dev'},
      );
      expect(github, 'https://github.com/paperkit-dev');

      final instagram = QrPayloadFormatter.format(
        type: QrContentType.instagram,
        values: {'username': '@design_studio'},
      );
      expect(instagram, 'https://instagram.com/design_studio');

      final whatsapp = QrPayloadFormatter.format(
        type: QrContentType.whatsapp,
        values: {'phone': '+1 (555) 019-2834', 'message': 'Hello'},
      );
      expect(whatsapp, contains('https://wa.me/15550192834?text=Hello'));
    });
  });

  group('QrPayloadParser Tests', () {
    test('Parses Wi-Fi payload accurately', () {
      const raw = 'WIFI:T:WPA;S:Home_Network;P:Secret99;H:false;;';
      final parsed = QrPayloadParser.parse(raw);
      expect(parsed.type, QrPayloadType.wifi);
      expect(parsed.ssid, 'Home_Network');
      expect(parsed.password, 'Secret99');
      expect(parsed.securityType, 'WPA');
      expect(parsed.isHiddenNetwork, isFalse);
    });

    test('Parses vCard contact accurately', () {
      const raw = '''BEGIN:VCARD
VERSION:3.0
N:Turing;Alan;;;
FN:Alan Turing
ORG:Bletchley Park
TEL;TYPE=CELL:+441234567
EMAIL:alan@turing.org
END:VCARD''';
      final parsed = QrPayloadParser.parse(raw);
      expect(parsed.type, QrPayloadType.vcard);
      expect(parsed.contactName, 'Alan Turing');
      expect(parsed.phone, '+441234567');
      expect(parsed.email, 'alan@turing.org');
      expect(parsed.organization, 'Bletchley Park');
    });

    test('Parses URL and detects non-https suspicious warning', () {
      final secure = QrPayloadParser.parse('https://paperkit.app');
      expect(secure.type, QrPayloadType.url);
      expect(secure.domain, 'paperkit.app');
      expect(secure.isSuspiciousUrl, isFalse);

      final insecure = QrPayloadParser.parse('http://192.168.1.1/login');
      expect(insecure.type, QrPayloadType.url);
      expect(insecure.isSuspiciousUrl, isTrue);
    });

    test('Parses telephone, email, and location', () {
      final phone = QrPayloadParser.parse('tel:+15551234567');
      expect(phone.type, QrPayloadType.phone);
      expect(phone.phone, '+15551234567');

      final email = QrPayloadParser.parse('mailto:support@paperkit.app?subject=Bug');
      expect(email.type, QrPayloadType.email);
      expect(email.email, 'support@paperkit.app');
      expect(email.subject, 'Bug');

      final geo = QrPayloadParser.parse('geo:37.7749,-122.4194');
      expect(geo.type, QrPayloadType.geo);
      expect(geo.latitude, 37.7749);
      expect(geo.longitude, -122.4194);
    });
  });

  group('QrReadabilityScore & SVG Tests', () {
    test('High contrast black on white evaluated as scannable', () {
      const config = QrDesignConfig(
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
      );
      final score = QrReadabilityScore.evaluate(config);
      expect(score.isScannable, isTrue);
      expect(score.contrastRatio, greaterThan(15.0));
    });

    test('Low contrast triggers warning or unscannable status', () {
      const config = QrDesignConfig(
        foregroundColor: Color(0xFFF3F4F6), // very light gray
        backgroundColor: Colors.white,
      );
      final score = QrReadabilityScore.evaluate(config);
      expect(score.contrastRatio, lessThan(2.5));
      expect(score.isScannable, isFalse);
    });

    test('SVG generator creates valid XML vector document', () {
      const config = QrDesignConfig(
        frameStyle: QrFrameStyle.roundedFrame,
        frameLabel: 'SCAN ME',
      );
      final svg = QrExportService.generateSvg(
        data: 'https://paperkit.app',
        config: config,
      );
      expect(svg.startsWith('<?xml version="1.0"'), isTrue);
      expect(svg.contains('<svg xmlns="http://www.w3.org/2000/svg"'), isTrue);
      expect(svg.contains('<rect'), isTrue);
      expect(svg.contains('SCAN ME'), isTrue);
      expect(svg.endsWith('</svg>\n') || svg.endsWith('</svg>'), isTrue);
    });
  });
}
