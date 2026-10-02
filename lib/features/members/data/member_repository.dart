import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../domain/member_model.dart';
import '../../../core/constants/app_constants.dart';

class MemberRepository {
  final FirebaseFirestore? _firestore;

  final Map<String, List<MemberModel>> _memberStore = {
    'group_sunshine_1': [
      MemberModel(userId: 'user_priya_1', groupId: 'group_sunshine_1', displayName: 'Priya Sharma', role: MemberRole.owner, phoneNumber: '+919876543210'),
      MemberModel(userId: 'user_neha_2', groupId: 'group_sunshine_1', displayName: 'Neha Gupta', role: MemberRole.admin, phoneNumber: '+919876543211'),
      MemberModel(userId: 'user_kavita_3', groupId: 'group_sunshine_1', displayName: 'Kavita Verma', role: MemberRole.member, phoneNumber: '+919876543212'),
      MemberModel(userId: 'user_ritu_4', groupId: 'group_sunshine_1', displayName: 'Ritu Kapoor', role: MemberRole.member, phoneNumber: '+919876543213'),
      MemberModel(userId: 'user_anjali_5', groupId: 'group_sunshine_1', displayName: 'Anjali Singh', role: MemberRole.member, phoneNumber: '+919876543214'),
      MemberModel(userId: 'user_simran_6', groupId: 'group_sunshine_1', displayName: 'Simran Kaur', role: MemberRole.member),
      MemberModel(userId: 'user_pooja_7', groupId: 'group_sunshine_1', displayName: 'Pooja Reddy', role: MemberRole.member),
      MemberModel(userId: 'user_meena_8', groupId: 'group_sunshine_1', displayName: 'Meena Joshi', role: MemberRole.member),
      MemberModel(userId: 'user_sangeeta_9', groupId: 'group_sunshine_1', displayName: 'Sangeeta Roy', role: MemberRole.member),
      MemberModel(userId: 'user_deepa_10', groupId: 'group_sunshine_1', displayName: 'Deepa Agarwal', role: MemberRole.member),
      MemberModel(userId: 'user_rekha_11', groupId: 'group_sunshine_1', displayName: 'Rekha Iyer', role: MemberRole.member),
      MemberModel(userId: 'user_sunita_12', groupId: 'group_sunshine_1', displayName: 'Sunita Jain', role: MemberRole.member),
      MemberModel(userId: 'user_anita_13', groupId: 'group_sunshine_1', displayName: 'Anita Malhotra', role: MemberRole.member),
      MemberModel(userId: 'user_monica_14', groupId: 'group_sunshine_1', displayName: 'Monica Saxena', role: MemberRole.member),
    ],
    'group_weekend_2': [
      MemberModel(userId: 'user_neha_2', groupId: 'group_weekend_2', displayName: 'Neha Gupta', role: MemberRole.owner),
      MemberModel(userId: 'user_priya_1', groupId: 'group_weekend_2', displayName: 'Priya Sharma', role: MemberRole.member),
      MemberModel(userId: 'user_kavita_3', groupId: 'group_weekend_2', displayName: 'Kavita Verma', role: MemberRole.member),
      MemberModel(userId: 'user_ritu_4', groupId: 'group_weekend_2', displayName: 'Ritu Kapoor', role: MemberRole.member),
      MemberModel(userId: 'user_anjali_5', groupId: 'group_weekend_2', displayName: 'Anjali Singh', role: MemberRole.member),
    ],
  };

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
        if (members.isNotEmpty) {
          _memberStore[groupId] = members;
          yield members;
        } else {
          yield _memberStore[groupId] ?? [];
        }
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
  }) async {
    final member = MemberModel(
      userId: userId,
      groupId: groupId,
      displayName: displayName,
      phoneNumber: phoneNumber,
      role: role,
    );

    _memberStore.putIfAbsent(groupId, () => []).add(member);

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
        final updated = MemberModel(
          userId: existing.userId,
          groupId: existing.groupId,
          displayName: existing.displayName,
          photoUrl: existing.photoUrl,
          phoneNumber: existing.phoneNumber,
          role: newRole,
          joinedAt: existing.joinedAt,
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
                .update({'role': updated.roleString});
          } catch (_) {}
        }
      }
    }
  }
}
