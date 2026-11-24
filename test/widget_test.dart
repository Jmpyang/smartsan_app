import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartsan_app/main.dart';

void main() {
  testWidgets('SmartSan app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app home page renders key text.
    expect(find.text('Sustainable Sanitization Management'), findsOneWidget);
  });
}
