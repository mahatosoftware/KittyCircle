import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus { present, absent, late }

class AttendanceModel {
  final String userId;
  final String eventId;
  final String userName;
  final AttendanceStatus status;
  final DateTime recordedAt;

  AttendanceModel({
    required this.userId,
    required this.eventId,
    required this.userName,
    required this.status,
    DateTime? recordedAt,
  }) : recordedAt = recordedAt ?? DateTime.now();

  String get statusString {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
    }
  }

  static AttendanceStatus parseStatus(String? statusStr) {
    if (statusStr == 'Present' || statusStr == 'present') return AttendanceStatus.present;
    if (statusStr == 'Late' || statusStr == 'late') return AttendanceStatus.late;
    return AttendanceStatus.absent;
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'eventId': eventId,
      'userName': userName,
      'status': statusString,
      'recordedAt': Timestamp.fromDate(recordedAt),
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String id) {
    return AttendanceModel(
      userId: id,
      eventId: map['eventId'] ?? '',
      userName: map['userName'] ?? 'Member',
      status: parseStatus(map['status']),
      recordedAt: (map['recordedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
