import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../domain/event_model.dart';
import '../domain/rsvp_model.dart';
import '../domain/attendance_model.dart';
import '../domain/host_schedule_model.dart';
import '../../../core/constants/app_constants.dart';

class EventRepository {
  final FirebaseFirestore? _firestore;

  final Map<String, List<EventModel>> _eventStore = {
    'group_sunshine_1': [
      EventModel(
        eventId: 'event_oct_18',
        groupId: 'group_sunshine_1',
        title: 'October Bollywood Kitty',
        date: DateTime(2026, 10, 18, 16, 0),
        startTime: '4:00 PM',
        endTime: '7:00 PM',
        hostId: 'user_priya_1',
        hostName: 'Priya Sharma',
        venue: 'Priya\'s Residence',
        venueAddress: '102 Sunview Towers, Indiranagar, Bengaluru',
        theme: 'Bollywood',
        dressCode: 'Retro 90s Saree / Kurti',
        foodNotes: 'Delicious Street Food & Chat counter + Dessert spread',
        description: 'Get ready for October Kitty! Games, prizes, delicious food and fun chatter!',
        createdBy: 'user_priya_1',
        status: EventStatus.upcoming,
      ),
      EventModel(
        eventId: 'event_sep_18',
        groupId: 'group_sunshine_1',
        title: 'September Floral Kitty',
        date: DateTime(2026, 9, 18, 16, 0),
        startTime: '4:00 PM',
        endTime: '7:00 PM',
        hostId: 'user_neha_2',
        hostName: 'Neha Gupta',
        venue: 'Neha\'s Residence',
        theme: 'Floral',
        status: EventStatus.completed,
        createdBy: 'user_neha_2',
      ),
    ],
  };

  final Map<String, List<RsvpModel>> _rsvpStore = {
    'event_oct_18': [
      RsvpModel(userId: 'user_priya_1', eventId: 'event_oct_18', userName: 'Priya Sharma', status: RsvpStatus.going),
      RsvpModel(userId: 'user_neha_2', eventId: 'event_oct_18', userName: 'Neha Gupta', status: RsvpStatus.going),
      RsvpModel(userId: 'user_kavita_3', eventId: 'event_oct_18', userName: 'Kavita Verma', status: RsvpStatus.going),
      RsvpModel(userId: 'user_ritu_4', eventId: 'event_oct_18', userName: 'Ritu Kapoor', status: RsvpStatus.maybe),
      RsvpModel(userId: 'user_anjali_5', eventId: 'event_oct_18', userName: 'Anjali Singh', status: RsvpStatus.going),
      RsvpModel(userId: 'user_simran_6', eventId: 'event_oct_18', userName: 'Simran Kaur', status: RsvpStatus.going),
      RsvpModel(userId: 'user_pooja_7', eventId: 'event_oct_18', userName: 'Pooja Reddy', status: RsvpStatus.notGoing),
    ],
  };

  final Map<String, List<AttendanceModel>> _attendanceStore = {};

  final Map<String, List<HostScheduleModel>> _hostScheduleStore = {
    'group_sunshine_1': [
      HostScheduleModel(scheduleId: 'sch_1', groupId: 'group_sunshine_1', monthYear: 'October 2026', hostId: 'user_priya_1', hostName: 'Priya Sharma', scheduledDate: DateTime(2026, 10, 18)),
      HostScheduleModel(scheduleId: 'sch_2', groupId: 'group_sunshine_1', monthYear: 'November 2026', hostId: 'user_neha_2', hostName: 'Neha Gupta', scheduledDate: DateTime(2026, 11, 16)),
      HostScheduleModel(scheduleId: 'sch_3', groupId: 'group_sunshine_1', monthYear: 'December 2026', hostId: 'user_kavita_3', hostName: 'Kavita Verma', scheduledDate: DateTime(2026, 12, 18)),
      HostScheduleModel(scheduleId: 'sch_4', groupId: 'group_sunshine_1', monthYear: 'January 2027', hostId: 'user_ritu_4', hostName: 'Ritu Kapoor', scheduledDate: DateTime(2027, 1, 18)),
      HostScheduleModel(scheduleId: 'sch_5', groupId: 'group_sunshine_1', monthYear: 'February 2027', hostId: 'user_anjali_5', hostName: 'Anjali Singh', scheduledDate: DateTime(2027, 2, 18)),
    ],
  };

