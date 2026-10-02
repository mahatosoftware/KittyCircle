import 'package:cloud_firestore/cloud_firestore.dart';

class HostScheduleModel {
  final String scheduleId;
  final String groupId;
  final String monthYear; // e.g. 'October 2026'
  final String hostId;
  final String hostName;
  final String? hostPhotoUrl;
  final DateTime scheduledDate;
  final bool isCompleted;
  final bool isSkipped;

  HostScheduleModel({
    required this.scheduleId,
    required this.groupId,
    required this.monthYear,
    required this.hostId,
    required this.hostName,
    this.hostPhotoUrl,
    required this.scheduledDate,
    this.isCompleted = false,
    this.isSkipped = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'scheduleId': scheduleId,
      'groupId': groupId,
      'monthYear': monthYear,
      'hostId': hostId,
      'hostName': hostName,
      'hostPhotoUrl': hostPhotoUrl,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'isCompleted': isCompleted,
      'isSkipped': isSkipped,
    };
  }

  factory HostScheduleModel.fromMap(Map<String, dynamic> map, String id) {
    return HostScheduleModel(
      scheduleId: id,
      groupId: map['groupId'] ?? '',
      monthYear: map['monthYear'] ?? '',
      hostId: map['hostId'] ?? '',
      hostName: map['hostName'] ?? 'Member',
      hostPhotoUrl: map['hostPhotoUrl'],
      scheduledDate: (map['scheduledDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isCompleted: map['isCompleted'] ?? false,
      isSkipped: map['isSkipped'] ?? false,
    );
  }
}

class TimelineItemModel {
  final String itemId;
  final String eventId;
  final String timeString; // e.g. "4:00 PM"
  final String title; // e.g. "Welcome & Drinks"
  final bool isCompleted;
  final bool isCurrent;
  final int order;

  TimelineItemModel({
    required this.itemId,
    required this.eventId,
    required this.timeString,
    required this.title,
    this.isCompleted = false,
    this.isCurrent = false,
    required this.order,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'eventId': eventId,
      'timeString': timeString,
      'title': title,
      'isCompleted': isCompleted,
      'isCurrent': isCurrent,
      'order': order,
    };
  }

  factory TimelineItemModel.fromMap(Map<String, dynamic> map, String id) {
    return TimelineItemModel(
      itemId: id,
      eventId: map['eventId'] ?? '',
      timeString: map['timeString'] ?? '',
      title: map['title'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      isCurrent: map['isCurrent'] ?? false,
      order: map['order'] ?? 0,
    );
  }
}

class FoodItemModel {
  final String itemId;
  final String eventId;
  final String category; // 'Starters', 'Main Course', 'Dessert', 'Drinks'
  final String itemName;
  final String? assignedUserId;
  final String? assignedUserName;

  FoodItemModel({
    required this.itemId,
    required this.eventId,
    required this.category,
    required this.itemName,
    this.assignedUserId,
    this.assignedUserName,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'eventId': eventId,
      'category': category,
      'itemName': itemName,
      'assignedUserId': assignedUserId,
      'assignedUserName': assignedUserName,
    };
  }

  factory FoodItemModel.fromMap(Map<String, dynamic> map, String id) {
    return FoodItemModel(
      itemId: id,
      eventId: map['eventId'] ?? '',
      category: map['category'] ?? 'Starters',
      itemName: map['itemName'] ?? '',
      assignedUserId: map['assignedUserId'],
      assignedUserName: map['assignedUserName'],
    );
  }
}
