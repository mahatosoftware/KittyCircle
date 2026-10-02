import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitty_circle/features/auth/presentation/login_screen.dart';

class TestHttpOverrides extends HttpOverrides {}

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  testWidgets('LoginScreen smoke test & options check', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Kitty Circle'), findsOneWidget);
    expect(find.text('Kitty Circle — Plan. Play. Celebrate.'), findsOneWidget);
    expect(find.text('Phone Login'), findsOneWidget);
    expect(find.text('Email / Password'), findsOneWidget);
  });
}
