import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../domain/event_model.dart';
import '../domain/rsvp_model.dart';
import '../domain/attendance_model.dart';
import '../domain/host_schedule_model.dart';
import '../../../core/constants/app_constants.dart';

class EventRepository {
  final FirebaseFirestore? _firestore;

  final Map<String, List<EventModel>> _eventStore = {};
  final Map<String, List<RsvpModel>> _rsvpStore = {};
  final Map<String, List<AttendanceModel>> _attendanceStore = {};
  final Map<String, List<HostScheduleModel>> _hostScheduleStore = {};
  final Map<String, List<TimelineItemModel>> _timelineStore = {};
  final Map<String, List<FoodItemModel>> _foodStore = {};

  final StreamController<Map<String, List<EventModel>>> _localStreamController =
      StreamController<Map<String, List<EventModel>>>.broadcast();

  EventRepository({this._firestore});

  void _notifyListeners() {
    if (!_localStreamController.isClosed) {
      _localStreamController.add(_eventStore);
    }
  }

  Stream<List<EventModel>> watchGroupEvents(String groupId) {
    late StreamController<List<EventModel>> controller;
    StreamSubscription? firestoreSub;
    StreamSubscription? localSub;

    controller = StreamController<List<EventModel>>.broadcast(
      onListen: () {
        controller.add(_eventStore[groupId] ?? []);

        localSub = _localStreamController.stream.listen((_) {
          if (!controller.isClosed) {
            controller.add(_eventStore[groupId] ?? []);
          }
        });

        if (Firebase.apps.isNotEmpty || _firestore != null) {
          try {
            final db = _firestore ?? FirebaseFirestore.instance;
            firestoreSub = db
                .collection(AppConstants.groupsCollection)
                .doc(groupId)
                .collection(AppConstants.eventsCollection)
                .orderBy('date', descending: true)
                .snapshots()
                .listen((snap) {
              final list = snap.docs.map((d) => EventModel.fromMap(d.data(), d.id)).toList();
              _eventStore[groupId] = list;
              _notifyListeners();
            }, onError: (e) {
              debugPrint('Error watching group events: $e');
            });
          } catch (e) {
            debugPrint('Error setting up group events stream: $e');
          }
        }
      },
      onCancel: () {
        localSub?.cancel();
        firestoreSub?.cancel();
      },
    );

    return controller.stream;
  }

