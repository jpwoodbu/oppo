import 'package:flutter/material.dart';

import 'oppo.dart' as oppo;
import 'util.dart';

class HomeRow extends StatelessWidget {
  final oppo.Device device;
  const HomeRow(this.device, {super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        IconButton(
          onPressed: () => addHaptic(device.home),
          icon: const Icon(
            Icons.home,
            semanticLabel: 'home',
          ),
        ),
        TextButton.icon(
          onPressed: () => addHaptic(device.goto),
          icon: const Icon(Icons.arrow_downward),
          label: const Text('Goto'),
        ),
        TextButton.icon(
          onPressed: () => addHaptic(device.clear),
          icon: Icon(Icons.clear),
          label: Text('Clear'),
        ),
        IconButton(
          onPressed: () => addHaptic(device.osd),
          icon: const Icon(
            Icons.info,
            semanticLabel: 'info',
          ),
        ),
        IconButton(
          onPressed: () => addHaptic(device.infoDetailed),
          icon: const Icon(
            Icons.query_stats,
            semanticLabel: 'detailed info',
          ),
        ),
      ],
    );
  }
}

class Arrows extends StatelessWidget {
  final oppo.Device device;
  const Arrows(this.device, {super.key});

  @override
  Widget build(BuildContext context) {
    const iconSize = 100.0;
    return Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      children: <TableRow>[
        TableRow(
          children: [
            TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: ElevatedButton(
                onPressed: () => addHaptic(device.topMenu),
                child: VerticalIcon(icon: Icon(Icons.navigation), label: 'Top'),
              ),
            ),
            IconButton(
                onPressed: () => addHaptic(device.arrowUp),
                icon: Icon(
                  Icons.keyboard_arrow_up,
                  size: iconSize,
                  semanticLabel: 'up',
                )),
            TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: ElevatedButton(
                onPressed: () => addHaptic(device.popupMenu),
                child: VerticalIcon(icon: Icon(Icons.article), label: 'Pop-up'),
              ),
            ),
          ],
        ),
        TableRow(
          children: [
            IconButton(
                onPressed: () => addHaptic(device.arrowLeft),
                icon: Icon(
                  Icons.keyboard_arrow_left,
                  size: iconSize,
                  semanticLabel: 'left',
                )),
            IconButton(
                onPressed: () => addHaptic(device.enter),
                icon: Icon(
                  Icons.circle_outlined,
                  size: iconSize,
                  semanticLabel: 'enter',
                )),
            IconButton(
                onPressed: () => addHaptic(device.arrowRight),
                icon: Icon(
                  Icons.keyboard_arrow_right,
                  size: iconSize,
                  semanticLabel: 'right',
                )),
          ],
        ),
        TableRow(
          children: [
            TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: ElevatedButton(
                onPressed: () => addHaptic(device.option),
                child:
                    VerticalIcon(icon: Icon(Icons.emergency), label: 'Option'),
              ),
            ),
            IconButton(
                onPressed: () => addHaptic(device.arrowDown),
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  size: iconSize,
                  semanticLabel: 'down',
                )),
            TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: ElevatedButton(
                  onPressed: () => addHaptic(device.returnToPrevious),
                  child: VerticalIcon(
                    icon: Icon(Icons.arrow_back),
                    label: 'Return',
                  )),
            ),
          ],
        ),
      ],
    );
  }
}

class PlayControls extends StatelessWidget {
  final oppo.Device device;
  const PlayControls(this.device, {super.key});

  @override
  Widget build(BuildContext context) {
    const iconSize = 85.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
            onPressed: () => addHaptic(device.stop),
            icon: Icon(
              Icons.stop_circle,
              size: iconSize,
              semanticLabel: 'stop',
            )),
        IconButton(
            onPressed: () => addHaptic(device.play),
            icon: Icon(
              Icons.play_arrow,
              size: iconSize,
              semanticLabel: 'play',
            )),
        IconButton(
            onPressed: () => addHaptic(device.pause),
            icon: Icon(
              Icons.pause,
              size: iconSize,
              semanticLabel: 'pause',
            )),
      ],
    );
  }
}

class PositionControls extends StatelessWidget {
  final oppo.Device device;
  const PositionControls(this.device, {super.key});

