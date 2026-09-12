import 'package:flutter_test/flutter_test.dart';
import 'package:maskerv_flutter/core/models/dual_pane_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Domain 11: Dual-Pane Workspace & Syllabus Tracker Tests', () {
    test('SyllabusCourse calculates 0.0 progress for empty topics', () {
      final course = SyllabusCourse(
        id: 'c_empty',
        courseName: 'Empty Course',
        courseCode: 'CS000',
        topics: [],
      );

      expect(course.progressPercentage, equals(0.0));
    });

    test('SyllabusCourse calculates exact topic completion ratio', () {
      final topics = [
        SyllabusTopic(id: 't1', title: 'Topic 1', isCompleted: true),
        SyllabusTopic(id: 't2', title: 'Topic 2', isCompleted: false),
        SyllabusTopic(id: 't3', title: 'Topic 3', isCompleted: true),
        SyllabusTopic(id: 't4', title: 'Topic 4', isCompleted: true),
      ];

      final course = SyllabusCourse(
        id: 'c_1',
        courseName: 'Data Structures',
        courseCode: 'CS201',
        topics: topics,
      );

      expect(course.progressPercentage, equals(0.75));
    });

    test('Sync scroll proportional ratio calculation logic', () {
      const maxA = 1000.0;
      const maxB = 500.0;
      const currentOffsetA = 500.0;

      final ratioA = (currentOffsetA / maxA).clamp(0.0, 1.0);
      final targetB = (ratioA * maxB).clamp(0.0, maxB);

      expect(ratioA, equals(0.5));
      expect(targetB, equals(250.0));
    });
  });
}
