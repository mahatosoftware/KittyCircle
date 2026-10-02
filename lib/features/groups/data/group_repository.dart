import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../domain/group_model.dart';
import '../../../core/constants/app_constants.dart';

class GroupRepository {
  final FirebaseFirestore? _firestore;

  GroupRepository({this._firestore});

  // Dynamic store for active groups
  final Map<String, GroupModel> _groupStore = {};
  final StreamController<List<GroupModel>> _localStreamController =
      StreamController<List<GroupModel>>.broadcast();

  void _notifyListeners() {
    if (!_localStreamController.isClosed) {
      _localStreamController.add(_groupStore.values.toList());
    }
  }

  List<GroupModel> _getGroupsForUser(String userId) {
    if (userId.isEmpty) {
      return [];
    }
    return _groupStore.values
        .where((g) => g.memberIds.contains(userId) || g.ownerId == userId)
        .toList();
  }

  void clearCache() {
    _groupStore.clear();
    _notifyListeners();
  }

  /// Fetch user's kitty groups dynamically combining local store & Cloud Firestore
  Stream<List<GroupModel>> watchUserGroups(String userId) {
    late StreamController<List<GroupModel>> controller;
    StreamSubscription? firestoreSub;
    StreamSubscription? localSub;

    controller = StreamController<List<GroupModel>>.broadcast(
      onListen: () {
        controller.add(_getGroupsForUser(userId));

        localSub = _localStreamController.stream.listen((_) {
          if (!controller.isClosed) {
            controller.add(_getGroupsForUser(userId));
          }
        });

        if (Firebase.apps.isNotEmpty || _firestore != null) {
          try {
            final db = _firestore ?? FirebaseFirestore.instance;
            firestoreSub = db
                .collection(AppConstants.groupsCollection)
                .snapshots()
                .listen((snap) {
              final remoteGroupIds = snap.docs.map((d) => d.id).toSet();
              _groupStore.removeWhere((id, _) => !remoteGroupIds.contains(id));
              for (final d in snap.docs) {
                final model = GroupModel.fromMap(d.data(), d.id);
                _groupStore[model.groupId] = model;
              }
              _notifyListeners();
            }, onError: (e) {
              debugPrint('Error watching groups collection in Firestore: $e');
              _notifyListeners();
            });
          } catch (e) {
            debugPrint('Error setting up Firestore groups listener: $e');
          }
        }
      },
      onCancel: () {
        localSub?.cancel();
        firestoreSub?.cancel();
      },
    );

    return controller.stream;
  }

  Future<GroupModel?> getGroupById(String groupId) async {
    if (_groupStore.containsKey(groupId)) {
      return _groupStore[groupId];
    }
    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        final doc = await db.collection(AppConstants.groupsCollection).doc(groupId).get();
        if (doc.exists && doc.data() != null) {
          final model = GroupModel.fromMap(doc.data()!, doc.id);
          _groupStore[groupId] = model;
          return model;
        }
      } catch (e) {
        debugPrint('Error getting group by id from Firestore: $e');
      }
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
    _notifyListeners();

    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        await db
            .collection(AppConstants.groupsCollection)
            .doc(groupId)
            .set(newGroup.toMap());
        debugPrint('Firestore: Group $groupId created successfully with attributes: ${newGroup.toMap()}');
      } catch (e, stack) {
        debugPrint('Firestore Error writing group to database: $e\n$stack');
      }
    }

    return newGroup;
  }

  Future<void> updateGroup(GroupModel group) async {
    _groupStore[group.groupId] = group;
    _notifyListeners();

    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        await db
            .collection(AppConstants.groupsCollection)
            .doc(group.groupId)
            .set(group.toMap(), SetOptions(merge: true));
        debugPrint('Firestore: Group ${group.groupId} updated successfully in database.');
      } catch (e, stack) {
        debugPrint('Firestore Error updating group in database: $e\n$stack');
      }
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
    _notifyListeners();

    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        await db.collection(AppConstants.groupsCollection).doc(groupId).delete();
      } catch (e) {
        debugPrint('Error deleting group from Firestore: $e');
      }
    }
  }
}
