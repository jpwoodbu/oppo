import 'package:flutter/material.dart';

import 'oppo.dart' as oppo;
import 'util.dart';

const _dialogPadding = EdgeInsets.all(12.0);

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
  const ColorButton({super.key, required this.onPressed, required this.color});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () => addHaptic(onPressed),
      style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(color),
          shape: MaterialStateProperty.all(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius)))),
      child: SizedBox(),
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
        child: Padding(padding: EdgeInsets.all(padding), child: child));
  }
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
                  onPressed: () => addHaptic(device.red), color: Colors.red)),
          TableCellPadded(
              child: ColorButton(
                  onPressed: () => addHaptic(device.green),
                  color: Colors.green)),
          TableCellPadded(
              child: ColorButton(
                  onPressed: () => addHaptic(device.blue), color: Colors.blue)),
          TableCellPadded(
              child: ColorButton(
                  onPressed: () => addHaptic(device.yellow),
                  color: Colors.yellow)),
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
                    VerticalIcon(icon: Icon(Icons.audiotrack), label: 'Audio'),
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
                onPressed: () => addHaptic(device.zoom),
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
              onPressed: () => addHaptic(device.repeat),
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
              onPressed: () => addHaptic(device.outputResolutionCycle),
              child: VerticalIcon(
                  icon: Icon(Icons.aspect_ratio), label: 'Resolution'),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.pageDown),
              child:
                  VerticalIcon(icon: Icon(Icons.arrow_downward), label: 'Page'),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.pageUp),
              child:
                  VerticalIcon(icon: Icon(Icons.arrow_upward), label: 'Page'),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.hdrMenu),
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
              onPressed: () => addHaptic(device.outputResolutionAuto),
              child: VerticalIcon(
                  icon: Icon(Icons.display_settings), label: 'Res auto'),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.threeDimensionalMenu),
              child: VerticalIcon(icon: Icon(Icons.view_in_ar), label: '3D'),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.audioVideoSyncMenu),
              child: VerticalIcon(icon: Icon(Icons.tune), label: 'A/V sync'),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.subtitleShift),
              child: VerticalIcon(
                  icon: Icon(Icons.format_indent_increase), label: 'Sub shift'),
            ),
          ),
        ]),
        TableRow(children: [
          TableCellPadded(
            child: ElevatedButton(
              onPressed: () async {
                final selection = await showDialog<oppo.ZoomRatio>(
                    context: context, builder: (context) => SetZoomRatio());
                if (selection != null) {
                  await device.setZoomRatio(selection);
                }
              },
              child: VerticalIcon(
                  icon: Icon(Icons.zoom_out_map), label: 'Zoom ratio'),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              onPressed: () async {
                final selection = await showDialog<oppo.HdmiResolution>(
                    context: context,
                    builder: (context) => SetHdmiResolution());
                if (selection != null) {
                  await device.setHdmiResolution(selection);
                }
              },
              child: VerticalIcon(
                  // TODO - This label wraps on my phone.
                  icon: Icon(Icons.settings_input_hdmi),
                  label: 'HDMI mode'),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.directPlay),
              child:
                  VerticalIcon(icon: Icon(Icons.table_view), label: 'Program'),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              onPressed: () async {
                final selection = await showDialog<int>(
                    context: context, builder: (context) => SetSubtitleShift());
                if (selection != null) {
                  await device.setVolume(selection);
                }
              },
              child: VerticalIcon(
                  icon: Icon(Icons.margin), label: 'Set sub shift'),
            ),
          ),
        ]),
        TableRow(children: [
          TableCellPadded(
            child: ElevatedButton(
              onPressed: () async {
                final selection = await showDialog<int>(
                    context: context, builder: (context) => SetVolume());
                if (selection != null) {
                  await device.setVolume(selection);
                }
              },
              child: VerticalIcon(
                  icon: Icon(Icons.volume_up), label: 'Set volume'),
            ),
          ),
          // TODO - Maybe make this the long press option on the repeat button.
          // But how to decorate that button to make it clear it can be long
          // pressed?
          TableCellPadded(
            child: ElevatedButton(
              onPressed: () async {
                final selection = await showDialog<oppo.RepeatMode>(
                    context: context, builder: (context) => SetRepeatMode());
                if (selection != null) {
                  await device.setRepeatMode(selection);
                }
              },
              child: VerticalIcon(
                  icon: Icon(Icons.repeat_on), label: 'Repeat mode'),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              onPressed: () async {
                final selection = await showDialog<String>(
                    context: context, builder: (context) => JumpTo());
                if (selection != null) {
                  await device.searchTo(selection);
                }
              },
              child: VerticalIcon(icon: Icon(Icons.schedule), label: 'Jump to'),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              onPressed: () async {
                final selection = await showDialog<int>(
                    context: context, builder: (context) => SetOsdPosition());
                if (selection != null) {
                  await device.setOsdPosition(selection);
                }
              },
              child: VerticalIcon(
                  icon: Icon(Icons.menu_open), label: 'Set OSD position'),
            ),
          ),
        ]),
        TableRow(
          children: [
            TableCellPadded(
              child: ElevatedButton(
                onPressed: () async {
                  final selection = await showDialog<oppo.RepeatMode>(
                      context: context, builder: (context) => SetTimeMode());
                  if (selection != null) {
                    await device.setRepeatMode(selection);
                  }
                },
                child: VerticalIcon(
                    icon: Icon(Icons.hourglass_bottom), label: 'Time mode'),
              ),
            ),
            TableCellPadded(
              child: ElevatedButton(
                onPressed: () async {
                  final selection = await showDialog<oppo.RepeatMode>(
                      context: context, builder: (context) => SetRepeatMode());
                  if (selection != null) {}
                },
                child: VerticalIcon(icon: Icon(Icons.abc), label: 'Dummy'),
              ),
            ),
            TableCellPadded(
              child: ElevatedButton(
                onPressed: () async {
                  final selection = await showDialog<oppo.RepeatMode>(
                      context: context, builder: (context) => SetRepeatMode());
                  if (selection != null) {}
                },
                child: VerticalIcon(icon: Icon(Icons.abc), label: 'Dummy'),
              ),
            ),
            TableCellPadded(
              child: ElevatedButton(
                onPressed: () async {
                  final selection = await showDialog<oppo.RepeatMode>(
                      context: context, builder: (context) => SetRepeatMode());
                  if (selection != null) {}
                },
                child: VerticalIcon(icon: Icon(Icons.abc), label: 'Dummy'),
              ),
            ),
          ],
        ),
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
      title: const Text('HDMI mode'),
      contentPadding: _dialogPadding,
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
      contentPadding: _dialogPadding,
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

