import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../domain/member_model.dart';
import '../../../core/constants/app_constants.dart';

class MemberRepository {
  final FirebaseFirestore? _firestore;

  final Map<String, List<MemberModel>> _memberStore = {};

  MemberRepository({this._firestore});

  Stream<List<MemberModel>> watchGroupMembers(String groupId) async* {
    yield _memberStore[groupId] ?? [];

    if (Firebase.apps.isEmpty && _firestore == null) return;

    try {
      final db = _firestore ?? FirebaseFirestore.instance;
      final stream = db
          .collection(AppConstants.groupsCollection)
          .doc(groupId)
          .collection(AppConstants.membersCollection)
          .snapshots();

      await for (final snap in stream) {
        final members = snap.docs.map((d) => MemberModel.fromMap(d.data(), d.id)).toList();
        _memberStore[groupId] = members;
        yield members;
      }
    } catch (_) {
      yield _memberStore[groupId] ?? [];
    }
  }

  Future<void> addMember({
    required String groupId,
    required String userId,
    required String displayName,
    String? phoneNumber,
    MemberRole role = MemberRole.member,
    DateTime? birthday,
    DateTime? anniversary,
  }) async {
    final member = MemberModel(
      userId: userId,
      groupId: groupId,
      displayName: displayName,
      phoneNumber: phoneNumber,
      role: role,
      birthday: birthday,
      anniversary: anniversary,
    );

    final list = _memberStore.putIfAbsent(groupId, () => []);
    final existingIdx = list.indexWhere((m) => m.userId == userId);
    if (existingIdx != -1) {
      list[existingIdx] = member;
    } else {
      list.add(member);
    }

    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        await db
            .collection(AppConstants.groupsCollection)
            .doc(groupId)
            .collection(AppConstants.membersCollection)
            .doc(userId)
            .set(member.toMap());
      } catch (_) {}
    }
  }

  Future<void> removeMember(String groupId, String userId) async {
    _memberStore[groupId]?.removeWhere((m) => m.userId == userId);

    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        await db
            .collection(AppConstants.groupsCollection)
            .doc(groupId)
            .collection(AppConstants.membersCollection)
            .doc(userId)
            .delete();
      } catch (_) {}
    }
  }

  Future<void> updateRole(String groupId, String userId, MemberRole newRole) async {
    final list = _memberStore[groupId];
    if (list != null) {
      final idx = list.indexWhere((m) => m.userId == userId);
      if (idx != -1) {
        final existing = list[idx];
        final updated = existing.copyWith(role: newRole);
        list[idx] = updated;

        if (Firebase.apps.isNotEmpty || _firestore != null) {
          try {
            final db = _firestore ?? FirebaseFirestore.instance;
            await db
                .collection(AppConstants.groupsCollection)
                .doc(groupId)
                .collection(AppConstants.membersCollection)
                .doc(userId)
                .update({'role': updated.roleString});
          } catch (_) {}
        }
      }
    }
  }

  Future<void> updateMemberDetails({
    required String groupId,
    required String userId,
    String? displayName,
    String? phoneNumber,
    MemberRole? role,
    DateTime? birthday,
    DateTime? anniversary,
  }) async {
    final list = _memberStore[groupId];
    if (list != null) {
      final idx = list.indexWhere((m) => m.userId == userId);
      if (idx != -1) {
        final existing = list[idx];
        final updated = existing.copyWith(
          displayName: displayName,
          phoneNumber: phoneNumber,
          role: role,
          birthday: birthday,
          anniversary: anniversary,
        );
        list[idx] = updated;

        if (Firebase.apps.isNotEmpty || _firestore != null) {
          try {
            final db = _firestore ?? FirebaseFirestore.instance;
            await db
                .collection(AppConstants.groupsCollection)
                .doc(groupId)
                .collection(AppConstants.membersCollection)
                .doc(userId)
                .set(updated.toMap(), SetOptions(merge: true));
          } catch (_) {}
        }
      }
    }
  }
}
