import 'package:flutter_test/flutter_test.dart';

import 'package:oppo/main.dart';

void main() {
  testWidgets('Playing around with the test framework',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const OppoApp());

    expect(find.text('Device discovery'), findsOneWidget);
    expect(find.text('Demo mode'), findsOneWidget);
  });
}
