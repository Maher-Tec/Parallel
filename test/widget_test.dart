// This is a basic Flutter widget test for Parallel app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holmi/screens/launch_screen.dart';

void main() {
  testWidgets('Launch screen shows Holmi entry points', (
    WidgetTester tester,
  ) async {
    // Wrap LaunchScreen in MaterialApp for proper rendering
    await tester.pumpWidget(const MaterialApp(home: LaunchScreen()));

    // Pump to let widgets build
    await tester.pump();

    // Verify the launch screen content
    expect(find.text('UFUQ'), findsOneWidget);
    expect(find.text('Begin'), findsOneWidget);
    expect(find.text('My Dreams'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
  });
}
