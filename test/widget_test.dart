// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:humsafar_app/main.dart';

void main() {
  testWidgets('HumSafar app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HumSafarApp());

    // Verify that the Explore screen is displayed by default
    expect(find.text('Explore Destinations'), findsOneWidget);
    expect(find.text('Mountain Trails'), findsOneWidget);
    expect(find.text('Beach Paradise'), findsOneWidget);
  });

  testWidgets('Navigation between screens works', (WidgetTester tester) async {
    await tester.pumpWidget(const HumSafarApp());

    // Verify Explore screen is shown
    expect(find.text('Explore Destinations'), findsOneWidget);

    // Tap on Trips navigation
    await tester.tap(find.text('Trips'));
    await tester.pumpAndSettle();

    // Verify Trips screen is shown
    expect(find.text('My Trips'), findsOneWidget);
    expect(find.text('Northern Mountains'), findsOneWidget);

    // Tap on Profile navigation
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    // Verify Profile screen is shown
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Travel Enthusiast'), findsOneWidget);
  });

  testWidgets('Search dialog appears when search icon is tapped', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const HumSafarApp());

    // Tap the search icon
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    // Verify search dialog appears
    expect(find.text('Search Destinations'), findsOneWidget);
    expect(find.text('Where do you want to go?'), findsOneWidget);
  });
}
