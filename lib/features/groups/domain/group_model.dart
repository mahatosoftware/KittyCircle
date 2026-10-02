import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String groupId;
  final String name;
  final String description;
  final String? photoUrl;
  final double contributionAmount;
  final String currency;
  final String frequency; // 'Monthly', 'Every 2 weeks', 'Custom'
  final int defaultDurationHours;
  final String ownerId;
  final List<String> memberIds;
  final List<String> adminIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  GroupModel({
    required this.groupId,
    required this.name,
    required this.description,
    this.photoUrl,
    required this.contributionAmount,
    this.currency = '₹',
    this.frequency = 'Monthly',
    this.defaultDurationHours = 3,
    required this.ownerId,
    required this.memberIds,
    required this.adminIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'name': name,
      'description': description,
      'photoUrl': photoUrl,
      'contributionAmount': contributionAmount,
      'currency': currency,
      'frequency': frequency,
      'defaultDurationHours': defaultDurationHours,
      'ownerId': ownerId,
      'createdBy': ownerId,
      'memberIds': memberIds,
      'adminIds': adminIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else if (value is DateTime) {
      return value;
    }
    return DateTime.now();
  }

  factory GroupModel.fromMap(Map<String, dynamic> map, String id) {
    final rawName = map['name'] as String?;
    final resolvedOwner = map['ownerId']?.toString() ?? map['createdBy']?.toString() ?? '';
    return GroupModel(
      groupId: id,
      name: (rawName != null && rawName.trim().isNotEmpty) ? rawName.trim() : 'Kitty Group',
      description: map['description']?.toString() ?? '',
      photoUrl: map['photoUrl']?.toString(),
      contributionAmount: (map['contributionAmount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency']?.toString() ?? '₹',
      frequency: map['frequency']?.toString() ?? 'Monthly',
      defaultDurationHours: (map['defaultDurationHours'] as num?)?.toInt() ?? 3,
      ownerId: resolvedOwner,
      memberIds: (map['memberIds'] as List?)?.map((e) => e.toString()).toList() ?? (resolvedOwner.isNotEmpty ? [resolvedOwner] : []),
      adminIds: (map['adminIds'] as List?)?.map((e) => e.toString()).toList() ?? (resolvedOwner.isNotEmpty ? [resolvedOwner] : []),
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  GroupModel copyWith({
    String? name,
    String? description,
    String? photoUrl,
    double? contributionAmount,
    String? currency,
    String? frequency,
    int? defaultDurationHours,
    String? ownerId,
    List<String>? memberIds,
    List<String>? adminIds,
  }) {
    return GroupModel(
      groupId: groupId,
      name: name ?? this.name,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      contributionAmount: contributionAmount ?? this.contributionAmount,
      currency: currency ?? this.currency,
      frequency: frequency ?? this.frequency,
      defaultDurationHours: defaultDurationHours ?? this.defaultDurationHours,
      ownerId: ownerId ?? this.ownerId,
      memberIds: memberIds ?? this.memberIds,
      adminIds: adminIds ?? this.adminIds,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
