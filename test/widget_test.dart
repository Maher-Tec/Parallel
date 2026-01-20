// This is a basic Flutter widget test for Parallel app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parallel/screens/launch_screen.dart';

void main() {
  testWidgets('Launch screen shows Begin button', (WidgetTester tester) async {
    // Wrap LaunchScreen in MaterialApp for proper rendering
    await tester.pumpWidget(
      const MaterialApp(
        home: LaunchScreen(),
      ),
    );
    
    // Pump to let widgets build
    await tester.pump();

    // Verify the launch screen content
    expect(find.text('PARALLEL'), findsOneWidget);
    expect(find.text('Begin'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
  });
}
