import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../domain/kitty_transaction_model.dart';
import '../../events/domain/event_model.dart';
import '../../groups/domain/group_model.dart';
import '../../members/domain/member_model.dart';
import '../../../core/constants/app_constants.dart';

class LedgerRepository {
  final FirebaseFirestore? _firestore;

  // In-memory store keyed by groupId
  final Map<String, List<KittyTransactionModel>> _transactionStore = {};
  final StreamController<List<KittyTransactionModel>> _localStreamController =
      StreamController<List<KittyTransactionModel>>.broadcast();

  LedgerRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

  void _notifyListeners() {
    if (!_localStreamController.isClosed) {
      _localStreamController.add(_transactionStore.values.expand((element) => element).toList());
    }
  }

  /// Watch transactions for a specific Kitty / Event
  Stream<List<KittyTransactionModel>> watchEventTransactions(String groupId, String eventId) {
    late StreamController<List<KittyTransactionModel>> controller;
    StreamSubscription? firestoreSub;
    StreamSubscription? localSub;

    controller = StreamController<List<KittyTransactionModel>>.broadcast(
      onListen: () {
        final list = (_transactionStore[groupId] ?? []).where((t) => t.eventId == eventId).toList();
        controller.add(list);

        localSub = _localStreamController.stream.listen((_) {
          if (!controller.isClosed) {
            final updatedList = (_transactionStore[groupId] ?? []).where((t) => t.eventId == eventId).toList();
            controller.add(updatedList);
          }
        });

        if (Firebase.apps.isNotEmpty || _firestore != null) {
          try {
            final db = _firestore ?? FirebaseFirestore.instance;
            firestoreSub = db
                .collection(AppConstants.groupsCollection)
                .doc(groupId)
                .collection('transactions')
                .where('eventId', isEqualTo: eventId)
                .snapshots()
                .listen((snap) {
              final remoteList = snap.docs.map((d) => KittyTransactionModel.fromMap(d.data(), d.id)).toList();
              final store = _transactionStore.putIfAbsent(groupId, () => []);
              store.removeWhere((t) => t.eventId == eventId);
              store.addAll(remoteList);
              _notifyListeners();
            }, onError: (e) {
              debugPrint('Error listening to event transactions: $e');
            });
          } catch (e) {
            debugPrint('Error setting up event transactions listener: $e');
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

  /// Watch all transactions across all kitties in a Kitty Circle
  Stream<List<KittyTransactionModel>> watchGroupTransactions(String groupId) {
    late StreamController<List<KittyTransactionModel>> controller;
    StreamSubscription? firestoreSub;
    StreamSubscription? localSub;

    controller = StreamController<List<KittyTransactionModel>>.broadcast(
      onListen: () {
        controller.add(_transactionStore[groupId] ?? []);

        localSub = _localStreamController.stream.listen((_) {
          if (!controller.isClosed) {
            controller.add(_transactionStore[groupId] ?? []);
          }
        });

        if (Firebase.apps.isNotEmpty || _firestore != null) {
          try {
            final db = _firestore ?? FirebaseFirestore.instance;
            firestoreSub = db
                .collection(AppConstants.groupsCollection)
                .doc(groupId)
                .collection('transactions')
                .snapshots()
                .listen((snap) {
              final remoteList = snap.docs.map((d) => KittyTransactionModel.fromMap(d.data(), d.id)).toList();
              _transactionStore[groupId] = remoteList;
              _notifyListeners();
            }, onError: (e) {
              debugPrint('Error listening to group transactions: $e');
            });
          } catch (e) {
            debugPrint('Error setting up group transactions listener: $e');
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

  /// Watch transactions involving a specific member (only kitties they participated in!)
  Stream<List<KittyTransactionModel>> watchMemberTransactions(String groupId, String userId) {
    return watchGroupTransactions(groupId).map((all) {
      return all.where((t) => t.fromUserId == userId || t.toUserId == userId).toList();
    });
  }

  /// Settlement Calculation & Membership Snapshot Per Kitty (Rule 1, 6, 7, 8)
  ///
  /// Enforces the No Retroactive Obligation Rule:
  /// Members only participate financially in kitties on or after their joining date.
  /// Host exception: Host does NOT owe themselves.
  Future<List<KittyTransactionModel>> generateKittySettlementTransactions({
    required EventModel event,
    required GroupModel group,
    required List<MemberModel> groupMembers,
  }) async {
    final existingStore = _transactionStore.putIfAbsent(event.groupId, () => []);
    final existingEventTxns = existingStore.where((t) => t.eventId == event.eventId).toList();
    if (existingEventTxns.isNotEmpty) {
      return existingEventTxns;
    }

    // 1. Membership Snapshot Per Kitty (Filter members who joined on or before event date)
    final eventDate = event.date;
    final eligibleMembers = groupMembers.where((m) {
      final joined = m.joinedAt;
      // Member participated if joined on or before eventDate (or same month)
      return joined.isBefore(eventDate) ||
          (joined.year == eventDate.year && joined.month == eventDate.month && joined.day <= eventDate.day);
    }).toList();

    final List<KittyTransactionModel> createdTxns = [];
    final hostId = event.hostId.isNotEmpty ? event.hostId : group.ownerId;
    final hostName = event.hostName.isNotEmpty ? event.hostName : 'Kitty Host';
    final contribution = group.contributionAmount > 0 ? group.contributionAmount : 2000.0;

    for (final member in eligibleMembers) {
      // Host Exception: Host does not owe themselves (Sneha -> Nobody ₹0)
      if (member.userId == hostId) {
        continue;
      }

      final txnId = 'txn_${event.eventId}_${member.userId}';
      final txn = KittyTransactionModel(
        transactionId: txnId,
        groupId: event.groupId,
        eventId: event.eventId,
        eventTitle: event.title,
        eventDate: event.date,
        hostUserId: hostId,
        hostUserName: hostName,
        fromUserId: member.userId,
        fromUserName: member.displayName,
        toUserId: hostId,
        toUserName: hostName,
        amountExpected: contribution,
        amountPaid: 0.0,
        status: PaymentStatus.pending,
      );

      createdTxns.add(txn);
    }

    existingStore.addAll(createdTxns);
    _notifyListeners();

    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        final batch = db.batch();

        for (final txn in createdTxns) {
          final docRef = db
              .collection(AppConstants.groupsCollection)
              .doc(event.groupId)
              .collection('transactions')
              .doc(txn.transactionId);
          batch.set(docRef, txn.toMap(), SetOptions(merge: true));
        }
        await batch.commit();
      } catch (e) {
        debugPrint('Error saving generated transactions to Firestore: $e');
      }
    }

    return createdTxns;
  }

  /// Manual Payment Recording with Audit History (Rule 12, 13, 14)
  Future<void> recordPayment({
    required String groupId,
    required String transactionId,
    required double amountPaid,
    required PaymentStatus status,
    required String paymentMethod,
    String? paymentReference,
    String? notes,
    DateTime? paymentDate,
    required String recordedByUserId,
    required String recordedByUserName,
    String? changeReason,
  }) async {
    final store = _transactionStore.putIfAbsent(groupId, () => []);
    final idx = store.indexWhere((t) => t.transactionId == transactionId);
    if (idx == -1) return;

    final existing = store[idx];

    // Audit log entry
    final audit = AuditLogItem(
      logId: 'audit_${DateTime.now().millisecondsSinceEpoch}',
      previousAmount: existing.amountPaid,
      newAmount: amountPaid,
      previousStatus: existing.status,
      newStatus: status,
      reason: changeReason ?? (status == PaymentStatus.paid ? 'Payment recorded' : 'Payment status updated'),
      changedBy: recordedByUserId,
      changedByName: recordedByUserName,
      timestamp: DateTime.now(),
    );

    final updatedLogs = List<AuditLogItem>.from(existing.auditLogs)..add(audit);

    final updated = existing.copyWith(
      amountPaid: amountPaid,
      status: status,
      paymentMethod: paymentMethod,
      paymentDate: paymentDate ?? DateTime.now(),
      paymentReference: paymentReference,
      notes: notes,
      auditLogs: updatedLogs,
    );

    store[idx] = updated;
    _notifyListeners();

    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        await db
            .collection(AppConstants.groupsCollection)
            .doc(groupId)
            .collection('transactions')
            .doc(transactionId)
            .set(updated.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error updating transaction payment in Firestore: $e');
      }
    }
  }

  /// Correct / Modify Transaction Amount with Audit Trail (Rule 14)
  Future<void> updateTransactionAmount({
    required String groupId,
    required String transactionId,
    required double newExpectedAmount,
    required String reason,
    required String changedByUserId,
    required String changedByUserName,
  }) async {
    final store = _transactionStore.putIfAbsent(groupId, () => []);
    final idx = store.indexWhere((t) => t.transactionId == transactionId);
    if (idx == -1) return;

    final existing = store[idx];

    final audit = AuditLogItem(
      logId: 'audit_${DateTime.now().millisecondsSinceEpoch}',
      previousAmount: existing.amountExpected,
      newAmount: newExpectedAmount,
      previousStatus: existing.status,
      newStatus: existing.status,
      reason: reason,
      changedBy: changedByUserId,
      changedByName: changedByUserName,
      timestamp: DateTime.now(),
    );

    final updatedLogs = List<AuditLogItem>.from(existing.auditLogs)..add(audit);
    final updated = existing.copyWith(
      amountExpected: newExpectedAmount,
      auditLogs: updatedLogs,
    );

    store[idx] = updated;
    _notifyListeners();

    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        await db
            .collection(AppConstants.groupsCollection)
            .doc(groupId)
            .collection('transactions')
            .doc(transactionId)
            .set(updated.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error updating transaction amount in Firestore: $e');
      }
    }
  }
}
