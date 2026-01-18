// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:planeja_chuva/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PlanejaChuvaApp());

    // Verify that our app builds and shows the title.
    // Note: This might hit issues if dependencies like Hive/PrivacyStore aren't mocked,
    // but this fixes the immediate compilation error 'MyApp not defined'.
    expect(find.text('Planeja Chuva'), findsOneWidget);
  });
}
