import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitty_circle/app/providers.dart';
import 'package:kitty_circle/features/auth/domain/user_model.dart';
import 'package:kitty_circle/features/events/presentation/create_event_screen.dart';

class TestHttpOverrides extends HttpOverrides {}

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  testWidgets('CreateEventScreen renders without crash when currentUser has custom UID', (WidgetTester tester) async {
    final customUser = UserModel(
      uid: 'user_priya_101',
      displayName: 'Priya Organizer',
      email: 'priya@kittycircle.app',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(customUser)),
        ],
        child: const MaterialApp(
          home: CreateEventScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Create Kitty Event'), findsOneWidget);
  });
}
