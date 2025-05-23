import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:logging_flutter/logging_flutter.dart';

import 'package:oppo/widgets/discovery.dart';
import 'package:oppo/widgets/util.dart';

void main() {
  Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  // Set up in-app log viewing.
  Flogger.init(
    config: const FloggerConfig(
      printClassName: true,
      printMethodName: true,
      showDateTime: true,
      showDebugLogs: true,
    ),
  );
  Flogger.registerListener(
    (record) => LogConsole.add(
      OutputEvent(record.level, [record.printable()]),
      bufferSize: 1000,
    ),
  );
  runApp(const OppoApp());
}

class OppoApp extends StatelessWidget {
  const OppoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    );
    return MaterialApp(
      // Based on
      // https://api.flutter.dev/flutter/material/MaterialApp/title.html, this
      // field should not be used on iOS, but since Apple is giving me hard time
      // about using the name "Oppo", I'm going to change this in case I'm
      // misunderstanding how this is used.
      title: isApple(context) ? appleApplicationName : applicationName,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: const EdgeInsets.fromLTRB(5.0, 20.0, 5.0, 20.0),
          ),
        ),
      ),
      home: const ScanForDevices(),
    );
  }
}
