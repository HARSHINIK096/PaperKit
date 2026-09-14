import '../../core/models/dual_pane_model.dart';
import '../../core/services/storage_service.dart';

class WorkspaceService {
  final StorageService _storage = StorageService();

  // Page-Anchored Notes Management
  Future<List<PageAnchorNote>> loadNotesForDocument(String documentPath) async {
    final rawList = await _storage.getPageNotes();
    return rawList
        .map((m) => PageAnchorNote.fromJson(m))
        .where((n) => n.documentPath == documentPath)
        .toList();
  }

  Future<void> saveNote(PageAnchorNote note) async {
    final rawList = await _storage.getPageNotes();
    final notes = rawList.map((m) => PageAnchorNote.fromJson(m)).toList();
    notes.removeWhere((n) => n.id == note.id);
    notes.insert(0, note);
    await _storage.savePageNotes(notes.map((n) => n.toJson()).toList());
  }

  Future<void> deleteNote(String noteId) async {
    final rawList = await _storage.getPageNotes();
    final notes = rawList.map((m) => PageAnchorNote.fromJson(m)).toList();
    notes.removeWhere((n) => n.id == noteId);
    await _storage.savePageNotes(notes.map((n) => n.toJson()).toList());
  }

  // Syllabus Tracker Management
  Future<List<SyllabusCourse>> loadSyllabusCourses() async {
    final rawList = await _storage.getSyllabusCourses();
    return rawList.map((m) => SyllabusCourse.fromJson(m)).toList();
  }

  Future<void> saveSyllabusCourse(SyllabusCourse course) async {
    final courses = await loadSyllabusCourses();
    courses.removeWhere((c) => c.id == course.id);
    courses.insert(0, course);
    await _storage.saveSyllabusCourses(courses.map((c) => c.toJson()).toList());
  }

  Future<void> deleteSyllabusCourse(String courseId) async {
    final courses = await loadSyllabusCourses();
    courses.removeWhere((c) => c.id == courseId);
    await _storage.saveSyllabusCourses(courses.map((c) => c.toJson()).toList());
  }

  Future<void> toggleTopicCompletion(String courseId, String topicId) async {
    final courses = await loadSyllabusCourses();
    final courseIndex = courses.indexWhere((c) => c.id == courseId);
    if (courseIndex != -1) {
      final course = courses[courseIndex];
      final topicIndex = course.topics.indexWhere((t) => t.id == topicId);
      if (topicIndex != -1) {
        course.topics[topicIndex].isCompleted = !course.topics[topicIndex].isCompleted;
        await _storage.saveSyllabusCourses(courses.map((c) => c.toJson()).toList());
      }
    }
  }
}
