import 'package:flutter/material.dart';

import 'oppo.dart' as oppo;
import 'util.dart';

class NumberPadButton extends StatelessWidget {
  final Function onPressed;
  final Widget child;
  const NumberPadButton(
      {super.key, required this.onPressed, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: ElevatedButton(
        onPressed: () => addHaptic(onPressed),
        child: child,
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
  const NumberPad(this.device, {super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Table(
          defaultColumnWidth: IntrinsicColumnWidth(),
          children: [
            TableRow(
              children: [
                // TODO - Make a reusable version of this button since it's used
                // in >1 places.
                NumberPadButton(
                  onPressed: () => addHaptic(device.goto),
                  child: VerticalIcon(
                    icon: Icon(Icons.arrow_downward),
                    label: 'Goto',
                  ),
                ),
                NumberPadButton(
                  onPressed: () => addHaptic(device.clear),
                  child: VerticalIcon(icon: Icon(Icons.clear), label: 'Clear'),
                ),
                IconButton(
                    alignment: Alignment.topRight,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close)),
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
                  child: VerticalIcon(
                    icon: Icon(Icons.arrow_back),
                    label: 'Return',
                  ),
                ),
                NumberButton(onPressed: device.number0, label: '0'),
                NumberPadButton(
                  onPressed: device.enter,
                  child: VerticalIcon(
                    icon: Icon(Icons.keyboard_return),
                    label: 'Enter',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
