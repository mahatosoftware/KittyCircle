import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../domain/contribution_model.dart';
import '../../../core/constants/app_constants.dart';

class ContributionRepository {
  final FirebaseFirestore? _firestore;

  final Map<String, List<ContributionModel>> _contributionStore = {
    'group_sunshine_1': [
      ContributionModel(contributionId: 'c1', groupId: 'group_sunshine_1', userId: 'user_priya_1', userName: 'Priya Sharma', monthYear: 'October 2026', amountExpected: 2000, amountPaid: 2000, status: ContributionStatus.paid),
      ContributionModel(contributionId: 'c2', groupId: 'group_sunshine_1', userId: 'user_neha_2', userName: 'Neha Gupta', monthYear: 'October 2026', amountExpected: 2000, amountPaid: 2000, status: ContributionStatus.paid),
      ContributionModel(contributionId: 'c3', groupId: 'group_sunshine_1', userId: 'user_kavita_3', userName: 'Kavita Verma', monthYear: 'October 2026', amountExpected: 2000, amountPaid: 0, status: ContributionStatus.pending),
      ContributionModel(contributionId: 'c4', groupId: 'group_sunshine_1', userId: 'user_ritu_4', userName: 'Ritu Kapoor', monthYear: 'October 2026', amountExpected: 2000, amountPaid: 1000, status: ContributionStatus.partial),
      ContributionModel(contributionId: 'c5', groupId: 'group_sunshine_1', userId: 'user_anjali_5', userName: 'Anjali Singh', monthYear: 'October 2026', amountExpected: 2000, amountPaid: 2000, status: ContributionStatus.paid),
      ContributionModel(contributionId: 'c6', groupId: 'group_sunshine_1', userId: 'user_simran_6', userName: 'Simran Kaur', monthYear: 'October 2026', amountExpected: 2000, amountPaid: 2000, status: ContributionStatus.paid),
      ContributionModel(contributionId: 'c7', groupId: 'group_sunshine_1', userId: 'user_pooja_7', userName: 'Pooja Reddy', monthYear: 'October 2026', amountExpected: 2000, amountPaid: 0, status: ContributionStatus.exempt),
    ],
  };

  ContributionRepository({this._firestore});

  Stream<List<ContributionModel>> watchGroupContributions(String groupId, String monthYear) async* {
    yield _contributionStore[groupId] ?? [];

    if (Firebase.apps.isEmpty && _firestore == null) return;

    try {
      final db = _firestore ?? FirebaseFirestore.instance;
      final snapStream = db
          .collection(AppConstants.groupsCollection)
          .doc(groupId)
          .collection(AppConstants.contributionsCollection)
          .where('monthYear', isEqualTo: monthYear)
          .snapshots();

      await for (final snap in snapStream) {
        final list = snap.docs.map((d) => ContributionModel.fromMap(d.data(), d.id)).toList();
        if (list.isNotEmpty) {
          _contributionStore[groupId] = list;
          yield list;
        } else {
          yield _contributionStore[groupId] ?? [];
        }
      }
    } catch (_) {
      yield _contributionStore[groupId] ?? [];
    }
  }

  Future<void> updateContributionStatus({
    required String groupId,
    required String contributionId,
    required ContributionStatus status,
    required double amountPaid,
  }) async {
    final list = _contributionStore[groupId];
    if (list != null) {
      final idx = list.indexWhere((c) => c.contributionId == contributionId);
      if (idx != -1) {
        final item = list[idx];
        final updated = ContributionModel(
          contributionId: item.contributionId,
          groupId: groupId,
          userId: item.userId,
          userName: item.userName,
          monthYear: item.monthYear,
          amountExpected: item.amountExpected,
          amountPaid: amountPaid,
          status: status,
        );
        list[idx] = updated;

        if (Firebase.apps.isNotEmpty || _firestore != null) {
          try {
            final db = _firestore ?? FirebaseFirestore.instance;
            await db
                .collection(AppConstants.groupsCollection)
                .doc(groupId)
                .collection(AppConstants.contributionsCollection)
                .doc(contributionId)
                .set(updated.toMap(), SetOptions(merge: true));
          } catch (_) {}
        }
      }
    }
  }
}
