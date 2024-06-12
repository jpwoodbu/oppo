import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'device_changes.dart';
import 'oppo.dart' as oppo;
import 'util.dart';

class NumberPadIcon extends StatelessWidget {
  const NumberPadIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final powered =
        context.select((DeviceChanges d) => d.device.powered) ?? false;
    final device = context.read<DeviceChanges>().device;
    return powered
        ? IconButton(
            onPressed: () {
              showDialog(
                context: context,
                // Passing device is needed since Dialogs appear to get a
                // context from way up in the tree near the MaterialApp widget
                // so none of its ancestors have a provider with a
                // [oppo.Device]. See
                // https://stackoverflow.com/questions/72925944/flutter-showdialog-not-able-to-access-the-provider-from-context.
                builder: (_) => NumberPad(device: device),
              );
            },
            icon: const Icon(
              Icons.dialpad,
              semanticLabel: 'open number pad',
            ),
          )
        : const SizedBox();
  }
}

class NumberPadButton extends StatelessWidget {
  final Function onPressed;
  final Widget child;
  const NumberPadButton(
      {super.key, required this.onPressed, required this.child});

  @override
  Widget build(BuildContext context) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.intrinsicHeight,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          onPressed: () => addHaptic(onPressed),
          child: child,
        ),
      ),
    );
  }
}

class NumberButton extends StatelessWidget {
  final Function onPressed;
  final String label;
  const NumberButton({super.key, required this.onPressed, required this.label});

  @override
  Widget build(BuildContext context) {
    return NumberPadButton(
      onPressed: onPressed,
      child: Text(label, style: Theme.of(context).textTheme.headlineLarge),
    );
  }
}

class NumberPad extends StatelessWidget {
  final oppo.Device device;
  const NumberPad({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'number pad buttons',
      child: Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            children: [
              TableRow(
                children: [
                  NumberPadButton(
                    onPressed: () => addHaptic(device.goto),
                    child: const VerticalIcon(
                      icon: Icon(Icons.arrow_downward),
                      label: 'Goto',
                    ),
                  ),
                  NumberPadButton(
                    onPressed: () => addHaptic(device.clear),
                    child: const VerticalIcon(
                        icon: Icon(Icons.clear), label: 'Clear'),
                  ),
                  IconButton(
                      alignment: Alignment.topRight,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        semanticLabel: 'close number pad',
                      )),
                ],
              ),
              TableRow(
                children: [
                  NumberButton(onPressed: device.number1, label: '1'),
                  NumberButton(onPressed: device.number2, label: '2'),
                  NumberButton(onPressed: device.number2, label: '3'),
                ],
              ),
              TableRow(
                children: [
                  NumberButton(onPressed: device.number4, label: '4'),
                  NumberButton(onPressed: device.number5, label: '5'),
                  NumberButton(onPressed: device.number6, label: '6'),
                ],
              ),
              TableRow(
                children: [
                  NumberButton(onPressed: device.number7, label: '7'),
                  NumberButton(onPressed: device.number8, label: '8'),
                  NumberButton(onPressed: device.number9, label: '9'),
                ],
              ),
              TableRow(
                children: [
                  NumberPadButton(
                    onPressed: device.returnToPrevious,
                    child: const VerticalIcon(
                      icon: Icon(Icons.arrow_back),
                      label: 'Return',
                    ),
                  ),
                  NumberButton(onPressed: device.number0, label: '0'),
                  NumberPadButton(
                    onPressed: device.enter,
                    child: const VerticalIcon(
                      icon: Icon(Icons.keyboard_return),
                      label: 'Enter',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
