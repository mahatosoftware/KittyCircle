import 'package:cloud_firestore/cloud_firestore.dart';

enum JoinRequestStatus {
  pending,
  approved,
  rejected,
}

class JoinRequestModel {
  final String requestId;
  final String groupId;
  final String userId;
  final String userName;
  final String? photoUrl;
  final JoinRequestStatus status;
  final DateTime requestedAt;

  JoinRequestModel({
    required this.requestId,
    required this.groupId,
    required this.userId,
    required this.userName,
    this.photoUrl,
    this.status = JoinRequestStatus.pending,
    DateTime? requestedAt,
  }) : requestedAt = requestedAt ?? DateTime.now();

  String get statusString => status.name;

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'groupId': groupId,
      'userId': userId,
      'userName': userName,
      'photoUrl': photoUrl,
      'status': statusString,
      'requestedAt': Timestamp.fromDate(requestedAt),
    };
  }

  factory JoinRequestModel.fromMap(Map<String, dynamic> map, String id) {
    JoinRequestStatus st = JoinRequestStatus.pending;
    final rawSt = map['status']?.toString();
    if (rawSt == 'approved') {
      st = JoinRequestStatus.approved;
    } else if (rawSt == 'rejected') {
      st = JoinRequestStatus.rejected;
    }

    return JoinRequestModel(
      requestId: id,
      groupId: map['groupId'] ?? '',
      userId: map['userId'] ?? id,
      userName: map['userName'] ?? 'Member',
      photoUrl: map['photoUrl']?.toString(),
      status: st,
      requestedAt: (map['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

enum JoinResultStatus {
  joined,
  pendingApproval,
  alreadyMember,
  disabled,
  notFound,
}

class JoinResult {
  final JoinResultStatus status;
  final GroupModelInfo? group;
  final String message;

  JoinResult({
    required this.status,
    this.group,
    required this.message,
  });
}

class GroupModelInfo {
  final String groupId;
  final String name;
  final int memberCount;

  GroupModelInfo({
    required this.groupId,
    required this.name,
    required this.memberCount,
  });
}
