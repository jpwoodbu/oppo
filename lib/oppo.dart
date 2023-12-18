import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

const int _broadcastPort = 7624;

final _log = Logger('oppo');

void main() async {
  Set<OppoBroadcast> devices = {};
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  final d = Discover();
  // Future.delayed(const Duration(seconds: 12), d.close);
  _log.info('Scanning for Oppo UDP-20X players...');
  await for (final info in d.listen()) {
    _log.info('Found Oppo device at ${info.address.address}');
    d.close();
    devices.add(info);
  }

  if (devices.isNotEmpty) {
    var info = devices.first;
    final device = Device(info.name, info.address, info.port);
    await device.connect();
    await device.powerOff();
    await device.close();
  }
}

class OppoBroadcast {
  InternetAddress address;
  int port;
  String name;

  OppoBroadcast(this.address, this.port, this.name);
}

class Discover {
  RawDatagramSocket? _socket;

  void close() {
    if (_socket != null) _socket!.close();
  }

  Stream<OppoBroadcast> listen() async* {
    _socket =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, _broadcastPort);
    _socket!.writeEventsEnabled = false;
    await for (final event in _socket!) {
      if (event == RawSocketEvent.read) {
        final datagram = _socket!.receive();
        if (datagram == null) continue;
        try {
          yield _parseBroadcast(datagram);
        } catch (e) {
          _log.warning('Failed to parse broadcast packet: $e');
        }
      }
    }
  }
}

OppoBroadcast _parseBroadcast(Datagram datagram) {
  InternetAddress? address;
  int? port;
  String name = '';
  final decoded = ascii.decode(datagram.data);
  for (final line in decoded.split('\n')) {
    if (line.isEmpty) continue;
    final segments = line.split(':');
    final key = segments[0].trim();
    final value = segments[1].trim();
    switch (key) {
      case 'Server IP':
        address = InternetAddress(value);
        break;
      case 'Server Port':
        port = int.parse(value);
        break;
      case 'Server Name':
        name = value;
        break;
      case 'Notify':
        // There's is the broadcast packet prefix. It has no data we need. And
        // it doesn't seem necessary to verify its contents.
        break;
      default:
        _log.warning('Unrecognized line in broadcast packet: $line');
        break;
    }
  }
  if (address == null) throw 'failed to find IP address';
  if (port == null) throw 'failed to find port';
  return OppoBroadcast(address, port, name);
}

class Device {
  String name;
  InternetAddress address;
  int port;
  Socket? _socket;

  Device(this.name, this.address, this.port);

  Future<void> connect() async {
    _socket = await Socket.connect(address, port,
        timeout: const Duration(seconds: 3));
    _log.fine('Connected to device at ${address.address}.');
    _socket?.encoding = const AsciiCodec();
  }

  Future<void> close() async {
    await _socket?.flush();
    await _socket?.close();
  }

  String _formatCommand(String code, String parameters) {
    if (code.length != 3) {
      throw 'Command codes must have a length of 3.';
    }
    if (parameters.isNotEmpty) {
      // A space before any parameters is required.
      parameters = ' $parameters';
    }
    return '#$code$parameters\r';
  }

  Future<void> command(String code, {String parameters = ''}) async {
    if (_socket == null) await connect();
    var c = _formatCommand(code, parameters);
    _log.fine('Sending command: $c');
    _socket?.write(c);
    await _socket?.flush();
    _log.fine('Waiting for a response...');
    await for (final response
        // The API docs say that if there is no response to a command within 10s,
        // the command should be considered lost and can be retransmitted.
        in _socket!.timeout(const Duration(seconds: 10))) {
      _log.info(ascii.decode(response));
      break;
    }
  }

  Future<void> powerToggle() async {
    await command('POW');
  }

  Future<void> powerOn() async {
    await command('PON');
  }

  Future<void> powerOff() async {
    await command('POF');
  }
}