  Future<EventModel?> getEventById(String groupId, String eventId) async {
    if (groupId.isNotEmpty) {
      final list = _eventStore[groupId] ?? [];
      final existing = list.where((e) => e.eventId == eventId).firstOrNull;
      if (existing != null) return existing;
    }

    for (final list in _eventStore.values) {
      final found = list.where((e) => e.eventId == eventId).firstOrNull;
      if (found != null) return found;
    }

    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        if (groupId.isNotEmpty) {
          final doc = await db
              .collection(AppConstants.groupsCollection)
              .doc(groupId)
              .collection(AppConstants.eventsCollection)
              .doc(eventId)
              .get();
          if (doc.exists && doc.data() != null) {
            final event = EventModel.fromMap(doc.data()!, doc.id);
            _eventStore.putIfAbsent(groupId, () => []).add(event);
            return event;
          }
        } else {
          final querySnap = await db
              .collectionGroup(AppConstants.eventsCollection)
              .where(FieldPath.documentId, isEqualTo: eventId)
              .limit(1)
              .get();
          if (querySnap.docs.isNotEmpty) {
            final doc = querySnap.docs.first;
            final event = EventModel.fromMap(doc.data(), doc.id);
            _eventStore.putIfAbsent(event.groupId, () => []).add(event);
            return event;
          }
        }
      } catch (e) {
        debugPrint('Error getting event by id: $e');
      }
    }
    return null;
  }

  Future<EventModel> createEvent(EventModel event) async {
    _eventStore.putIfAbsent(event.groupId, () => []).insert(0, event);
    _notifyListeners();

    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        await db
            .collection(AppConstants.groupsCollection)
            .doc(event.groupId)
            .collection(AppConstants.eventsCollection)
            .doc(event.eventId)
            .set(event.toMap());
      } catch (e) {
        debugPrint('Error creating event in Firestore: $e');
      }
    }

    return event;
  }

  Future<void> updateEventStatus(String groupId, String eventId, EventStatus newStatus) async {
    final list = _eventStore[groupId];
    if (list != null) {
      final idx = list.indexWhere((e) => e.eventId == eventId);
      if (idx != -1) {
        list[idx] = list[idx].copyWith(status: newStatus);
        _notifyListeners();
      }
    }

    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        await db
            .collection(AppConstants.groupsCollection)
            .doc(groupId)
            .collection(AppConstants.eventsCollection)
            .doc(eventId)
            .update({'status': newStatus.name});
      } catch (e) {
        debugPrint('Error updating event status in Firestore: $e');
      }
    }
  }

  String? _findGroupIdForEvent(String eventId) {
    for (final entry in _eventStore.entries) {
      if (entry.value.any((e) => e.eventId == eventId)) {
        return entry.key;
      }
    }
    return null;
  }

  // RSVP methods
  Stream<List<RsvpModel>> watchEventRsvps(String eventId, {String? groupId}) {
    late StreamController<List<RsvpModel>> controller;
    StreamSubscription? topSub;
    StreamSubscription? subSub;
    StreamSubscription? localSub;

    controller = StreamController<List<RsvpModel>>.broadcast(
      onListen: () {
        controller.add(_rsvpStore[eventId] ?? []);

        localSub = _localStreamController.stream.listen((_) {
          if (!controller.isClosed) {
            controller.add(_rsvpStore[eventId] ?? []);
          }
        });

        if (Firebase.apps.isNotEmpty || _firestore != null) {
          try {
            final db = _firestore ?? FirebaseFirestore.instance;
            topSub = db
                .collection(AppConstants.rsvpsCollection)
                .where('eventId', isEqualTo: eventId)
                .snapshots()
                .listen((snap) {
              final list = snap.docs.map((d) => RsvpModel.fromMap(d.data(), d.id)).toList();
              _rsvpStore[eventId] = list;
              _notifyListeners();
            }, onError: (e) {
              debugPrint('Error watching top event RSVPs: $e');
            });

            final resolvedGroupId = groupId ?? _findGroupIdForEvent(eventId);
            if (resolvedGroupId != null && resolvedGroupId.isNotEmpty) {
              subSub = db
                  .collection(AppConstants.groupsCollection)
                  .doc(resolvedGroupId)
                  .collection(AppConstants.eventsCollection)
                  .doc(eventId)
                  .collection(AppConstants.rsvpsCollection)
                  .snapshots()
                  .listen((snap) {
                final list = snap.docs.map((d) => RsvpModel.fromMap(d.data(), d.id)).toList();
                _rsvpStore[eventId] = list;
                _notifyListeners();
              }, onError: (e) {
                debugPrint('Error watching sub event RSVPs: $e');
              });
            }
          } catch (e) {
            debugPrint('Error setting up event RSVPs stream: $e');
          }
        }
      },
      onCancel: () {
        localSub?.cancel();
        topSub?.cancel();
        subSub?.cancel();
      },
    );

    return controller.stream;
  }

  Future<void> setRsvp({
    required String eventId,
    required String userId,
    required String userName,
    required RsvpStatus status,
    String? groupId,
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
    _notifyListeners();

    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        final docId = userId.startsWith('${eventId}_') ? userId : '${eventId}_$userId';
        await db
            .collection(AppConstants.rsvpsCollection)
            .doc(docId)
            .set(newRsvp.toMap(), SetOptions(merge: true));

        final resolvedGroupId = groupId ?? _findGroupIdForEvent(eventId);
        if (resolvedGroupId != null && resolvedGroupId.isNotEmpty) {
          await db
              .collection(AppConstants.groupsCollection)
              .doc(resolvedGroupId)
              .collection(AppConstants.eventsCollection)
              .doc(eventId)
              .collection(AppConstants.rsvpsCollection)
              .doc(userId)
              .set(newRsvp.toMap(), SetOptions(merge: true));
        }
      } catch (e) {
        debugPrint('Error setting RSVP in Firestore: $e');
      }
    }
  }

  // Attendance methods
  Stream<List<AttendanceModel>> watchEventAttendance(String eventId) {
    late StreamController<List<AttendanceModel>> controller;
    StreamSubscription? firestoreSub;
    StreamSubscription? localSub;

    controller = StreamController<List<AttendanceModel>>.broadcast(
      onListen: () {
        controller.add(_attendanceStore[eventId] ?? []);

        localSub = _localStreamController.stream.listen((_) {
          if (!controller.isClosed) {
            controller.add(_attendanceStore[eventId] ?? []);
          }
        });

        if (Firebase.apps.isNotEmpty || _firestore != null) {
          try {
            final db = _firestore ?? FirebaseFirestore.instance;
            firestoreSub = db
                .collection(AppConstants.attendanceCollection)
                .where('eventId', isEqualTo: eventId)
                .snapshots()
                .listen((snap) {
              final list = snap.docs.map((d) => AttendanceModel.fromMap(d.data(), d.id)).toList();
              _attendanceStore[eventId] = list;
              _notifyListeners();
            }, onError: (e) {
              debugPrint('Error watching event attendance: $e');
            });
          } catch (e) {
            debugPrint('Error setting up attendance stream: $e');
          }
        }
      },
      onCancel: () {
        localSub?.cancel();
        firestoreSub?.cancel();
      },
    );

    return controller.stream;
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
    _notifyListeners();

    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        await db
            .collection(AppConstants.attendanceCollection)
            .doc('${eventId}_$userId')
            .set(att.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error marking attendance in Firestore: $e');
      }
    }
  }

  // Host Schedule
  Stream<List<HostScheduleModel>> watchHostSchedule(String groupId) {
    late StreamController<List<HostScheduleModel>> controller;
    StreamSubscription? firestoreSub;
    StreamSubscription? localSub;

    controller = StreamController<List<HostScheduleModel>>.broadcast(
      onListen: () {
        controller.add(_hostScheduleStore[groupId] ?? []);

        localSub = _localStreamController.stream.listen((_) {
          if (!controller.isClosed) {
            controller.add(_hostScheduleStore[groupId] ?? []);
          }
        });

        if (Firebase.apps.isNotEmpty || _firestore != null) {
          try {
            final db = _firestore ?? FirebaseFirestore.instance;
            firestoreSub = db
                .collection(AppConstants.hostScheduleCollection)
                .where('groupId', isEqualTo: groupId)
                .snapshots()
                .listen((snap) {
              final list = snap.docs.map((d) => HostScheduleModel.fromMap(d.data(), d.id)).toList();
              _hostScheduleStore[groupId] = list;
              _notifyListeners();
            }, onError: (e) {
              debugPrint('Error watching host schedule: $e');
            });
          } catch (e) {
            debugPrint('Error setting up host schedule stream: $e');
          }
        }
      },
      onCancel: () {
        localSub?.cancel();
        firestoreSub?.cancel();
      },
    );

    return controller.stream;
  }

  Future<void> updateHostSchedule(String groupId, List<HostScheduleModel> schedule) async {
    _hostScheduleStore[groupId] = schedule;
    _notifyListeners();

    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        final batch = db.batch();
        for (final item in schedule) {
          final docRef = db.collection(AppConstants.hostScheduleCollection).doc('${groupId}_${item.scheduleId}');
          batch.set(docRef, item.toMap(), SetOptions(merge: true));
        }
        await batch.commit();
      } catch (e) {
        debugPrint('Error updating host schedule in Firestore: $e');
      }
    }
  }

  // Timeline
  Stream<List<TimelineItemModel>> watchTimeline(String eventId, {String? groupId}) {
    late StreamController<List<TimelineItemModel>> controller;
    StreamSubscription? topSub;
    StreamSubscription? subSub;
    StreamSubscription? localSub;

    controller = StreamController<List<TimelineItemModel>>.broadcast(
      onListen: () {
        controller.add(_timelineStore[eventId] ?? []);

        localSub = _localStreamController.stream.listen((_) {
          if (!controller.isClosed) {
            controller.add(_timelineStore[eventId] ?? []);
          }
        });

        if (Firebase.apps.isNotEmpty || _firestore != null) {
          try {
            final db = _firestore ?? FirebaseFirestore.instance;
            topSub = db
                .collection(AppConstants.timelineCollection)
                .where('eventId', isEqualTo: eventId)
                .snapshots()
                .listen((snap) {
              final list = snap.docs.map((d) => TimelineItemModel.fromMap(d.data(), d.id)).toList();
              _timelineStore[eventId] = list;
              _notifyListeners();
            }, onError: (e) {
              debugPrint('Error watching top timeline: $e');
            });

            final resolvedGroupId = groupId ?? _findGroupIdForEvent(eventId);
            if (resolvedGroupId != null && resolvedGroupId.isNotEmpty) {
              subSub = db
                  .collection(AppConstants.groupsCollection)
                  .doc(resolvedGroupId)
                  .collection(AppConstants.eventsCollection)
                  .doc(eventId)
                  .collection(AppConstants.timelineCollection)
                  .snapshots()
                  .listen((snap) {
                final list = snap.docs.map((d) => TimelineItemModel.fromMap(d.data(), d.id)).toList();
                _timelineStore[eventId] = list;
                _notifyListeners();
              }, onError: (e) {
                debugPrint('Error watching sub timeline: $e');
              });
            }
          } catch (e) {
            debugPrint('Error setting up timeline stream: $e');
          }
        }
      },
      onCancel: () {
        localSub?.cancel();
        topSub?.cancel();
        subSub?.cancel();
      },
    );

    return controller.stream;
  }

  Future<void> updateTimelineItem(String eventId, TimelineItemModel item, {String? groupId}) async {
    final list = _timelineStore.putIfAbsent(eventId, () => []);
    final idx = list.indexWhere((t) => t.itemId == item.itemId);
    if (idx != -1) {
      list[idx] = item;
    } else {
      list.add(item);
    }
    _notifyListeners();

    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        final docId = item.itemId.startsWith('${eventId}_') ? item.itemId : '${eventId}_${item.itemId}';
        await db
            .collection(AppConstants.timelineCollection)
            .doc(docId)
            .set(item.toMap(), SetOptions(merge: true));

        final resolvedGroupId = groupId ?? _findGroupIdForEvent(eventId);
        if (resolvedGroupId != null && resolvedGroupId.isNotEmpty) {
          await db
              .collection(AppConstants.groupsCollection)
              .doc(resolvedGroupId)
              .collection(AppConstants.eventsCollection)
              .doc(eventId)
              .collection(AppConstants.timelineCollection)
              .doc(item.itemId)
              .set(item.toMap(), SetOptions(merge: true));
        }
      } catch (e, st) {
        debugPrint('Error updating timeline item in Firestore: $e\n$st');
      }
    }
  }

  // Food / Potluck
  Stream<List<FoodItemModel>> watchFoodPlanner(String eventId, {String? groupId}) {
    late StreamController<List<FoodItemModel>> controller;
    StreamSubscription? topSub;
    StreamSubscription? subSub;
    StreamSubscription? localSub;

    controller = StreamController<List<FoodItemModel>>.broadcast(
      onListen: () {
        controller.add(_foodStore[eventId] ?? []);

        localSub = _localStreamController.stream.listen((_) {
          if (!controller.isClosed) {
            controller.add(_foodStore[eventId] ?? []);
          }
        });

        if (Firebase.apps.isNotEmpty || _firestore != null) {
          try {
            final db = _firestore ?? FirebaseFirestore.instance;
            topSub = db
                .collection(AppConstants.potluckCollection)
                .where('eventId', isEqualTo: eventId)
                .snapshots()
                .listen((snap) {
              final list = snap.docs.map((d) => FoodItemModel.fromMap(d.data(), d.id)).toList();
              _foodStore[eventId] = list;
              _notifyListeners();
            }, onError: (e) {
              debugPrint('Error watching top food planner: $e');
            });

            final resolvedGroupId = groupId ?? _findGroupIdForEvent(eventId);
            if (resolvedGroupId != null && resolvedGroupId.isNotEmpty) {
              subSub = db
                  .collection(AppConstants.groupsCollection)
                  .doc(resolvedGroupId)
                  .collection(AppConstants.eventsCollection)
                  .doc(eventId)
                  .collection('food_items')
                  .snapshots()
                  .listen((snap) {
                final list = snap.docs.map((d) => FoodItemModel.fromMap(d.data(), d.id)).toList();
                _foodStore[eventId] = list;
                _notifyListeners();
              }, onError: (e) {
                debugPrint('Error watching sub food planner: $e');
              });
            }
          } catch (e) {
            debugPrint('Error setting up food planner stream: $e');
          }
        }
      },
      onCancel: () {
        localSub?.cancel();
        topSub?.cancel();
        subSub?.cancel();
      },
    );

    return controller.stream;
  }

  Future<void> assignFoodItem(String eventId, String itemId, String userId, String userName, {String? groupId}) async {
    final list = _foodStore[eventId];
    FoodItemModel? updated;
    if (list != null) {
      final idx = list.indexWhere((f) => f.itemId == itemId);
      if (idx != -1) {
        updated = FoodItemModel(
          itemId: list[idx].itemId,
          eventId: eventId,
          category: list[idx].category,
          itemName: list[idx].itemName,
          assignedUserId: userId,
          assignedUserName: userName,
        );
        list[idx] = updated;
      }
    }
    _notifyListeners();

    if (updated != null && (Firebase.apps.isNotEmpty || _firestore != null)) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        final docId = itemId.startsWith('${eventId}_') ? itemId : '${eventId}_$itemId';
        await db
            .collection(AppConstants.potluckCollection)
            .doc(docId)
            .set(updated.toMap(), SetOptions(merge: true));

        final resolvedGroupId = groupId ?? _findGroupIdForEvent(eventId);
        if (resolvedGroupId != null && resolvedGroupId.isNotEmpty) {
          await db
              .collection(AppConstants.groupsCollection)
              .doc(resolvedGroupId)
              .collection(AppConstants.eventsCollection)
              .doc(eventId)
              .collection('food_items')
              .doc(itemId)
              .set(updated.toMap(), SetOptions(merge: true));
        }
      } catch (e) {
        debugPrint('Error assigning food item in Firestore: $e');
      }
    }
  }

  Future<void> addFoodItem(FoodItemModel item, {String? groupId}) async {
    _foodStore.putIfAbsent(item.eventId, () => []).add(item);
    _notifyListeners();

    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        final docId = item.itemId.startsWith('${item.eventId}_') ? item.itemId : '${item.eventId}_${item.itemId}';
        await db
            .collection(AppConstants.potluckCollection)
            .doc(docId)
            .set(item.toMap(), SetOptions(merge: true));

        final resolvedGroupId = groupId ?? _findGroupIdForEvent(item.eventId);
        if (resolvedGroupId != null && resolvedGroupId.isNotEmpty) {
          await db
              .collection(AppConstants.groupsCollection)
              .doc(resolvedGroupId)
              .collection(AppConstants.eventsCollection)
              .doc(item.eventId)
              .collection('food_items')
              .doc(item.itemId)
              .set(item.toMap(), SetOptions(merge: true));
        }
      } catch (e) {
        debugPrint('Error adding food item to Firestore: $e');
      }
    }
  }
}