  @override
  Widget build(BuildContext context) {
    const iconSize = 65.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
            onPressed: () => addHaptic(device.previous),
            icon: Icon(
              Icons.skip_previous,
              size: iconSize,
              semanticLabel: 'previous',
            )),
        IconButton(
            onPressed: () => addHaptic(device.reverse),
            icon: Icon(
              Icons.fast_rewind,
              size: iconSize,
              semanticLabel: 'scan reverse',
            )),
        IconButton(
            onPressed: () => addHaptic(device.forward),
            icon: Icon(
              Icons.fast_forward,
              size: iconSize,
              semanticLabel: 'scan forward',
            )),
        IconButton(
            onPressed: () => addHaptic(device.next),
            icon: Icon(
              Icons.skip_next,
              size: iconSize,
              semanticLabel: 'next',
            )),
      ],
    );
  }
}

class ColorButton extends StatelessWidget {
  final Function onPressed;
  final Color color;
  final String semanticLabel;
  const ColorButton(
      {super.key,
      required this.onPressed,
      required this.color,
      required this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: FilledButton(
        onPressed: () => addHaptic(onPressed),
        style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(color),
            shape: MaterialStateProperty.all(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius)))),
        child: const SizedBox(),
      ),
    );
  }
}

class TableCellPadded extends StatelessWidget {
  final Widget child;
  final double padding = 4.0;
  const TableCellPadded({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.intrinsicHeight,
      child: Padding(padding: EdgeInsets.all(padding), child: child),
    );
  }
}

ButtonStyle dialogButtonStyle(BuildContext context) {
  return ButtonStyle(
    backgroundColor:
        MaterialStatePropertyAll(Theme.of(context).colorScheme.onSecondary),
    foregroundColor:
        MaterialStatePropertyAll(Theme.of(context).colorScheme.secondary),
  );
}

ButtonStyle alertDialogButtonStyle(BuildContext context) {
  return ButtonStyle(
    backgroundColor:
        MaterialStatePropertyAll(Theme.of(context).colorScheme.onTertiary),
    foregroundColor:
        MaterialStatePropertyAll(Theme.of(context).colorScheme.tertiary),
  );
}

class BottomGrid extends StatelessWidget {
  final oppo.Device device;
  const BottomGrid(this.device, {super.key});

  @override
  Widget build(BuildContext context) {
    return Table(
      children: <TableRow>[
        TableRow(children: [
          TableCellPadded(
            child: ColorButton(
              onPressed: () => addHaptic(device.red),
              color: Colors.red,
              semanticLabel: 'red button',
            ),
          ),
          TableCellPadded(
            child: ColorButton(
              onPressed: () => addHaptic(device.green),
              color: Colors.green,
              semanticLabel: 'green button',
            ),
          ),
          TableCellPadded(
            child: ColorButton(
              onPressed: () => addHaptic(device.blue),
              color: Colors.blue,
              semanticLabel: 'blue button',
            ),
          ),
          TableCellPadded(
            child: ColorButton(
              onPressed: () => addHaptic(device.yellow),
              color: Colors.yellow,
              semanticLabel: 'yellow button',
            ),
          ),
        ]),
        TableRow(children: [
          TableCellPadded(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.pureAudio),
              child: VerticalIcon(
                  icon: Icon(Icons.graphic_eq), label: 'Pure audio'),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.volumeDown),
              child:
                  VerticalIcon(icon: Icon(Icons.volume_down), label: 'Vol -'),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.volumeUp),
              child: VerticalIcon(icon: Icon(Icons.volume_up), label: 'Vol +'),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.mute),
              child: VerticalIcon(icon: Icon(Icons.volume_mute), label: 'Mute'),
            ),
          ),
        ]),
        TableRow(
          children: [
            TableCellPadded(
              child: ElevatedButton(
                onPressed: () => addHaptic(device.audio),
                child:
                    VerticalIcon(icon: Icon(Icons.animation), label: 'Audio'),
              ),
            ),
            TableCellPadded(
              child: ElevatedButton(
                onPressed: () => addHaptic(device.subtitle),
                child: VerticalIcon(
                    icon: Icon(Icons.subtitles), label: 'Subtitle'),
              ),
            ),
            TableCellPadded(
              child: ElevatedButton(
                style: dialogButtonStyle(context),
                onPressed: () async {
                  final selection = await showDialog<oppo.ZoomRatio>(
                      context: context, builder: (context) => SetZoomRatio());
                  if (selection != null) {
                    await device.setZoomRatio(selection);
                  }
                },
                child: VerticalIcon(icon: Icon(Icons.zoom_in), label: 'Zoom'),
              ),
            ),
            TableCellPadded(
              child: ElevatedButton(
                onPressed: () => addHaptic(device.dim),
                child:
                    VerticalIcon(icon: Icon(Icons.light_mode), label: 'Dimmer'),
              ),
            ),
          ],
        ),
        TableRow(children: [
          TableCellPadded(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.setup),
              child: VerticalIcon(icon: Icon(Icons.build), label: 'Setup'),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.repeatAB),
              child: VerticalIcon(icon: Icon(Icons.undo), label: 'AB Replay'),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              style: dialogButtonStyle(context),
              onPressed: () async {
                final selection = await showDialog<oppo.RepeatMode>(
                    context: context, builder: (context) => SetRepeatMode());
                if (selection != null) {
                  await device.setRepeatMode(selection);
                }
              },
              child: VerticalIcon(icon: Icon(Icons.repeat), label: 'Repeat'),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.pictureAdjustmentMenu),
              child: VerticalIcon(icon: Icon(Icons.apps), label: 'Pic'),
            ),
          ),
        ]),
        TableRow(children: [
          TableCellPadded(
            child: ElevatedButton(
              style: dialogButtonStyle(context),
              onPressed: () async {
                final selection = await showDialog<oppo.HdmiResolution>(
                    context: context,
                    builder: (context) => SetHdmiResolution());
                if (selection != null) {
                  await device.setHdmiResolution(selection);
                }
              },
              child: VerticalIcon(
                  icon: Icon(Icons.aspect_ratio), label: 'Resolution'),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.pageDown),
              child: VerticalIcon(
                  icon: Icon(Icons.keyboard_double_arrow_down), label: 'Page'),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.pageUp),
              child: VerticalIcon(
                  icon: Icon(Icons.keyboard_double_arrow_up), label: 'Page'),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              style: dialogButtonStyle(context),
              onPressed: () async {
                final selection = await showDialog<oppo.HdrSetting>(
                    context: context, builder: (context) => SetHdrMode());
                if (selection != null) {
                  await device.setHdrSetting(selection);
                }
              },
              child: VerticalIcon(icon: Icon(Icons.hdr_strong), label: 'HDR'),
            ),
          ),
        ]),
      ],
    );
  }
}

