import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../domain/memory_model.dart';
import '../../../core/constants/app_constants.dart';

class MemoryRepository {
  final FirebaseFirestore? _firestore;

  final Map<String, List<MemoryModel>> _memoryStore = {};

  MemoryRepository({this._firestore});

  Stream<List<MemoryModel>> watchGroupMemories(String groupId) async* {
    yield _memoryStore[groupId] ?? [];

    if (Firebase.apps.isEmpty && _firestore == null) return;

    try {
      final db = _firestore ?? FirebaseFirestore.instance;
      final snapStream = db
          .collection(AppConstants.groupsCollection)
          .doc(groupId)
          .collection(AppConstants.memoriesCollection)
          .orderBy('createdAt', descending: true)
          .snapshots();

      await for (final snap in snapStream) {
        final list = snap.docs.map((d) => MemoryModel.fromMap(d.data(), d.id)).toList();
        _memoryStore[groupId] = list;
        yield list;
      }
    } catch (_) {
      yield _memoryStore[groupId] ?? [];
    }
  }

  Future<MemoryModel> addMemory(MemoryModel memory) async {
    _memoryStore.putIfAbsent(memory.groupId, () => []).insert(0, memory);

    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        await db
            .collection(AppConstants.groupsCollection)
            .doc(memory.groupId)
            .collection(AppConstants.memoriesCollection)
            .doc(memory.memoryId)
            .set(memory.toMap());
      } catch (_) {}
    }

    return memory;
  }

  Future<void> deleteMemory(String groupId, String memoryId) async {
    _memoryStore[groupId]?.removeWhere((m) => m.memoryId == memoryId);

    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        await db
            .collection(AppConstants.groupsCollection)
            .doc(groupId)
            .collection(AppConstants.memoriesCollection)
            .doc(memoryId)
            .delete();
      } catch (_) {}
    }
  }
}
