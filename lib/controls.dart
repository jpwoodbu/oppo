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
                child: IconVertical(icon: Icon(Icons.navigation), label: 'Top'),
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
                child: IconVertical(icon: Icon(Icons.article), label: 'Pop-up'),
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
                    IconVertical(icon: Icon(Icons.emergency), label: 'Option'),
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
                  child: IconVertical(
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
          // TODO - refactor this out to common code with Material app theme.
          shape: MaterialStateProperty.all(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius)))),
      child: SizedBox(),
    );
  }
}

class TableCellPadded extends StatelessWidget {
  final Widget child;
  const TableCellPadded({super.key, required this.child});

  // TODO - make this a module const.
  final double padding = 4.0;

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
              child: IconVertical(
                  icon: Icon(Icons.graphic_eq), label: 'Pure audio'),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.volumeDown),
              child:
                  IconVertical(icon: Icon(Icons.volume_down), label: 'Vol -'),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.volumeUp),
              child: IconVertical(icon: Icon(Icons.volume_up), label: 'Vol +'),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.mute),
              child: IconVertical(icon: Icon(Icons.volume_mute), label: 'Mute'),
            ),
          ),
        ]),
        TableRow(
          children: [
            TableCellPadded(
              child: ElevatedButton(
                onPressed: () => addHaptic(device.audio),
                child:
                    IconVertical(icon: Icon(Icons.audiotrack), label: 'Audio'),
              ),
            ),
            TableCellPadded(
              child: ElevatedButton(
                onPressed: () => addHaptic(device.subtitle),
                child: IconVertical(
                    icon: Icon(Icons.subtitles), label: 'Subtitle'),
              ),
            ),
            TableCellPadded(
              child: ElevatedButton(
                onPressed: () => addHaptic(device.zoom),
                child: IconVertical(icon: Icon(Icons.zoom_in), label: 'Zoom'),
              ),
            ),
            TableCellPadded(
              child: ElevatedButton(
                onPressed: () => addHaptic(device.dim),
                child:
                    IconVertical(icon: Icon(Icons.light_mode), label: 'Dimmer'),
              ),
            ),
          ],
        ),
        TableRow(children: [
          TableCellPadded(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.setup),
              child: IconVertical(icon: Icon(Icons.build), label: 'Setup'),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.repeatAB),
              child: IconVertical(icon: Icon(Icons.undo), label: 'AB Replay'),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.repeat),
              child: IconVertical(icon: Icon(Icons.repeat), label: 'Repeat'),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.pictureAdjustmentMenu),
              child: IconVertical(icon: Icon(Icons.apps), label: 'Pic'),
            ),
          ),
        ]),
        TableRow(children: [
          TableCellPadded(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.outputResolutionCycle),
              child: IconVertical(
                  icon: Icon(Icons.aspect_ratio), label: 'Resolution'),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.pageDown),
              child:
                  IconVertical(icon: Icon(Icons.arrow_downward), label: 'Page'),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.pageUp),
              child:
                  IconVertical(icon: Icon(Icons.arrow_upward), label: 'Page'),
            ),
          ),
          TableCellPadded(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.hdrMenu),
              child: IconVertical(icon: Icon(Icons.hdr_strong), label: 'HDR'),
            ),
          ),
        ]),
      ],
    );
  }
}
