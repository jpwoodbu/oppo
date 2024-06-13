import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:logging_flutter/logging_flutter.dart';

import 'widgets/connect.dart';
import 'widgets/discovery.dart';
import 'widgets/util.dart';

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
      title: 'Oppo Remote',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        // This is a workaround for
        // https://github.com/flutter/flutter/issues/148849. When upgrading
        // Flutter from 3.19.6, the backgrounds of dialogs were too dark and had
        // low contrast with the dimmed background. Note that the default
        // background color for dialogs is supposed to be surfaceContainerHigh,
        // but I preferred surfaceContainer when testing this workaround.
        dialogTheme: DialogTheme(
          backgroundColor: colorScheme.surfaceContainer,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: const EdgeInsets.fromLTRB(5.0, 20.0, 5.0, 20.0),
          ),
        ),
      ),
      initialRoute: ScanForDevices.routeName,
      routes: {
        ScanForDevices.routeName: (context) => const ScanForDevices(),
        ConnectWrapper.routeName: (context) => const ConnectWrapper(),
      },
    );
  }
}