class SetVolume extends StatefulWidget {
  const SetVolume({super.key});

  @override
  State<SetVolume> createState() => _SetVolumeState();
}

class _SetVolumeState extends State<SetVolume> {
  final _volumeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _volumeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Set volume (0 - 100)'),
      contentPadding: _dialogPadding,
      children: [
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _volumeController,
            keyboardType: TextInputType.number,
            validator: _validate,
            autofocus: true,
          ),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final volume = int.parse(_volumeController.text);
              addHaptic(() => Navigator.pop(context, volume));
            }
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }

  String? _validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a value';
    }
    final volume = int.tryParse(value);
    if (volume == null || volume < 0 || volume > 100) {
      return 'Please enter a value between 0 and 100';
    }
    return null;
  }
}

class SetRepeatMode extends StatelessWidget {
  const SetRepeatMode({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Repeat mode'),
      contentPadding: _dialogPadding,
      children: oppo.RepeatMode.values
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

class JumpTo extends StatefulWidget {
  const JumpTo({super.key});

  @override
  State<JumpTo> createState() => _JumpToState();
}

class _JumpToState extends State<JumpTo> {
  final _positionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Jump to'),
      contentPadding: _dialogPadding,
      children: [
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _positionController,
            keyboardType: TextInputType.number,
            validator: _validate,
            autofocus: true,
          ),
        ),
        const SizedBox(height: 12.0),
        Wrap(
          children: [
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  addHaptic(
                      () => Navigator.pop(context, _positionController.text));
                }
              },
              child: const Text('Time'),
            ),
            // TODO - implement the other options below.
            TextButton(
              onPressed: () {},
              child: const Text('Title'),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('Chatper'),
            ),
          ],
        ),
        Wrap(
          children: [
            TextButton(
              onPressed: () {},
              child: const Text('Chatper time'),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('Title time'),
            ),
          ],
        ),
      ],
    );
  }

  String? _validate(String? value) {
    if (value == null) {
      return 'Please enter a value';
    }
    if (!oppo.validateClockText(value)) {
      return 'Format like 01:23:45';
    }
    return null;
  }
}

class SetSubtitleShift extends StatefulWidget {
  const SetSubtitleShift({super.key});

  @override
  State<SetSubtitleShift> createState() => _SetSubtitleShiftState();
}

// TODO - Can this be made into a notched slider?
class _SetSubtitleShiftState extends State<SetSubtitleShift> {
  final _shiftController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _shiftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Subtitle shift'),
      contentPadding: _dialogPadding,
      children: [
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _shiftController,
            keyboardType: TextInputType.number,
            validator: (value) => _numberInputValidator(value, -10, 10),
            autofocus: true,
          ),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final shift = int.parse(_shiftController.text);
              addHaptic(() => Navigator.pop(context, shift));
            }
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

String? _numberInputValidator(String? value, [int? min, int? max]) {
  if (value == null || value.isEmpty) {
    return 'Please enter a number';
  }
  final number = int.tryParse(value);
  if (number == null) {
    return 'Please enter a valid number';
  }
  if (min != null && number < min) {
    return 'Enter a number greater than $min';
  }
  if (max != null && number > max) {
    return 'Enter a number less than $max';
  }
  return null;
}

class SetOsdPosition extends StatelessWidget {
  const SetOsdPosition({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('OSD position'),
      contentPadding: _dialogPadding,
      children: [0, 1, 2, 3, 4, 5]
          .map(
            (position) => TextButton(
              onPressed: () =>
                  addHaptic(() => Navigator.pop(context, position)),
              child: PopupSelectionChoice(label: position.toString()),
            ),
          )
          .toList(),
    );
  }
}

class SetTimeMode extends StatelessWidget {
  const SetTimeMode({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Time mode'),
      contentPadding: _dialogPadding,
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
