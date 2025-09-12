import 'package:flutter/material.dart';
import 'package:logging_flutter/logging_flutter.dart';
import 'package:provider/provider.dart';

import 'package:oppo/device_changes.dart';
import 'package:oppo/widgets/controls.dart';
import 'package:oppo/widgets/discovery.dart';
import 'package:oppo/widgets/display.dart';
import 'package:oppo/widgets/info.dart';
import 'package:oppo/widgets/number_pad.dart';
import 'package:oppo/widgets/position.dart';
import 'package:oppo/widgets/track_info.dart';
import 'package:oppo/widgets/util.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final device = context.read<DeviceChanges>().device;
    return FutureBuilder<void>(
      // Show the waiting message for at least 1s while we perform the
      // background work.
      future: Future.wait(
          [Future.delayed(const Duration(seconds: 1)), device.engage()]),
      builder: (_, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return const PowerUpError();
          }
          return const MainView();
        } else {
          return const Scaffold(
            body: Center(
              child: Text('Powering on and setting up communication...'),
            ),
          );
        }
      },
    );
  }
}

class MainView extends StatelessWidget {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Position(),
        centerTitle: true,
        titleSpacing: 0.0,
        actions: const [NumberPadIcon()],
      ),
      drawer: const Drawer(),
      body: const Switch(),
    );
  }
}

class Switch extends StatelessWidget {
  const Switch({super.key});

  @override
  Widget build(BuildContext context) {
    final powered =
        context.select((DeviceChanges d) => d.device.powered ?? false);
    return powered ? const Buttons() : const NotPoweredOn();
  }
}

class Drawer extends StatelessWidget {
  final appIcon = const Image(
    image: AssetImage('assets/hdpi_app_icon.png'),
    height: 72.0,
    width: 72.0,
  );

  const Drawer({super.key});

  @override
  Widget build(BuildContext context) {
    final smallText = Theme.of(context).textTheme.bodySmall;
    final powered =
        context.select((DeviceChanges d) => d.device.powered ?? false);
    final device = context.read<DeviceChanges>().device;
    return NavigationDrawer(
      children: [
        DrawerHeader(
          child: Row(
            children: [
              appIcon,
              const SizedBox(width: 8.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(isApple(context)
                      ? appleApplicationName
                      : applicationName),
                  Text(device.name, style: smallText),
                  Text('Firmware: ${device.firmwareVersion ?? 'unknown'}',
                      style: smallText),
                ],
              ),
            ],
          ),
        ),
        if (powered)
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Fetch track metadata'),
            onTap: () {
              Navigator.pop(context); // close the drawer
              showDialog(
                context: context,
                builder: (_) => TrackMetadata(device: device),
              );
            },
          ),
        ListTile(
          leading: const Icon(Icons.sensors),
          title: const Text('Scan for players'),
          onTap: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const ScanForDevices()),
              (Route<dynamic> route) => false,
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.bug_report),
          title: const Text('Known issues'),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => const KnownIssues())),
        ),
        // Debug logs reference "oppo", which Apple doesn't like.
        if (!isApple(context))
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('Debug logs'),
            onTap: () => LogConsole.open(context),
          ),
        ListTile(
          leading: const Icon(Icons.article),
          title: const Text('Licenses'),
          onTap: () => showLicensePage(
            context: context,
            applicationIcon: appIcon,
            applicationName:
                isApple(context) ? appleApplicationName : applicationName,
          ),
        ),
      ],
    );
  }
}

class PowerUpError extends StatelessWidget {
  const PowerUpError({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Error while waiting on device to power up.'),
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const ScanForDevices()),
                      (Route<dynamic> route) => false);
                },
                child: const Text('Scan for players'),
              ),
              // Debug logs reference "oppo", which Apple doesn't like.
              if (!isApple(context))
                TextButton(
                  onPressed: () => LogConsole.open(context),
                  child: const Text('Debug logs'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class Buttons extends StatelessWidget {
  const Buttons({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'scrollable area with information display and '
          'remote control buttons',
      child: Padding(
        padding: mainViewPadding,
        child: ListView(
          children: const [
            Display(),
            SizedBox(height: 4.0),
            Divider(),
            HomeRow(),
            Arrows(),
            PlayControls(),
            PositionControls(),
            BottomGrid(),
            Divider(),
            ExtraControls(),
            SizedBox(height: 4.0),
          ],
        ),
      ),
    );
  }
}

class NotPoweredOn extends StatelessWidget {
  const NotPoweredOn({super.key});

  @override
  Widget build(BuildContext context) {
    final device = context.read<DeviceChanges>().device;
    return Padding(
      padding: mainViewPadding,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Power on to use the remote.'),
            const SizedBox(height: 10.0),
            IconButton(
              onPressed: () {
                addHaptic(device.powerOn);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Waiting for power on signal...')));
              },
              icon: const Icon(
                Icons.power_settings_new,
                color: Colors.amber,
                semanticLabel: 'Toggle power',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
