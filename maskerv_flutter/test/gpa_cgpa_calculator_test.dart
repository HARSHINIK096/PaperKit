import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:maskerv_flutter/core/providers/files_provider.dart';
import 'package:maskerv_flutter/core/providers/history_provider.dart';
import 'package:maskerv_flutter/features/domain_expansions/expanded_domain_screens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestWidget(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FilesProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: MaterialApp(home: child),
    );
  }

  group('Domain 11: GPA & CGPA Calculator Classification Tests', () {
    testWidgets('Renders GpaCalculatorScreen with Term GPA and CGPA cards', (tester) async {
      await tester.pumpWidget(buildTestWidget(const GpaCalculatorScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('GRADING SYSTEM CLASSIFICATION'), findsOneWidget);
      expect(find.textContaining('TERM GPA'), findsOneWidget);
      expect(find.textContaining('CUMULATIVE CGPA'), findsOneWidget);
      expect(find.textContaining('Computer Science 101'), findsOneWidget);
    });

    testWidgets('Switches Grading Classification to 10.0 Scale', (tester) async {
      await tester.pumpWidget(buildTestWidget(const GpaCalculatorScreen()));
      await tester.pumpAndSettle();

      // Open Dropdown
      final dropdown = find.byType(DropdownButtonFormField<GpaClassification>);
      expect(dropdown, findsOneWidget);

      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      final scale10Option = find.text('10.0 Scale (SGPA / CGPA Point)').last;
      await tester.tap(scale10Option);
      await tester.pumpAndSettle();

      expect(find.textContaining('Out of 10.0'), findsOneWidget);
    });
  });
}
