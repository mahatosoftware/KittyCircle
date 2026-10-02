import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../domain/memory_model.dart';
import '../../../core/constants/app_constants.dart';

class MemoryRepository {
  final FirebaseFirestore? _firestore;

  final Map<String, List<MemoryModel>> _memoryStore = {
    'group_sunshine_1': [
      MemoryModel(
        memoryId: 'm1',
        groupId: 'group_sunshine_1',
        eventId: 'event_sep_18',
        eventTitle: 'September Floral Kitty',
        imageUrl: 'https://picsum.photos/seed/kitty1/600/600',
        caption: 'Group selfie with the beautiful floral theme backdrop! 🌸💐',
        uploadedByUserId: 'user_priya_1',
        uploadedByUserName: 'Priya Sharma',
      ),
      MemoryModel(
        memoryId: 'm2',
        groupId: 'group_sunshine_1',
        eventId: 'event_sep_18',
        eventTitle: 'September Floral Kitty',
        imageUrl: 'https://picsum.photos/seed/kitty2/600/600',
        caption: 'Congratulations to our September Kitty Winner Neha! 🏆🥇',
        uploadedByUserId: 'user_neha_2',
        uploadedByUserName: 'Neha Gupta',
      ),
      MemoryModel(
        memoryId: 'm3',
        groupId: 'group_sunshine_1',
        eventId: 'event_sep_18',
        eventTitle: 'September Floral Kitty',
        imageUrl: 'https://picsum.photos/seed/kitty3/600/600',
        caption: 'Delicious food spread and high-tea snacks! 🍰☕',
        uploadedByUserId: 'user_kavita_3',
        uploadedByUserName: 'Kavita Verma',
      ),
    ]
  };

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
        if (list.isNotEmpty) {
          _memoryStore[groupId] = list;
          yield list;
        } else {
          yield _memoryStore[groupId] ?? [];
        }
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
