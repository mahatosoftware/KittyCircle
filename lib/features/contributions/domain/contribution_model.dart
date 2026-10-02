import 'package:cloud_firestore/cloud_firestore.dart';

enum ContributionStatus { paid, pending, partial, exempt }

class ContributionModel {
  final String contributionId;
  final String groupId;
  final String userId;
  final String userName;
  final String monthYear; // e.g. "October 2026"
  final double amountExpected;
  final double amountPaid;
  final ContributionStatus status;
  final DateTime updatedAt;

  ContributionModel({
    required this.contributionId,
    required this.groupId,
    required this.userId,
    required this.userName,
    required this.monthYear,
    required this.amountExpected,
    this.amountPaid = 0.0,
    required this.status,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  String get statusString {
    switch (status) {
      case ContributionStatus.paid:
        return 'Paid';
      case ContributionStatus.pending:
        return 'Pending';
      case ContributionStatus.partial:
        return 'Partial';
      case ContributionStatus.exempt:
        return 'Exempt';
    }
  }

  static ContributionStatus parseStatus(String? str) {
    if (str == 'Paid' || str == 'paid') return ContributionStatus.paid;
    if (str == 'Partial' || str == 'partial') return ContributionStatus.partial;
    if (str == 'Exempt' || str == 'exempt') return ContributionStatus.exempt;
    return ContributionStatus.pending;
  }

  Map<String, dynamic> toMap() {
    return {
      'contributionId': contributionId,
      'groupId': groupId,
      'userId': userId,
      'userName': userName,
      'monthYear': monthYear,
      'amountExpected': amountExpected,
      'amountPaid': amountPaid,
      'status': statusString,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ContributionModel.fromMap(Map<String, dynamic> map, String id) {
    return ContributionModel(
      contributionId: id,
      groupId: map['groupId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Member',
      monthYear: map['monthYear'] ?? '',
      amountExpected: (map['amountExpected'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
      status: parseStatus(map['status']),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