class ExtraControls extends StatelessWidget {
  final oppo.Device device;
  const ExtraControls(this.device, {super.key});

  @override
  Widget build(BuildContext context) {
    return Table(
      children: [
        TableRow(children: [
          TableCellPadded(
            child: ElevatedButton(
              style: alertDialogButtonStyle(context),
              onPressed: () async {
                final selection = await showDialog<bool?>(
                    context: context, builder: (context) => PowerOff());
                if (selection != null && selection == true) {
                  await device.powerOff();
                }
              },
              child: VerticalIcon(
                  icon: Icon(Icons.power_settings_new), label: 'Power'),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              style: dialogButtonStyle(context),
              onPressed: () async {
                final selection = await showDialog<oppo.App>(
                    context: context, builder: (context) => SelectApp());
                if (selection != null) {
                  await device.runApp(selection);
                }
              },
              child: VerticalIcon(icon: Icon(Icons.apps), label: 'Apps'),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              style: dialogButtonStyle(context),
              onPressed: () async {
                final selection = await showDialog<oppo.InputSource>(
                    context: context, builder: (context) => SetInputSource());
                if (selection != null) {
                  await device.setInputSource(selection);
                }
              },
              child: VerticalIcon(icon: Icon(Icons.input), label: 'Input'),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              style: alertDialogButtonStyle(context),
              onPressed: () async {
                final selection = await showDialog<bool?>(
                    context: context, builder: (context) => ToggleTray());
                if (selection != null && selection == true) {
                  await device.trayToggle();
                }
              },
              child: VerticalIcon(icon: Icon(Icons.eject), label: 'Open'),
            ),
          ),
        ]),
        TableRow(children: [
          TableCellPadded(
            child: ElevatedButton(
              style: dialogButtonStyle(context),
              onPressed: () async {
                final selection = await showDialog<oppo.TimeInformation>(
                    context: context, builder: (context) => SetTimeMode());
                if (selection != null) {
                  await device.setTimeInformationDisplay(selection);
                }
              },
              child: VerticalIcon(
                  icon: Icon(Icons.hourglass_bottom), label: 'Time'),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              style: dialogButtonStyle(context),
              onPressed: () async {
                final selection = await showDialog<int>(
                    context: context, builder: (context) => SetSubtitleShift());
                if (selection != null) {
                  await device.setSubtitleShift(selection);
                }
              },
              child: VerticalIcon(
                  icon: Icon(Icons.format_indent_increase),
                  label: 'Subtitle shift',
                  small: true),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              style: dialogButtonStyle(context),
              onPressed: () async {
                final selection = await showDialog<int>(
                    context: context, builder: (context) => SetOsdPosition());
                if (selection != null) {
                  await device.setOsdPosition(selection);
                }
              },
              child: VerticalIcon(icon: Icon(Icons.margin), label: 'OSD'),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.audioVideoSyncMenu),
              child: VerticalIcon(icon: Icon(Icons.tune), label: 'A/V sync'),
            ),
          ),
        ]),
        TableRow(children: [
          TableCellPadded(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.threeDimensionalMenu),
              child: VerticalIcon(icon: Icon(Icons.view_in_ar), label: '3D'),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              style: dialogButtonStyle(context),
              onPressed: () async {
                final selection = await showDialog<oppo.ScreenSaverSetting>(
                    context: context, builder: (context) => SetScreenSaver());
                if (selection != null) {
                  await device.setScreenSaver(selection);
                }
              },
              child: VerticalIcon(
                  icon: Icon(Icons.tv), label: 'Screensaver', small: true),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              style: dialogButtonStyle(context),
              onPressed: () async {
                final selection = await showDialog<oppo.SacdPriority>(
                    context: context, builder: (context) => SetSacdPriority());
                if (selection != null) {
                  await device.setSacdPriority(selection);
                }
              },
              child: VerticalIcon(
                  icon: Icon(Icons.album), label: 'SACD priority', small: true),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              style: dialogButtonStyle(context),
              onPressed: () async {
                final selection = await showDialog<oppo.SacdOutputMode>(
                    context: context,
                    builder: (context) => SetSacdOutputMode());
                if (selection != null) {
                  await device.setSacdOutputMode(selection);
                }
              },
              child: VerticalIcon(
                  icon: Icon(Icons.transform),
                  label: 'SACD output',
                  small: true),
            ),
          ),
        ]),
      ],
    );
  }
}

