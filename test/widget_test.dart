import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oppo/main.dart';
import 'package:oppo/preferences.dart';

void main() {
  testWidgets('Playing around with the test framework',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = Preferences(await SharedPreferences.getInstance());

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      Provider<Preferences>.value(
        value: preferences,
        child: const OppoApp(),
      ),
    );

    expect(find.text('Device discovery'), findsOneWidget);
    expect(find.text('Demo mode'), findsOneWidget);
  });
}
