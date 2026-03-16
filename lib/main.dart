import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:logging_flutter/logging_flutter.dart';

import 'package:oppo/widgets/discovery.dart';
import 'package:oppo/widgets/util.dart';

void main() {
  Logger.root.level = kDebugMode ? .ALL : .INFO;
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
      brightness: .dark,
    );
    return MaterialApp(
      title: applicationName,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: const .fromLTRB(5.0, 20.0, 5.0, 20.0),
          ),
        ),
      ),
      home: const ScanForDevices(),
    );
  }
}