class PopupSelectionChoice extends StatelessWidget {
  final String label;
  const PopupSelectionChoice({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label),
    );
  }
}

class SetHdmiResolution extends StatelessWidget {
  const SetHdmiResolution({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('HDMI resolution'),
      contentPadding: dialogPadding,
      children: oppo.HdmiResolution.values
          .map(
            (mode) => TextButton(
              onPressed: () => addHaptic(() => Navigator.pop(context, mode)),
              child: PopupSelectionChoice(label: mode.displayName),
            ),
          )
          .toList(),
    );
  }
}

class SetZoomRatio extends StatelessWidget {
  const SetZoomRatio({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Zoom ratio'),
      contentPadding: dialogPadding,
      children: oppo.ZoomRatio.values
          .map(
            (mode) => TextButton(
              onPressed: () => addHaptic(() => Navigator.pop(context, mode)),
              child: PopupSelectionChoice(label: mode.displayName),
            ),
          )
          .toList(),
    );
  }
}

class SetRepeatMode extends StatelessWidget {
  const SetRepeatMode({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Repeat mode'),
      contentPadding: dialogPadding,
      children: oppo.RepeatMode.values
          // RepeatMode.one is not available for the SRP command.
          .where((element) => element != oppo.RepeatMode.one)
          .map(
            (mode) => TextButton(
              onPressed: () => addHaptic(() => Navigator.pop(context, mode)),
              child: PopupSelectionChoice(label: mode.displayName),
            ),
          )
          .toList(),
    );
  }
}

class SetSubtitleShift extends StatelessWidget {
  const SetSubtitleShift({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Subtitle shift'),
      children: [
        Wrap(
            children: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
                .map(
                  (shift) => IntrinsicWidth(
                    child: TextButton(
                      onPressed: () =>
                          addHaptic(() => Navigator.pop(context, shift)),
                      child: Text(shift.toString()),
                    ),
                  ),
                )
                .toList())
      ],
    );
  }
}

class SetOsdPosition extends StatelessWidget {
  const SetOsdPosition({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('OSD margin'),
      contentPadding: dialogPadding,
      children: [Wrap(children: [0, 1, 2, 3, 4, 5]
          .map(
            (position) => IntrinsicWidth(
              child: TextButton(
                onPressed: () =>
                    addHaptic(() => Navigator.pop(context, position)),
                child: Text(position.toString()),
              ),
            ),
          )
          .toList())],
    );
  }
}

