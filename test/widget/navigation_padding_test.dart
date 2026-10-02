import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitty_circle/core/widgets/app_buttons.dart';

class TestHttpOverrides extends HttpOverrides {}

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  testWidgets('PrimaryButton and SecondaryButton apply navigation padding when requested', (WidgetTester tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(padding: EdgeInsets.only(bottom: 34.0)),
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: const [
                PrimaryButton(
                  text: 'Bottom Action Button',
                  useNavigationPadding: true,
                ),
                SecondaryButton(
                  text: 'Secondary Action Button',
                  useNavigationPadding: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Padding widgets with bottom: 34.0 exist for each button
    final paddingFinders = find.byType(Padding);
    final has34pxPadding = paddingFinders.evaluate().any((element) {
      final widget = element.widget as Padding;
      return widget.padding == const EdgeInsets.only(bottom: 34.0);
    });

    expect(has34pxPadding, isTrue);
  });
}
