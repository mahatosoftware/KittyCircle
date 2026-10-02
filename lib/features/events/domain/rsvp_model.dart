import 'package:cloud_firestore/cloud_firestore.dart';

enum RsvpStatus { going, maybe, notGoing, pending }

class RsvpModel {
  final String userId;
  final String eventId;
  final String userName;
  final String? userPhotoUrl;
  final RsvpStatus status;
  final DateTime updatedAt;

  RsvpModel({
    required this.userId,
    required this.eventId,
    required this.userName,
    this.userPhotoUrl,
    required this.status,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  String get statusString {
    switch (status) {
      case RsvpStatus.going:
        return 'Going';
      case RsvpStatus.maybe:
        return 'Maybe';
      case RsvpStatus.notGoing:
        return 'Not Going';
      case RsvpStatus.pending:
        return 'Pending';
    }
  }

  static RsvpStatus parseStatus(String? statusStr) {
    if (statusStr == 'Going' || statusStr == 'going') return RsvpStatus.going;
    if (statusStr == 'Maybe' || statusStr == 'maybe') return RsvpStatus.maybe;
    if (statusStr == 'Not Going' || statusStr == 'notGoing') return RsvpStatus.notGoing;
    return RsvpStatus.pending;
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'eventId': eventId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'status': statusString,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory RsvpModel.fromMap(Map<String, dynamic> map, String id) {
    return RsvpModel(
      userId: id,
      eventId: map['eventId'] ?? '',
      userName: map['userName'] ?? 'Member',
      userPhotoUrl: map['userPhotoUrl'],
      status: parseStatus(map['status']),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