  final Map<String, List<TimelineItemModel>> _timelineStore = {
    'event_oct_18': [
      TimelineItemModel(itemId: 't1', eventId: 'event_oct_18', timeString: '4:00 PM', title: 'Welcome & Refreshing Drinks', isCompleted: true, order: 1),
      TimelineItemModel(itemId: 't2', eventId: 'event_oct_18', timeString: '4:15 PM', title: 'Snacks & High Tea', isCompleted: true, order: 2),
      TimelineItemModel(itemId: 't3', eventId: 'event_oct_18', timeString: '4:30 PM', title: 'Game 1: Bollywood Quiz', isCurrent: true, order: 3),
      TimelineItemModel(itemId: 't4', eventId: 'event_oct_18', timeString: '5:00 PM', title: 'Game 2: Memory Challenge', order: 4),
      TimelineItemModel(itemId: 't5', eventId: 'event_oct_18', timeString: '5:30 PM', title: '🎁 Lucky Draw & Winner Ceremony', order: 5),
      TimelineItemModel(itemId: 't6', eventId: 'event_oct_18', timeString: '6:00 PM', title: 'Photoshoot & Group Memories', order: 6),
      TimelineItemModel(itemId: 't7', eventId: 'event_oct_18', timeString: '6:30 PM', title: 'Dinner Spread', order: 7),
    ],
  };

  final Map<String, List<FoodItemModel>> _foodStore = {
    'event_oct_18': [
      FoodItemModel(itemId: 'f1', eventId: 'event_oct_18', category: 'Starters', itemName: 'Pani Puri & Sev Puri', assignedUserId: 'user_priya_1', assignedUserName: 'Priya'),
      FoodItemModel(itemId: 'f2', eventId: 'event_oct_18', category: 'Starters', itemName: 'Paneer Tikka Skewers', assignedUserId: 'user_neha_2', assignedUserName: 'Neha'),
      FoodItemModel(itemId: 'f3', eventId: 'event_oct_18', category: 'Main Course', itemName: 'Dal Makhani & Naan', assignedUserId: 'user_kavita_3', assignedUserName: 'Kavita'),
      FoodItemModel(itemId: 'f4', eventId: 'event_oct_18', category: 'Dessert', itemName: 'Gulab Jamun & Ice Cream', assignedUserId: 'user_ritu_4', assignedUserName: 'Ritu'),
      FoodItemModel(itemId: 'f5', eventId: 'event_oct_18', category: 'Drinks', itemName: 'Mojitos & Mocktails', assignedUserId: 'user_anjali_5', assignedUserName: 'Anjali'),
    ],
  };

  EventRepository({this._firestore});

  Stream<List<EventModel>> watchGroupEvents(String groupId) async* {
    yield _eventStore[groupId] ?? [];

    if (Firebase.apps.isEmpty && _firestore == null) return;

    try {
      final db = _firestore ?? FirebaseFirestore.instance;
      final snapStream = db
          .collection(AppConstants.groupsCollection)
          .doc(groupId)
          .collection(AppConstants.eventsCollection)
          .orderBy('date', descending: true)
          .snapshots();

      await for (final snap in snapStream) {
        final list = snap.docs.map((d) => EventModel.fromMap(d.data(), d.id)).toList();
        if (list.isNotEmpty) {
          _eventStore[groupId] = list;
          yield list;
        } else {
          yield _eventStore[groupId] ?? [];
        }
      }
    } catch (_) {
      yield _eventStore[groupId] ?? [];
    }
  }

