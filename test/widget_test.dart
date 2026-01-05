import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:angry_battery/main.dart';


void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AngryBatteryApp());

    // Verify that our app title is present
    expect(find.text('Angry Battery'), findsOneWidget);
    
    // Verify initial battery state text (might be 'Unknown' or 'Charging' etc depending on mock)
    // Since we can't easily mock the platform channel in a basic smoke test without more setup,
    // we'll just check for the static UI elements
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });
}
