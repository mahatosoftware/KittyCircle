import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitty_circle/app/providers.dart';
import 'package:kitty_circle/features/events/domain/event_model.dart';
import 'package:kitty_circle/features/events/domain/rsvp_model.dart';
import 'package:kitty_circle/features/events/domain/host_schedule_model.dart';
import 'package:kitty_circle/features/games/domain/game_models.dart';
import 'package:kitty_circle/features/events/presentation/event_detail_screen.dart';

class TestHttpOverrides extends HttpOverrides {}

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  testWidgets('EventDetailScreen renders without overflow on narrow screen with long text', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final longEvent = EventModel(
      eventId: 'evt_test_1',
      groupId: 'group_1',
      title: 'Extremely Long Event Title For Annual Super Kitty Gala Celebration 2026',
      theme: 'Extremely Long Theme Name Retro Bollywood Glamour 80s Masquerade Night',
      date: DateTime(2026, 10, 15),
      startTime: '07:00 PM',
      endTime: '11:30 PM',
      venue: 'Grand Royal Palace Ballroom & Convention Hall',
      venueAddress: '123 Grand Celebration Boulevard, Sector 45, Cyber City, Gurgaon',
      hostId: 'user_1',
      hostName: 'Priya Sharma-Deshmukh & Ananya Roy-Chowdhury',
      createdBy: 'user_1',
      status: EventStatus.upcoming,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentEventProvider.overrideWith((ref) => Stream.value(longEvent)),
          eventRsvpsProvider('evt_test_1').overrideWith((ref) => Stream.value(<RsvpModel>[])),
          eventTimelineProvider('evt_test_1').overrideWith((ref) => Stream.value(<TimelineItemModel>[])),
          eventFoodPlannerProvider('evt_test_1').overrideWith((ref) => Stream.value(<FoodItemModel>[])),
          eventWinnersProvider('evt_test_1').overrideWith((ref) => Stream.value(<WinnerModel>[])),
        ],
        child: const MaterialApp(
          home: EventDetailScreen(eventId: 'evt_test_1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Event Details'), findsOneWidget);
  });
}
