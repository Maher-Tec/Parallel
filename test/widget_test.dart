// This is a basic Flutter widget test for Parallel app.

import 'package:flutter_test/flutter_test.dart';
import 'package:parallel/main.dart';

void main() {
  testWidgets('Parallel app smoke test', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const ParallelApp());

    // Verify the launch screen shows
    expect(find.text('PARALLEL'), findsOneWidget);
    expect(find.text('Begin'), findsOneWidget);
  });
}
