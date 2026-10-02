import 'package:cloud_firestore/cloud_firestore.dart';

enum EventStatus { draft, invitationSent, upcoming, live, completed, cancelled }

class EventModel {
  final String eventId;
  final String groupId;
  final String title;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String hostId;
  final String hostName;
  final String venue;
  final String venueAddress;
  final String theme;
  final String dressCode;
  final String foodNotes;
  final String description;
  final String createdBy;
  final EventStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventModel({
    required this.eventId,
    required this.groupId,
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.hostId,
    required this.hostName,
    required this.venue,
    this.venueAddress = '',
    this.theme = 'General',
    this.dressCode = '',
    this.foodNotes = '',
    this.description = '',
    required this.createdBy,
    this.status = EventStatus.upcoming,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get statusString {
    switch (status) {
      case EventStatus.draft:
        return 'DRAFT';
      case EventStatus.invitationSent:
        return 'INVITATION_SENT';
      case EventStatus.upcoming:
        return 'UPCOMING';
      case EventStatus.live:
        return 'LIVE';
      case EventStatus.completed:
        return 'COMPLETED';
      case EventStatus.cancelled:
        return 'CANCELLED';
    }
  }

  static EventStatus parseStatus(String? statusStr) {
    switch (statusStr) {
      case 'DRAFT':
        return EventStatus.draft;
      case 'INVITATION_SENT':
        return EventStatus.invitationSent;
      case 'LIVE':
        return EventStatus.live;
      case 'COMPLETED':
        return EventStatus.completed;
      case 'CANCELLED':
        return EventStatus.cancelled;
      default:
        return EventStatus.upcoming;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'groupId': groupId,
      'title': title,
      'date': Timestamp.fromDate(date),
      'startTime': startTime,
      'endTime': endTime,
      'hostId': hostId,
      'hostName': hostName,
      'venue': venue,
      'venueAddress': venueAddress,
      'theme': theme,
      'dressCode': dressCode,
      'foodNotes': foodNotes,
      'description': description,
      'createdBy': createdBy,
      'status': statusString,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map, String id) {
    return EventModel(
      eventId: id,
      groupId: map['groupId'] ?? '',
      title: map['title'] ?? 'Kitty Gathering',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startTime: map['startTime'] ?? '4:00 PM',
      endTime: map['endTime'] ?? '7:00 PM',
      hostId: map['hostId'] ?? '',
      hostName: map['hostName'] ?? 'Host',
      venue: map['venue'] ?? 'Host\'s Residence',
      venueAddress: map['venueAddress'] ?? '',
      theme: map['theme'] ?? 'General',
      dressCode: map['dressCode'] ?? '',
      foodNotes: map['foodNotes'] ?? '',
      description: map['description'] ?? '',
      createdBy: map['createdBy'] ?? '',
      status: parseStatus(map['status']),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  EventModel copyWith({
    String? title,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? hostId,
    String? hostName,
    String? venue,
    String? venueAddress,
    String? theme,
    String? dressCode,
    String? foodNotes,
    String? description,
    EventStatus? status,
  }) {
    return EventModel(
      eventId: eventId,
      groupId: groupId,
      title: title ?? this.title,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      venue: venue ?? this.venue,
      venueAddress: venueAddress ?? this.venueAddress,
      theme: theme ?? this.theme,
      dressCode: dressCode ?? this.dressCode,
      foodNotes: foodNotes ?? this.foodNotes,
      description: description ?? this.description,
      createdBy: createdBy,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
