import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

enum InviteStatus {
  active,
  used,
  revoked,
  expired,
}

class GroupInviteModel {
  final String inviteId;
  final String groupId;
  final String token; // e.g. K7P9-X4M2
  final String tokenClean; // e.g. K7P9X4M2
  final InviteStatus status;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? usedBy;
  final String? usedByName;
  final DateTime? usedAt;

  GroupInviteModel({
    required this.inviteId,
    required this.groupId,
    required this.token,
    String? tokenClean,
    this.status = InviteStatus.active,
    required this.createdBy,
    required this.createdByName,
    DateTime? createdAt,
    DateTime? expiresAt,
    this.usedBy,
    this.usedByName,
    this.usedAt,
  })  : tokenClean = tokenClean ?? token.replaceAll('-', '').toUpperCase(),
        createdAt = createdAt ?? DateTime.now(),
        expiresAt = expiresAt ?? DateTime.now().add(const Duration(days: 7));

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => status == InviteStatus.active && !isExpired;

  String get statusString {
    if (status == InviteStatus.used) return 'USED';
    if (status == InviteStatus.revoked) return 'REVOKED';
    if (isExpired) return 'EXPIRED';
    return 'ACTIVE';
  }

  static String generateToken() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random();
    final part1 = List.generate(4, (_) => chars[rnd.nextInt(chars.length)]).join();
    final part2 = List.generate(4, (_) => chars[rnd.nextInt(chars.length)]).join();
    return '$part1-$part2';
  }

  Map<String, dynamic> toMap() {
    return {
      'inviteId': inviteId,
      'groupId': groupId,
      'token': token,
      'tokenClean': tokenClean,
      'status': status.name,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'usedBy': usedBy,
      'usedByName': usedByName,
      'usedAt': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
    };
  }

  factory GroupInviteModel.fromMap(Map<String, dynamic> map, String id) {
    InviteStatus st = InviteStatus.active;
    final rawSt = map['status']?.toString();
    if (rawSt == 'used') {
      st = InviteStatus.used;
    } else if (rawSt == 'revoked') {
      st = InviteStatus.revoked;
    } else if (rawSt == 'expired') {
      st = InviteStatus.expired;
    }

    final rawToken = map['token']?.toString() ?? 'K7P9-X4M2';

    return GroupInviteModel(
      inviteId: id,
      groupId: map['groupId']?.toString() ?? '',
      token: rawToken,
      tokenClean: map['tokenClean']?.toString() ?? rawToken.replaceAll('-', '').toUpperCase(),
      status: st,
      createdBy: map['createdBy']?.toString() ?? '',
      createdByName: map['createdByName']?.toString() ?? 'Host',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 7)),
      usedBy: map['usedBy']?.toString(),
      usedByName: map['usedByName']?.toString(),
      usedAt: (map['usedAt'] as Timestamp?)?.toDate(),
    );
  }
}
