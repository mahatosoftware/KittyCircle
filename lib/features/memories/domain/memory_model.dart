import 'package:cloud_firestore/cloud_firestore.dart';

class MemoryModel {
  final String memoryId;
  final String groupId;
  final String? eventId;
  final String eventTitle;
  final String imageUrl;
  final String caption;
  final String uploadedByUserId;
  final String uploadedByUserName;
  final DateTime createdAt;

  MemoryModel({
    required this.memoryId,
    required this.groupId,
    this.eventId,
    required this.eventTitle,
    required this.imageUrl,
    required this.caption,
    required this.uploadedByUserId,
    required this.uploadedByUserName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'memoryId': memoryId,
      'groupId': groupId,
      'eventId': eventId,
      'eventTitle': eventTitle,
      'imageUrl': imageUrl,
      'caption': caption,
      'uploadedByUserId': uploadedByUserId,
      'uploadedByUserName': uploadedByUserName,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory MemoryModel.fromMap(Map<String, dynamic> map, String id) {
    return MemoryModel(
      memoryId: id,
      groupId: map['groupId'] ?? '',
      eventId: map['eventId'],
      eventTitle: map['eventTitle'] ?? 'Kitty Party',
      imageUrl: map['imageUrl'] ?? '',
      caption: map['caption'] ?? '',
      uploadedByUserId: map['uploadedByUserId'] ?? '',
      uploadedByUserName: map['uploadedByUserName'] ?? 'Member',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
