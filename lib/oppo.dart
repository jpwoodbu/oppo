import 'dart:async';
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
  // Uncomment if you want to exercise the discovery feature. Also comment out
  // the devices.add() call below. While testing on WSL, it's convenient to skip
  // discovery.
  /*
  final d = Discover();
  _log.info('Scanning for Oppo UDP-20X players...');
  await for (final info in d.listen()) {
    _log.info('Found Oppo device at ${info.address.address}');
    d.close();
    devices.add(info);
  }
  */
  devices.add(OppoBroadcast(InternetAddress('192.168.86.149'), 23, 'unknown'));

  if (devices.isNotEmpty) {
    var info = devices.first;
    final device = Device(info.name, info.address, info.port);
    await device.connect();
    device.listen();
    await device.powerOn();
    // TODO - serialize command / response pairs.
    device.setVerboseMode(VerboseMode.detailed);
    // device.close();
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

enum VerboseMode { off, major, detailed }

class Device {
  final String name;
  final InternetAddress address;
  final int port;
  // TODO - Why do I get a warning if I make this var private?
  bool pendingResponse = false;
  Socket? _socket;

  Device(this.name, this.address, this.port);

  Future<void> connect() async {
    _socket = await Socket.connect(address, port,
        timeout: const Duration(seconds: 3));
    _log.info('Connected to device at ${address.address}.');
    final socket = _socket;
    if (socket != null) {
      socket.encoding = const AsciiCodec();
      socket.setOption(SocketOption.tcpNoDelay, true);
    }
  }

  void listen() async {
    if (_socket == null) connect();
    final socket = _socket;
    if (socket != null) {
      _log.info('Listening for inbound packets.');
      await for (final data in socket) {
        final decoded = ascii.decode(data);
        _log.info('Listener received: $decoded');
        if (decoded.startsWith('@U')) {
          _log.fine('Got an update message: $decoded');
        } else {
          _parseResponse(decoded);
        }
      }
    }
  }

  void _parseResponse(String response) {
    if (!response.startsWith('@')) {
      throw 'Unable to parse response. The "@" prefix is missing: $response';
    }
    final parts = response.split(' ');
    final resultCode = parts[0].trim();
    if (resultCode == '@ER') {
      _log.severe('Got an error response: $response');
    } else if (resultCode != '@OK') {
      _log.severe(
          'Unable to parse response. Unexpected result code in: $response');
    }
    _log.info('Received: $response');
    pendingResponse = false;
  }

  Future<void> close() async {
    final socket = _socket;
    if (socket != null) {
      await socket.flush();
      await socket.close();
      _socket = null;
      _log.info('Closed connection.');
    }
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

  Future<void> _command(String code,
      {String parameters = '', int remainingDelays = 10}) async {
    if (pendingResponse) {
      if (remainingDelays < 1) {
        _log.severe('Giving up on getting a response for the previous command.');
        pendingResponse = false;
        return _command(code, parameters: parameters);
      }
      _log.warning('Waiting on a response to the previous command. '
          'Will try again in 1s.');
      await Future.delayed(
          const Duration(seconds: 1),
          () => _command(code,
              parameters: parameters, remainingDelays: remainingDelays - 1));
      return;
    }
    final socket = _socket;
    final c = _formatCommand(code, parameters);
    if (socket != null) {
      _log.info('Sending command: $c');
      socket.write(c);
      pendingResponse = true;
    } else {
      _log.severe('Socket is not open. Unable to send command code: $code');
    }
  }

  Future<void> powerToggle() async => await _command('POW');
  Future<void> powerOn() async => await _command('PON');
  Future<void> powerOff() async => await _command('POF');

  Future<void> setVerboseMode(VerboseMode mode) async {
    int modeValue;
    switch (mode) {
      case VerboseMode.off:
        modeValue = 0;
        break;
      case VerboseMode.major:
        modeValue = 2;
        break;
      case VerboseMode.detailed:
        modeValue = 3;
        break;
    }
    await _command('SMV', parameters: modeValue.toString());
  }
}
