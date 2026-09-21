import 'package:flutter_test/flutter_test.dart';
import 'package:maskerv_flutter/core/constants/app_tools.dart';
import 'package:maskerv_flutter/core/models/domain_item.dart';

void main() {
  group('QR Tools Architecture & Registration Tests', () {
    test('QR Generator and QR Scanner are registered with unique IDs', () {
      final gen = ToolRegistry.getById('qr-generator');
      final scan = ToolRegistry.getById('qr-scanner');

      expect(gen, isNotNull);
      expect(scan, isNotNull);
      expect(gen!.id, 'qr-generator');
      expect(scan!.id, 'qr-scanner');
    });

    test('Both QR tools are classified as General Utilities outside Domain 12', () {
      final gen = ToolRegistry.getById('qr-generator')!;
      final scan = ToolRegistry.getById('qr-scanner')!;

      // Must belong to general utilities layer
      expect(gen.domainNumber, isNull);
      expect(gen.domainId, DomainId.utilities);

      expect(scan.domainNumber, isNull);
      expect(scan.domainId, DomainId.utilities);

      // Must belong to general utilities layer
      expect(ToolRegistry.generalUtilities.any((t) => t.id == 'qr-generator'), isTrue);
      expect(ToolRegistry.generalUtilities.any((t) => t.id == 'qr-scanner'), isTrue);
    });

    test('Universal Search discovers both tools via keywords', () {
      final qrResults = ToolRegistry.search('qr');
      expect(qrResults.any((t) => t.id == 'qr-generator'), isTrue);
      expect(qrResults.any((t) => t.id == 'qr-scanner'), isTrue);

      final scannerResults = ToolRegistry.search('scanner');
      expect(scannerResults.any((t) => t.id == 'qr-scanner'), isTrue);
    });

    test('Route resolution resolves canonical tools', () {
      final gen = ToolRegistry.getByRoute('/tools/qr-generator');
      final scan = ToolRegistry.getByRoute('/tools/qr-scanner');

      expect(gen?.id, 'qr-generator');
      expect(scan?.id, 'qr-scanner');
    });

    test('AppTools utility accessors expose QR tools', () {
      expect(AppTools.qrTools.length, 2);
      expect(AppTools.qrTools.map((t) => t.id), containsAll(['qr-generator', 'qr-scanner']));
    });
  });
}