  Future<EventModel?> getEventById(String groupId, String eventId) async {
    final list = _eventStore[groupId] ?? [];
    return list.firstWhere((e) => e.eventId == eventId, orElse: () {
      return EventModel(
        eventId: eventId,
        groupId: groupId,
        title: 'October Kitty',
        date: DateTime.now(),
        startTime: '4:00 PM',
        endTime: '7:00 PM',
        hostId: 'user_priya_1',
        hostName: 'Priya',
        venue: 'Priya\'s Residence',
        createdBy: 'user_priya_1',
      );
    });
  }

  Future<EventModel> createEvent(EventModel event) async {
    _eventStore.putIfAbsent(event.groupId, () => []).insert(0, event);

    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        await db
            .collection(AppConstants.groupsCollection)
            .doc(event.groupId)
            .collection(AppConstants.eventsCollection)
            .doc(event.eventId)
            .set(event.toMap());
      } catch (_) {}
    }

    return event;
  }

  Future<void> updateEventStatus(String groupId, String eventId, EventStatus newStatus) async {
    final list = _eventStore[groupId];
    if (list != null) {
      final idx = list.indexWhere((e) => e.eventId == eventId);
      if (idx != -1) {
        list[idx] = list[idx].copyWith(status: newStatus);
      }
    }
  }

  // RSVP methods
  Stream<List<RsvpModel>> watchEventRsvps(String eventId) async* {
    yield _rsvpStore[eventId] ?? [];
  }

  Future<void> setRsvp({
    required String eventId,
    required String userId,
    required String userName,
    required RsvpStatus status,
  }) async {
    final list = _rsvpStore.putIfAbsent(eventId, () => []);
    final idx = list.indexWhere((r) => r.userId == userId);
    final newRsvp = RsvpModel(
      userId: userId,
      eventId: eventId,
      userName: userName,
      status: status,
    );
    if (idx != -1) {
      list[idx] = newRsvp;
    } else {
      list.add(newRsvp);
    }
  }

  // Attendance methods
  Stream<List<AttendanceModel>> watchEventAttendance(String eventId) async* {
    yield _attendanceStore[eventId] ?? [];
  }

  Future<void> markAttendance({
    required String eventId,
    required String userId,
    required String userName,
    required AttendanceStatus status,
  }) async {
    final list = _attendanceStore.putIfAbsent(eventId, () => []);
    final idx = list.indexWhere((a) => a.userId == userId);
    final att = AttendanceModel(userId: userId, eventId: eventId, userName: userName, status: status);
    if (idx != -1) {
      list[idx] = att;
    } else {
      list.add(att);
    }
  }

  // Host Schedule
  Stream<List<HostScheduleModel>> watchHostSchedule(String groupId) async* {
    yield _hostScheduleStore[groupId] ?? [];
  }

  Future<void> updateHostSchedule(String groupId, List<HostScheduleModel> schedule) async {
    _hostScheduleStore[groupId] = schedule;
  }

  // Timeline
  Stream<List<TimelineItemModel>> watchTimeline(String eventId) async* {
    yield _timelineStore[eventId] ?? [];
  }

  Future<void> updateTimelineItem(String eventId, TimelineItemModel item) async {
    final list = _timelineStore.putIfAbsent(eventId, () => []);
    final idx = list.indexWhere((t) => t.itemId == item.itemId);
    if (idx != -1) {
      list[idx] = item;
    } else {
      list.add(item);
    }
  }

  // Food / Potluck
  Stream<List<FoodItemModel>> watchFoodPlanner(String eventId) async* {
    yield _foodStore[eventId] ?? [];
  }

  Future<void> assignFoodItem(String eventId, String itemId, String userId, String userName) async {
    final list = _foodStore[eventId];
    if (list != null) {
      final idx = list.indexWhere((f) => f.itemId == itemId);
      if (idx != -1) {
        list[idx] = FoodItemModel(
          itemId: list[idx].itemId,
          eventId: eventId,
          category: list[idx].category,
          itemName: list[idx].itemName,
          assignedUserId: userId,
          assignedUserName: userName,
        );
      }
    }
  }

  Future<void> addFoodItem(FoodItemModel item) async {
    _foodStore.putIfAbsent(item.eventId, () => []).add(item);
  }
}
