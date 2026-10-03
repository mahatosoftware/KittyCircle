import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

enum MemberRole { owner, admin, member }

class MemberModel {
  final String userId;
  final String groupId;
  final String displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final MemberRole role;
  final DateTime? birthday;
  final DateTime? anniversary;
  final DateTime joinedAt;

  MemberModel({
    required this.userId,
    required this.groupId,
    required this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.role = MemberRole.member,
    this.birthday,
    this.anniversary,
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

  String? get birthdayString => birthday != null ? DateFormat('dd MMMM').format(birthday!) : null;
  String? get anniversaryString => anniversary != null ? DateFormat('dd MMMM').format(anniversary!) : null;

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
      'birthday': birthday != null ? Timestamp.fromDate(birthday!) : null,
      'anniversary': anniversary != null ? Timestamp.fromDate(anniversary!) : null,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  factory MemberModel.fromMap(Map<String, dynamic> map, String id) {
    return MemberModel(
      userId: id,
      groupId: map['groupId'] ?? '',
      displayName: map['displayName'] ?? map['userName'] ?? map['name'] ?? map['user_name'] ?? map['createdByName'] ?? map['usedByName'] ?? 'Kitty Member',
      photoUrl: map['photoUrl'] ?? map['photo_url'],
      phoneNumber: map['phoneNumber'] ?? map['phone'] ?? map['phone_number'],
      role: parseRole(map['role']),
      birthday: (map['birthday'] as Timestamp?)?.toDate(),
      anniversary: (map['anniversary'] as Timestamp?)?.toDate(),
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  MemberModel copyWith({
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    MemberRole? role,
    DateTime? birthday,
    DateTime? anniversary,
  }) {
    return MemberModel(
      userId: userId,
      groupId: groupId,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      birthday: birthday ?? this.birthday,
      anniversary: anniversary ?? this.anniversary,
      joinedAt: joinedAt,
    );
  }
}
