import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../domain/group_model.dart';
import '../domain/join_request_model.dart';
import '../domain/group_invite_model.dart';
import '../../members/domain/member_model.dart';
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
            final Query<Map<String, dynamic>> query = userId.isNotEmpty
                ? db.collection(AppConstants.groupsCollection).where('memberIds', arrayContains: userId)
                : db.collection(AppConstants.groupsCollection);

            firestoreSub = query.snapshots().listen((snap) {
              final remoteGroupIds = snap.docs.map((d) => d.id).toSet();
              _groupStore.removeWhere((id, g) => (g.memberIds.contains(userId) || g.ownerId == userId) && !remoteGroupIds.contains(id));
              for (final d in snap.docs) {
                final data = d.data();
                final model = GroupModel.fromMap(data, d.id);
                _groupStore[model.groupId] = model;
                if (!data.containsKey('inviteCode') && !data.containsKey('invite_code')) {
                  db.collection(AppConstants.groupsCollection)
                    .doc(d.id)
                    .set({'inviteCode': model.inviteCode}, SetOptions(merge: true));
                }
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
          final data = doc.data()!;
          final model = GroupModel.fromMap(data, doc.id);
          _groupStore[groupId] = model;
          if (!data.containsKey('inviteCode') && !data.containsKey('invite_code')) {
            await db.collection(AppConstants.groupsCollection)
              .doc(doc.id)
              .set({'inviteCode': model.inviteCode}, SetOptions(merge: true));
          }
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
    String joiningPolicy = 'approval',
    bool approvalRequired = true,
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
      joiningPolicy: joiningPolicy,
      approvalRequired: approvalRequired,
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

  Future<void> addMemberToGroup(String groupId, String userId, {String? userName}) async {
    final group = await getGroupById(groupId);
    if (group != null) {
      if (!group.memberIds.contains(userId)) {
        final updatedMembers = List<String>.from(group.memberIds)..add(userId);
        final updatedGroup = group.copyWith(memberIds: updatedMembers);
        await updateGroup(updatedGroup);
      }

      if (Firebase.apps.isNotEmpty || _firestore != null) {
        try {
          final db = _firestore ?? FirebaseFirestore.instance;
          String nameToUse = (userName != null && userName.trim().isNotEmpty) ? userName.trim() : '';
          if (nameToUse.isEmpty) {
            try {
              final userSnap = await db.collection(AppConstants.usersCollection).doc(userId).get();
              if (userSnap.exists && userSnap.data() != null) {
                final uData = userSnap.data()!;
                nameToUse = uData['displayName'] ?? uData['userName'] ?? uData['name'] ?? uData['email']?.split('@').first ?? '';
              }
            } catch (_) {}
          }
          if (nameToUse.isEmpty) {
            try {
              final currentUser = FirebaseAuth.instance.currentUser;
              if (currentUser != null && currentUser.uid == userId) {
                nameToUse = currentUser.displayName ?? currentUser.email?.split('@').first ?? '';
              }
            } catch (_) {}
          }
          if (nameToUse.isEmpty) {
            nameToUse = 'Kitty Member';
          }
          final isOwner = group.ownerId == userId;
          final memberDoc = MemberModel(
            userId: userId,
            groupId: groupId,
            displayName: nameToUse,
            role: isOwner ? MemberRole.owner : MemberRole.member,
          );
          await db
              .collection(AppConstants.groupsCollection)
              .doc(groupId)
              .collection(AppConstants.membersCollection)
              .doc(userId)
              .set(memberDoc.toMap(), SetOptions(merge: true));
        } catch (e) {
          debugPrint('Error writing member to subcollection: $e');
        }
      }
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

  /// Find a group by its 6-character invite code or group identifier with full fallback & backfill
  Future<GroupModel?> getGroupByInviteCode(String inviteCode) async {
    final rawClean = inviteCode.trim().toUpperCase();
    final noHyphen = rawClean.replaceAll('-', '');
    if (noHyphen.isEmpty) return null;

    // 1. Local Memory Cache Check
    final localMatch = _groupStore.values.where((g) {
      final code = g.inviteCode.toUpperCase();
      final codeNoHyphen = code.replaceAll('-', '');
      return code == rawClean || codeNoHyphen == noHyphen || g.groupId.toUpperCase() == rawClean;
    }).firstOrNull;
    if (localMatch != null) return localMatch;

    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;

        // 2. Query Firestore by exact uppercase inviteCode
        var snap = await db
            .collection(AppConstants.groupsCollection)
            .where('inviteCode', isEqualTo: rawClean)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          final model = GroupModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
          _groupStore[model.groupId] = model;
          return model;
        }

        // 3. Query Firestore by clean inviteCode without hyphens
        if (noHyphen != rawClean) {
          snap = await db
              .collection(AppConstants.groupsCollection)
              .where('inviteCode', isEqualTo: noHyphen)
              .limit(1)
              .get();
          if (snap.docs.isNotEmpty) {
            final model = GroupModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
            _groupStore[model.groupId] = model;
            return model;
          }
        }

        // 4. Query Firestore by lowercase inviteCode
        snap = await db
            .collection(AppConstants.groupsCollection)
            .where('inviteCode', isEqualTo: rawClean.toLowerCase())
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          final model = GroupModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
          _groupStore[model.groupId] = model;
          return model;
        }

        // 5. Scan all groups in Firestore to support legacy docs missing inviteCode field
        final allDocs = await db.collection(AppConstants.groupsCollection).get();
        for (final doc in allDocs.docs) {
          final data = doc.data();
          final model = GroupModel.fromMap(data, doc.id);
          _groupStore[model.groupId] = model;
          final codeUpper = model.inviteCode.toUpperCase();
          final codeClean = codeUpper.replaceAll('-', '');
          if (doc.id.toUpperCase() == rawClean ||
              codeUpper == rawClean ||
              codeClean == noHyphen) {
            // Backfill inviteCode in Firestore if missing
            if (!data.containsKey('inviteCode')) {
              await db
                  .collection(AppConstants.groupsCollection)
                  .doc(doc.id)
                  .set({'inviteCode': model.inviteCode}, SetOptions(merge: true));
            }
            return model;
          }
        }
      } catch (e) {
        debugPrint('Error fetching group by invite code from Firestore: $e');
        if (e is FirebaseException && e.code == 'permission-denied') {
          _lastLookupError = 'Firestore Security Rules are blocking group searches (permission-denied). Please publish the updated rules in your Firebase Console.';
        }
      }
    }
    return null;
  }

  String? _lastLookupError;

  /// Request to join a group using invite code or group ID
  Future<JoinResult> requestToJoinGroup({
    required String identifier,
    required String userId,
    required String userName,
    String? photoUrl,
  }) async {
    final cleanId = identifier.trim();
    if (cleanId.isEmpty) {
      return JoinResult(
        status: JoinResultStatus.notFound,
        message: 'Please enter a valid Group Code or link.',
      );
    }

    GroupModel? group;
    group = await getGroupByInviteCode(cleanId);
    group ??= await getGroupByInviteCode(cleanId.replaceAll('-', ''));
    group ??= await getGroupById(cleanId);

    if (group == null) {
      final msg = _lastLookupError ?? 'No Kitty Circle group found with code "$cleanId".';
      _lastLookupError = null;
      return JoinResult(
        status: JoinResultStatus.notFound,
        message: msg,
      );
    }

    final info = GroupModelInfo(
      groupId: group.groupId,
      name: group.name,
      memberCount: group.memberIds.length,
    );

    if (group.memberIds.contains(userId)) {
      return JoinResult(
        status: JoinResultStatus.alreadyMember,
        group: info,
        message: 'You are already a member of ${group.name}!',
      );
    }

    if (!group.inviteEnabled || group.joiningPolicy == 'invite_only') {
      return JoinResult(
        status: JoinResultStatus.disabled,
        group: info,
        message: 'Invitations are currently disabled for ${group.name}.',
      );
    }

    // Direct join if policy is anyone or approval is disabled
    if (group.joiningPolicy == 'anyone' || !group.approvalRequired) {
      await addMemberToGroup(group.groupId, userId, userName: userName);
      return JoinResult(
        status: JoinResultStatus.joined,
        group: info,
        message: 'Welcome! You have successfully joined ${group.name}. 🎉',
      );
    }

    // Otherwise, create join request for host approval
    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        final req = JoinRequestModel(
          requestId: userId,
          groupId: group.groupId,
          userId: userId,
          userName: userName,
          photoUrl: photoUrl,
          status: JoinRequestStatus.pending,
        );
        await db
            .collection(AppConstants.groupsCollection)
            .doc(group.groupId)
            .collection('join_requests')
            .doc(userId)
            .set(req.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error creating join request in Firestore: $e');
      }
    }

    return JoinResult(
      status: JoinResultStatus.pendingApproval,
      group: info,
      message: 'Join request submitted! Waiting for host approval. ⏳',
    );
  }

  /// Watch pending join requests for a group
  Stream<List<JoinRequestModel>> watchGroupJoinRequests(String groupId) {
    if (groupId.isEmpty) return Stream.value([]);
    final db = _firestore ?? FirebaseFirestore.instance;
    return db
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection('join_requests')
        .snapshots()
        .map((snap) {
      return snap.docs
          .map((d) => JoinRequestModel.fromMap(d.data(), d.id))
          .where((r) => r.status == JoinRequestStatus.pending)
          .toList();
    }).handleError((e) {
      debugPrint('Error watching join requests for group $groupId: $e');
      return <JoinRequestModel>[];
    });
  }

  /// Host accepts join request
  Future<void> acceptJoinRequest(String groupId, String userId, String userName) async {
    await addMemberToGroup(groupId, userId, userName: userName);
    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        await db
            .collection(AppConstants.groupsCollection)
            .doc(groupId)
            .collection('join_requests')
            .doc(userId)
            .update({'status': 'approved'});
      } catch (e) {
        debugPrint('Error approving join request in Firestore: $e');
      }
    }
  }

  /// Host rejects join request
  Future<void> rejectJoinRequest(String groupId, String userId) async {
    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        await db
            .collection(AppConstants.groupsCollection)
            .doc(groupId)
            .collection('join_requests')
            .doc(userId)
            .update({'status': 'rejected'});
      } catch (e) {
        debugPrint('Error rejecting join request in Firestore: $e');
      }
    }
  }

  /// Generate a new secure, unguessable one-time invitation token
  Future<GroupInviteModel> generateOneTimeInvite({
    required String groupId,
    required String userId,
    required String userName,
    Duration validDuration = const Duration(days: 7),
  }) async {
    final token = GroupInviteModel.generateToken();
    final inviteId = 'invite_${DateTime.now().millisecondsSinceEpoch}';
    final invite = GroupInviteModel(
      inviteId: inviteId,
      groupId: groupId,
      token: token,
      status: InviteStatus.active,
      createdBy: userId,
      createdByName: userName,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(validDuration),
    );

    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        await db
            .collection(AppConstants.groupsCollection)
            .doc(groupId)
            .collection('invites')
            .doc(inviteId)
            .set(invite.toMap());
      } catch (e) {
        debugPrint('Error writing one-time invite to Firestore: $e');
      }
    }
    return invite;
  }

  /// Watch invitations for a group
  Stream<List<GroupInviteModel>> watchGroupInvites(String groupId) {
    if (groupId.isEmpty) return Stream.value([]);
    final db = _firestore ?? FirebaseFirestore.instance;
    return db
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection('invites')
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => GroupInviteModel.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }).handleError((e) {
      debugPrint('Error watching invites for group $groupId: $e');
      return <GroupInviteModel>[];
    });
  }

  /// Revoke an active invitation immediately
  Future<void> revokeInvite({required String groupId, required String inviteId}) async {
    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        await db
            .collection(AppConstants.groupsCollection)
            .doc(groupId)
            .collection('invites')
            .doc(inviteId)
            .update({'status': 'revoked'});
      } catch (e) {
        debugPrint('Error revoking invite in Firestore: $e');
      }
    }
  }

  /// Redeem a one-time invitation token or code
  Future<JoinResult> redeemOneTimeInvite({
    required String rawInput,
    required String userId,
    required String userName,
    String? photoUrl,
  }) async {
    final extracted = _extractCodeFromRawInput(rawInput);
    final cleanInput = extracted.trim().toUpperCase();
    final cleanToken = cleanInput.replaceAll('-', '');

    if (cleanToken.isEmpty) {
      return JoinResult(
        status: JoinResultStatus.notFound,
        message: 'Please enter a valid invitation code or link.',
      );
    }

    // Try finding one-time invite across Firestore group invites subcollections
    if (Firebase.apps.isNotEmpty || _firestore != null) {
      final db = _firestore ?? FirebaseFirestore.instance;
      try {
        var snap = await db
            .collectionGroup('invites')
            .where('tokenClean', isEqualTo: cleanToken)
            .limit(1)
            .get();

        if (snap.docs.isEmpty) {
          snap = await db
              .collectionGroup('invites')
              .where('token', isEqualTo: cleanInput)
              .limit(1)
              .get();
        }

        if (snap.docs.isNotEmpty) {
          final doc = snap.docs.first;
          final invite = GroupInviteModel.fromMap(doc.data(), doc.id);
          return await _processInviteRedemption(db, invite, userId, userName);
        }
      } catch (e) {
        debugPrint('Error searching one-time invite via collectionGroup: $e');
        // Subcollection fallback if collectionGroup index is missing/building
        try {
          final groupsSnap = await db.collection(AppConstants.groupsCollection).limit(50).get();
          for (final groupDoc in groupsSnap.docs) {
            final subSnap = await db
                .collection(AppConstants.groupsCollection)
                .doc(groupDoc.id)
                .collection('invites')
                .where('tokenClean', isEqualTo: cleanToken)
                .limit(1)
                .get();
            if (subSnap.docs.isNotEmpty) {
              final invite = GroupInviteModel.fromMap(subSnap.docs.first.data(), subSnap.docs.first.id);
              return await _processInviteRedemption(db, invite, userId, userName);
            }
          }
        } catch (fallbackErr) {
          debugPrint('Error in fallback subcollection invite search: $fallbackErr');
        }
      }
    }

    // Fallback to group inviteCode or group ID
    return requestToJoinGroup(
      identifier: cleanInput,
      userId: userId,
      userName: userName,
      photoUrl: photoUrl,
    );
  }

  Future<JoinResult> _processInviteRedemption(
    FirebaseFirestore db,
    GroupInviteModel invite,
    String userId,
    String userName,
  ) async {
    final group = await getGroupById(invite.groupId);
    final info = GroupModelInfo(
      groupId: invite.groupId,
      name: group?.name ?? 'Kitty Group',
      memberCount: group?.memberIds.length ?? 0,
    );

    if (invite.status == InviteStatus.used) {
      return JoinResult(
        status: JoinResultStatus.disabled,
        group: info,
        message: 'This invitation code has already been used by another member.',
      );
    }

    if (invite.status == InviteStatus.revoked) {
      return JoinResult(
        status: JoinResultStatus.disabled,
        group: info,
        message: 'This invitation code was revoked by the host.',
      );
    }

    if (invite.isExpired) {
      return JoinResult(
        status: JoinResultStatus.disabled,
        group: info,
        message: 'This invitation code has expired.',
      );
    }

    if (group != null && group.memberIds.contains(userId)) {
      return JoinResult(
        status: JoinResultStatus.alreadyMember,
        group: info,
        message: 'You are already a member of ${group.name}!',
      );
    }

    // Valid one-time token -> Add member & mark invite as USED
    await addMemberToGroup(invite.groupId, userId, userName: userName);
    await db
        .collection(AppConstants.groupsCollection)
        .doc(invite.groupId)
        .collection('invites')
        .doc(invite.inviteId)
        .update({
      'status': 'used',
      'usedBy': userId,
      'usedByName': userName,
      'usedAt': Timestamp.now(),
    });

    return JoinResult(
      status: JoinResultStatus.joined,
      group: info,
      message: 'Invitation accepted! Welcome to ${group?.name ?? "the Kitty Group"}. 🎉',
    );
  }

  static String _extractCodeFromRawInput(String input) {
    final text = input.trim();
    // 1. Hyphenated 8-char token e.g. K7P9-X4M2
    final hyphenMatch = RegExp(r'([A-Za-z0-9]{4}\-[A-Za-z0-9]{4})').firstMatch(text);
    if (hyphenMatch != null) return hyphenMatch.group(1)!;

    // 2. Query param code e.g. ?code=... or code=...
    final paramMatch = RegExp(r'[?&]code=([A-Za-z0-9\-]{6,9})').firstMatch(text);
    if (paramMatch != null) return paramMatch.group(1)!;

    // 3. 8-character token without hyphen e.g. K7P9X4M2
    final eightCharMatch = RegExp(r'\b([A-Za-z0-9]{8})\b').firstMatch(text);
    if (eightCharMatch != null) return eightCharMatch.group(1)!;

    // 4. 6-character group invite code e.g. KTY7P2
    final sixCharMatch = RegExp(r'\b([A-Za-z0-9]{6})\b').firstMatch(text);
    if (sixCharMatch != null) return sixCharMatch.group(1)!;

    return text;
  }

  /// Host selection management methods
  Future<void> updateHostSelectionMode(String groupId, String mode) async {
    final group = await getGroupById(groupId);
    if (group != null) {
      final updated = group.copyWith(hostSelectionMode: mode);
      await updateGroup(updated);
    }
  }

  Future<void> toggleVolunteer(String groupId, String userId) async {
    final group = await getGroupById(groupId);
    if (group != null) {
      final volunteers = List<String>.from(group.volunteers);
      if (volunteers.contains(userId)) {
        volunteers.remove(userId);
      } else {
        volunteers.add(userId);
      }
      final updated = group.copyWith(volunteers: volunteers);
      await updateGroup(updated);
    }
  }

  Future<void> setSelectedHost(String groupId, String hostId, String hostName, {String? mode}) async {
    final group = await getGroupById(groupId);
    if (group != null) {
      final updated = group.copyWith(
        currentHostId: hostId,
        currentHostName: hostName,
        hostSelectionMode: mode ?? group.hostSelectionMode,
      );
      await updateGroup(updated);
    }
  }
}

