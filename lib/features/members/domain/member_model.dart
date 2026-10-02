import 'package:cloud_firestore/cloud_firestore.dart';

enum MemberRole { owner, admin, member }

class MemberModel {
  final String userId;
  final String groupId;
  final String displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final MemberRole role;
  final DateTime joinedAt;

  MemberModel({
    required this.userId,
    required this.groupId,
    required this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.role = MemberRole.member,
    DateTime? joinedAt,
  }) : joinedAt = joinedAt ?? DateTime.now();

  String get roleString {
    switch (role) {
      case MemberRole.owner:
        return 'Owner';
      case MemberRole.admin:
        return 'Admin';
      case MemberRole.member:
        return 'Member';
    }
  }

  static MemberRole parseRole(String? roleStr) {
    if (roleStr == 'Owner' || roleStr == 'owner') return MemberRole.owner;
    if (roleStr == 'Admin' || roleStr == 'admin') return MemberRole.admin;
    return MemberRole.member;
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'groupId': groupId,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'role': roleString,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  factory MemberModel.fromMap(Map<String, dynamic> map, String id) {
    return MemberModel(
      userId: id,
      groupId: map['groupId'] ?? '',
      displayName: map['displayName'] ?? 'Member',
      photoUrl: map['photoUrl'],
      phoneNumber: map['phoneNumber'],
      role: parseRole(map['role']),
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
