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
      'memberIds': memberIds,
      'adminIds': adminIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory GroupModel.fromMap(Map<String, dynamic> map, String id) {
    return GroupModel(
      groupId: id,
      name: map['name'] ?? 'Kitty Group',
      description: map['description'] ?? '',
      photoUrl: map['photoUrl'],
      contributionAmount: (map['contributionAmount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? '₹',
      frequency: map['frequency'] ?? 'Monthly',
      defaultDurationHours: map['defaultDurationHours'] ?? 3,
      ownerId: map['ownerId'] ?? '',
      memberIds: List<String>.from(map['memberIds'] ?? []),
      adminIds: List<String>.from(map['adminIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
