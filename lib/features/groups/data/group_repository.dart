import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../domain/group_model.dart';
import '../../../core/constants/app_constants.dart';

class GroupRepository {
  final FirebaseFirestore? _firestore;

  GroupRepository({this._firestore});

  // In-memory initial store populated with realistic demo kitties
  final Map<String, GroupModel> _groupStore = {
    'group_sunshine_1': GroupModel(
      groupId: 'group_sunshine_1',
      name: '🌸 Sunshine Ladies',
      description: 'Monthly kitty gathering for fun, games, food and chatter!',
      contributionAmount: 2000,
      currency: '₹',
      frequency: 'Monthly',
      defaultDurationHours: 3,
      ownerId: 'user_priya_1',
      memberIds: [
        'user_priya_1',
        'user_neha_2',
        'user_kavita_3',
        'user_ritu_4',
        'user_anjali_5',
        'user_simran_6',
        'user_pooja_7',
        'user_meena_8',
        'user_sangeeta_9',
        'user_deepa_10',
        'user_rekha_11',
        'user_sunita_12',
        'user_anita_13',
        'user_monica_14',
      ],
      adminIds: ['user_priya_1', 'user_neha_2'],
    ),
    'group_weekend_2': GroupModel(
      groupId: 'group_weekend_2',
      name: '💐 Weekend Queens',
      description: 'Weekend high-tea & themes kitty party group!',
      contributionAmount: 1500,
      currency: '₹',
      frequency: 'Monthly',
      defaultDurationHours: 3,
      ownerId: 'user_neha_2',
      memberIds: [
        'user_priya_1',
        'user_neha_2',
        'user_kavita_3',
        'user_ritu_4',
        'user_anjali_5',
        'user_simran_6',
        'user_pooja_7',
        'user_meena_8',
        'user_sangeeta_9',
        'user_deepa_10',
      ],
      adminIds: ['user_neha_2'],
    ),
  };

  /// Fetch user's kitty groups
  Stream<List<GroupModel>> watchUserGroups(String userId) async* {
    yield _groupStore.values.where((g) => g.memberIds.contains(userId)).toList();

    if (Firebase.apps.isEmpty && _firestore == null) return;

    try {
      final db = _firestore ?? FirebaseFirestore.instance;
      final snapStream = db
          .collection(AppConstants.groupsCollection)
          .where('memberIds', arrayContains: userId)
          .snapshots();

      await for (final snap in snapStream) {
        final groups = snap.docs.map((d) {
          final model = GroupModel.fromMap(d.data(), d.id);
          _groupStore[model.groupId] = model;
          return model;
        }).toList();
        yield groups.isNotEmpty
            ? groups
            : _groupStore.values.where((g) => g.memberIds.contains(userId)).toList();
      }
    } catch (_) {
      yield _groupStore.values.where((g) => g.memberIds.contains(userId)).toList();
    }
  }

  Future<GroupModel?> getGroupById(String groupId) async {
    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        final doc = await db.collection(AppConstants.groupsCollection).doc(groupId).get();
        if (doc.exists && doc.data() != null) {
          final model = GroupModel.fromMap(doc.data()!, doc.id);
          _groupStore[groupId] = model;
          return model;
        }
      } catch (_) {}
    }
    return _groupStore[groupId];
  }

  Future<GroupModel> createGroup({
    required String name,
    required String description,
    required double contributionAmount,
    required String ownerId,
    String frequency = 'Monthly',
    String currency = '₹',
    int defaultDurationHours = 3,
  }) async {
    final groupId = 'group_${DateTime.now().millisecondsSinceEpoch}';
    final newGroup = GroupModel(
      groupId: groupId,
      name: name,
      description: description,
      contributionAmount: contributionAmount,
      currency: currency,
      frequency: frequency,
      defaultDurationHours: defaultDurationHours,
      ownerId: ownerId,
      memberIds: [ownerId],
      adminIds: [ownerId],
    );

    _groupStore[groupId] = newGroup;

    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        await db
            .collection(AppConstants.groupsCollection)
            .doc(groupId)
            .set(newGroup.toMap());
      } catch (_) {}
    }

    return newGroup;
  }

  Future<void> updateGroup(GroupModel group) async {
    _groupStore[group.groupId] = group;
    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        await db
            .collection(AppConstants.groupsCollection)
            .doc(group.groupId)
            .update(group.toMap());
      } catch (_) {}
    }
  }

  Future<void> addMemberToGroup(String groupId, String userId) async {
    final group = await getGroupById(groupId);
    if (group != null && !group.memberIds.contains(userId)) {
      final updatedMembers = List<String>.from(group.memberIds)..add(userId);
      final updatedGroup = group.copyWith(memberIds: updatedMembers);
      await updateGroup(updatedGroup);
    }
  }

  Future<void> removeMemberFromGroup(String groupId, String userId) async {
    final group = await getGroupById(groupId);
    if (group != null && group.memberIds.contains(userId)) {
      final updatedMembers = List<String>.from(group.memberIds)..remove(userId);
      final updatedAdmins = List<String>.from(group.adminIds)..remove(userId);
      final updatedGroup = group.copyWith(memberIds: updatedMembers, adminIds: updatedAdmins);
      await updateGroup(updatedGroup);
    }
  }

  Future<void> setAdminRole(String groupId, String userId, bool isAdmin) async {
    final group = await getGroupById(groupId);
    if (group != null) {
      final admins = List<String>.from(group.adminIds);
      if (isAdmin && !admins.contains(userId)) {
        admins.add(userId);
      } else if (!isAdmin) {
        admins.remove(userId);
      }
      final updatedGroup = group.copyWith(adminIds: admins);
      await updateGroup(updatedGroup);
    }
  }

  Future<void> deleteGroup(String groupId) async {
    _groupStore.remove(groupId);
    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        await db.collection(AppConstants.groupsCollection).doc(groupId).delete();
      } catch (_) {}
    }
  }
}