class SetTimeMode extends StatelessWidget {
  const SetTimeMode({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Time mode'),
      contentPadding: dialogPadding,
      children: oppo.TimeInformation.values
          .map(
            (mode) => TextButton(
              onPressed: () => addHaptic(() => Navigator.pop(context, mode)),
              child: PopupSelectionChoice(label: mode.displayName),
            ),
          )
          .toList(),
    );
  }
}

class SetHdrMode extends StatelessWidget {
  const SetHdrMode({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('HDR mode'),
      contentPadding: dialogPadding,
      children: oppo.HdrSetting.values
          .map(
            (mode) => TextButton(
              onPressed: () => addHaptic(() => Navigator.pop(context, mode)),
              child: PopupSelectionChoice(label: mode.displayName),
            ),
          )
          .toList(),
    );
  }
}

class SetInputSource extends StatelessWidget {
  const SetInputSource({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Input source'),
      contentPadding: dialogPadding,
      children: oppo.InputSource.values
          .map(
            (mode) => TextButton(
              onPressed: () => addHaptic(() => Navigator.pop(context, mode)),
              child: PopupSelectionChoice(label: mode.displayName),
            ),
          )
          .toList(),
    );
  }
}

class SetScreenSaver extends StatelessWidget {
  const SetScreenSaver({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Screensaver'),
      contentPadding: dialogPadding,
      children: oppo.ScreenSaverSetting.values
          .map(
            (mode) => TextButton(
              onPressed: () => addHaptic(() => Navigator.pop(context, mode)),
              child: PopupSelectionChoice(label: mode.displayName),
            ),
          )
          .toList(),
    );
  }
}

class SelectApp extends StatelessWidget {
  const SelectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Apps'),
      contentPadding: dialogPadding,
      children: oppo.App.values
          .map(
            (mode) => TextButton(
              onPressed: () => addHaptic(() => Navigator.pop(context, mode)),
              child: PopupSelectionChoice(label: mode.displayName),
            ),
          )
          .toList(),
    );
  }
}

class SetSacdPriority extends StatelessWidget {
  const SetSacdPriority({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('SACD priority'),
      contentPadding: dialogPadding,
      children: oppo.SacdPriority.values
          .map(
            (mode) => TextButton(
              onPressed: () => addHaptic(() => Navigator.pop(context, mode)),
              child: PopupSelectionChoice(label: mode.displayName),
            ),
          )
          .toList(),
    );
  }
}

class SetSacdOutputMode extends StatelessWidget {
  const SetSacdOutputMode({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('SACD output mode'),
      contentPadding: dialogPadding,
      children: oppo.SacdOutputMode.values
          .map(
            (mode) => TextButton(
              onPressed: () => addHaptic(() => Navigator.pop(context, mode)),
              child: PopupSelectionChoice(label: mode.displayName),
            ),
          )
          .toList(),
    );
  }
}

class SetForwardPlaybackSpeed extends StatelessWidget {
  const SetForwardPlaybackSpeed({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Forward playback speed'),
      contentPadding: dialogPadding,
      children: oppo.PlaybackSpeed.values
          .map(
            (mode) => TextButton(
              onPressed: () => addHaptic(() => Navigator.pop(context, mode)),
              child: PopupSelectionChoice(label: mode.typeCode),
            ),
          )
          .toList(),
    );
  }
}

class SetReversePlaybackSpeed extends StatelessWidget {
  const SetReversePlaybackSpeed({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Reverse playback speed'),
      contentPadding: dialogPadding,
      children: oppo.PlaybackSpeed.values
          .map(
            (mode) => TextButton(
              onPressed: () => addHaptic(() => Navigator.pop(context, mode)),
              child: PopupSelectionChoice(label: mode.typeCode),
            ),
          )
          .toList(),
    );
  }
}

class PowerOff extends StatelessWidget {
  const PowerOff({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: const Text('Are you sure you want to power off the player?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            addHaptic(() => Navigator.pop(context, true));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Waiting for power off signal...')));
          },
          child: const Text('Proceed'),
        ),
      ],
    );
  }
}

class ToggleTray extends StatelessWidget {
  const ToggleTray({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: const Text('Are you sure you want to toggle the tray?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => addHaptic(() => Navigator.pop(context, true)),
          child: const Text('Proceed'),
        ),
      ],
    );
  }
}
