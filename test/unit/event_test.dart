import 'package:flutter_test/flutter_test.dart';
import 'package:kitty_circle/features/events/domain/event_model.dart';
import 'package:kitty_circle/features/events/domain/rsvp_model.dart';

void main() {
  group('EventModel & RSVP Tests', () {
    test('EventStatus string conversion and parsing', () {
      final event = EventModel(
        eventId: 'event_test_1',
        groupId: 'group_1',
        title: 'October Kitty',
        date: DateTime(2026, 10, 18),
        startTime: '4:00 PM',
        endTime: '7:00 PM',
        hostId: 'user_priya_1',
        hostName: 'Priya',
        venue: 'Indiranagar',
        createdBy: 'user_priya_1',
        status: EventStatus.upcoming,
      );

      expect(event.statusString, equals('UPCOMING'));
      expect(EventModel.parseStatus('LIVE'), equals(EventStatus.live));
      expect(EventModel.parseStatus('COMPLETED'), equals(EventStatus.completed));
    });

    test('RSVP status parsing', () {
      expect(RsvpModel.parseStatus('Going'), equals(RsvpStatus.going));
      expect(RsvpModel.parseStatus('Maybe'), equals(RsvpStatus.maybe));
      expect(RsvpModel.parseStatus('Not Going'), equals(RsvpStatus.notGoing));
    });
  });
}
