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

        // Auto-sync any members present in group.memberIds but missing in members subcollection
        try {
          final groupDoc = await db.collection(AppConstants.groupsCollection).doc(groupId).get();
          if (groupDoc.exists && groupDoc.data() != null) {
            final data = groupDoc.data()!;
            final memberIds = (data['memberIds'] as List?)?.map((e) => e.toString()).toList() ?? [];
            final existingUserIds = members.map((m) => m.userId).toSet();

            for (final uid in memberIds) {
              if (!existingUserIds.contains(uid)) {
                final isOwner = data['ownerId'] == uid;
                String resolvedName = '';
                if (data['createdBy'] == uid && (data['createdByName'] as String?)?.isNotEmpty == true) {
                  resolvedName = data['createdByName'];
                }
                if (resolvedName.isEmpty) {
                  try {
                    final uSnap = await db.collection(AppConstants.usersCollection).doc(uid).get();
                    if (uSnap.exists && uSnap.data() != null) {
                      final uData = uSnap.data()!;
                      resolvedName = uData['displayName'] ?? uData['userName'] ?? uData['name'] ?? uData['email']?.split('@').first ?? '';
                    }
                  } catch (_) {}
                }
                if (resolvedName.isEmpty) {
                  resolvedName = 'Kitty Member';
                }

                final synth = MemberModel(
                  userId: uid,
                  groupId: groupId,
                  displayName: resolvedName,
                  role: isOwner ? MemberRole.owner : MemberRole.member,
                );
                members.add(synth);

                // Auto-backfill subcollection in Cloud Firestore
                db.collection(AppConstants.groupsCollection)
                  .doc(groupId)
                  .collection(AppConstants.membersCollection)
                  .doc(uid)
                  .set(synth.toMap(), SetOptions(merge: true));
              }
            }
          }
        } catch (_) {}

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
