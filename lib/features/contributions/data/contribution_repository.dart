import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../domain/contribution_model.dart';
import '../../../core/constants/app_constants.dart';

class ContributionRepository {
  final FirebaseFirestore? _firestore;

  final Map<String, List<ContributionModel>> _contributionStore = {};

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
        _contributionStore[groupId] = list;
        yield list;
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
    String? userId,
    String? userName,
    String? monthYear,
    double? amountExpected,
  }) async {
    final list = _contributionStore.putIfAbsent(groupId, () => []);
    final idx = list.indexWhere((c) => c.contributionId == contributionId || (userId != null && userId.isNotEmpty && c.userId == userId));

    ContributionModel updated;
    if (idx != -1) {
      final item = list[idx];
      updated = ContributionModel(
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
    } else {
      updated = ContributionModel(
        contributionId: contributionId,
        groupId: groupId,
        userId: userId ?? '',
        userName: userName ?? 'Member',
        monthYear: monthYear ?? 'October 2026',
        amountExpected: amountExpected ?? 2000.0,
        amountPaid: amountPaid,
        status: status,
      );
      list.add(updated);
    }

    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        await db
            .collection(AppConstants.groupsCollection)
            .doc(groupId)
            .collection(AppConstants.contributionsCollection)
            .doc(updated.contributionId)
            .set(updated.toMap(), SetOptions(merge: true));
      } catch (_) {}
    }
  }
}
