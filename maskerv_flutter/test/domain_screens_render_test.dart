import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:maskerv_flutter/core/providers/files_provider.dart';
import 'package:maskerv_flutter/core/providers/history_provider.dart';

import 'package:maskerv_flutter/core/constants/tool_registry.dart';
import 'package:maskerv_flutter/core/models/domain_item.dart';
import 'package:maskerv_flutter/features/tools/category_hub_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableWidget(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FilesProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: MaterialApp(home: child),
    );
  }

  group('Domain Separation & Domain Hub Tests', () {
    testWidgets('Renders CategoryHubScreen for all 15 domains without error', (
      tester,
    ) async {
      for (int i = 1; i <= 15; i++) {
        await tester.pumpWidget(
          buildTestableWidget(CategoryHubScreen(categoryId: i.toString())),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Domain $i'), findsWidgets);
      }
    });

    testWidgets('DomainRegistry resolves all 15 domains properly', (
      tester,
    ) async {
      expect(DomainRegistry.domains.length, equals(15));
      for (int i = 1; i <= 15; i++) {
        final domain = DomainRegistry.getByNumber(i);
        expect(domain, isNotNull);
        expect(domain!.number, equals(i));
        final tools = ToolRegistry.getByDomainNumber(i);
        expect(
          tools.isNotEmpty,
          isTrue,
          reason: 'Domain $i has no primary tools registered!',
        );
      }
    });
  });
}
