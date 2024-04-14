import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

const int _broadcastPort = 7624;
const Duration _responseTimeout = Duration(seconds: 10);

final _log = Logger('oppo');

void main() async {
  Set<OppoBroadcast> devices = {};
  Logger.root.level = Level.INFO;
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
    await device.startListener();
    await device.engage();
  }
}

class OppoBroadcast {
  InternetAddress address;
  int port;
  String name;

  OppoBroadcast(this.address, this.port, this.name);

  @override
  int get hashCode => address.address.hashCode ^ port.hashCode;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OppoBroadcast &&
            address.address == other.address.address &&
            port == other.port;
  }
}

class Discover {
  RawDatagramSocket? _socket;

  void close() {
    if (_socket != null) {
      _socket!.close();
      _log.info('No longer listening for Oppo broadcast packets.');
    }
  }

  Stream<OppoBroadcast> listen() async* {
    _socket =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, _broadcastPort);
    _socket!.writeEventsEnabled = false;
    _log.info('Listening for Oppo broadcast packets.');
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

enum VerboseMode {
  off('0'),
  major('2'),
  detailed('3');

  final String typeCode;
  const VerboseMode(this.typeCode);

  factory VerboseMode.fromTypeCode(String typeCode) {
    try {
      return VerboseMode.values
          .firstWhere((element) => element.typeCode == typeCode);
    } on StateError {
      throw 'Unknown typeCode for verbose mode: $typeCode';
    }
  }
}

enum PlaybackStatus {
  noDisc('DISC'),
  loadingDisc('LOAD'),
  openTray('OPEN'),
  closingTray('CLOS'),
  playbackStarted('PLAY'),
  playbackPaused('PAUS'),
  playbackStopped('STOP'),
  forwardFrameByFrame('STPF'),
  reverseFrameByFrame('STPR'),
  fastForward1('FFW1'),
  fastForward2('FFW2'),
  fastForward3('FFW3'),
  fastForward4('FFW4'),
  fastForward5('FFW5'),
  fastReverse1('FFV1'),
  fastReverse2('FFV2'),
  fastReverse3('FFV3'),
  fastReverse4('FFV4'),
  fastReverse5('FFV5'),
  slowForwardHalf('SFW1'),
  slowForwardQuarter('SFW2'),
  slowForwardEighth('SFW3'),
  slowForwardSixteenth('SFW4'),
  slowForwardThirtySecond('SFW5'),
  fastForwardHalf('SRV1'),
  fastForwardQuarter('SRV2'),
  fastForwardEighth('SRV3'),
  fastForwardSixteenth('SRV4'),
  fastForwardThirtySecond('SRV5'),
  homeMenu('HOME'),
  mediaCenter('MCTR'),
  screenSaver('SCSV'),
  discMenu('MENU'),
  dlna('DLNA'); // undocumented

  final String typeCode;
  const PlaybackStatus(this.typeCode);

  factory PlaybackStatus.fromTypeCode(String typeCode) {
    try {
      return PlaybackStatus.values
          .firstWhere((element) => element.typeCode == typeCode);
    } on StateError {
      throw 'Unknown typeCode for playback status: $typeCode';
    }
  }
}

enum AspectRatio {
  ratio16x9('16:9'),
  ratio21x9('21:9');

  final String displayName;
  const AspectRatio(this.displayName);
}

enum AspectRatioMode {
  wide('Wide'),
  wideAuto('Wide Auto'),
  moveable('Moveable'),
  fixed('Fixed'),
  cropped('Cropped');

  final String displayName;
  const AspectRatioMode(this.displayName);
}

enum AspectRatioPlayback {
  wide('Wide'),
  ratio4x3('4:3'),
  fullScreen('Fullscreen'),
  ratio16x9or4x3('16:9 or 4:3'),
  ratio21x9('21:9');

  final String displayName;
  const AspectRatioPlayback(this.displayName);
}

class AspectRatioSetting {
  AspectRatio ratio;
  AspectRatioMode mode;
  AspectRatioPlayback playback;

  AspectRatioSetting(this.ratio, this.mode, this.playback);
}

enum TimeInformation {
  totalElapsedTime('Total elapsed time', 'E'),
  totalRemainingTime('Total remaining time', 'R'),
  titleElapsedTime('Title elapsed time', 'T'),
  titleRemainingTime('Title remaining time', 'X'),
  chapterOrTrackElapsedTime('Chapter/Track elapsed time', 'C'),
  chapterOrTrackRemainingTime('Chapter/Track remaining time', 'K');

  final String displayName;
  final String typeCode;

  const TimeInformation(this.displayName, this.typeCode);

  factory TimeInformation.fromTypeCode(String typeCode) {
    try {
      return TimeInformation.values
          .firstWhere((element) => element.typeCode == typeCode);
    } on StateError {
      throw 'Unknown typeCode for time information: $typeCode';
    }
  }
}

class Position {
  int title;
  int chapter;
  TimeInformation timeInformation;
  String clock;

  Position(this.title, this.chapter, this.timeInformation, this.clock);
}

enum DirectoryItemType {
  usb('U'),
  opticalDisc('O'),
  // TODO - 0 is also an example of a network search?!
  upperLevel('0'),
  file('F'),
  directory('D'),
  dlnaServer('L'),
  smbServer('S'),
  nfsServer('N');

  final String typeCode;
  const DirectoryItemType(this.typeCode);

  factory DirectoryItemType.fromTypeCode(String typeCode) {
    try {
      return DirectoryItemType.values
          .firstWhere((element) => element.typeCode == typeCode);
    } on StateError {
      throw 'Unknown typeCode for directory item type: $typeCode';
    }
  }
}

class DirectoryItem {
  DirectoryItemType type;
  String name;

  DirectoryItem(this.type, this.name);

  @override
  String toString() => name;
}

enum HdmiResolution {
  auto('AUTO'),
  src('SRC'),
  uhdAuto('UDH_AUTO'),
  udh24('UHD24'),
  uhd50('UHD50'),
  uhd60('UHD60'),
  r1080pAuto('1080P_AUTO'),
  r1080p24('1080P24'),
  r1080p50('1080P50'),
  r1080p60('1080P60'),
  r1080i50('1080I50'),
  r1080i60('1080I60'),
  r720p50('720P50'),
  r720p60('720P60'),
  r576p('576P'),
  r576i('576I'),
  r480p('480P'),
  r480i('480I');

  final String typeCode;
  const HdmiResolution(this.typeCode);

  factory HdmiResolution.fromTypeCode(String typeCode) {
    try {
      return HdmiResolution.values
          .firstWhere((element) => element.typeCode == typeCode);
    } on StateError {
      throw 'Unknown typeCode for HDMI resolution: $typeCode';
    }
  }
}

enum ZoomRatio {
  aspectRatioCorrection('AR'),
  fullScreen('FS'),
  underScan('US'),
  oneX('1'),
  onePointTwoX('1.2'),
  onePointThreeX('1.3'),
  onePointFiveX('1.5'),
  twoX('2'),
  threeX('3'),
  fourX('4'),
  oneHalf('1/2'),
  oneThird('1/3'),
  oneQuarter('1/4');

  final String typeCode;
  const ZoomRatio(this.typeCode);

  factory ZoomRatio.fromTypeCode(String typeCode) {
    try {
      return ZoomRatio.values
          .firstWhere((element) => element.typeCode == typeCode);
    } on StateError {
      throw 'Unknown typeCode for zoom ratio: $typeCode';
    }
  }
}

enum RepeatMode {
  chapter('CH'),
  titleOrTrack('TT'),
  all('ALL'),
  off('OFF'),
  shuffle('SHf'),
  random('RND');

  final String typeCode;
  const RepeatMode(this.typeCode);

  factory RepeatMode.fromTypeCode(String typeCode) {
    try {
      return RepeatMode.values
          .firstWhere((element) => element.typeCode == typeCode);
    } on StateError {
      throw 'Unknown typeCode for repeat mode: $typeCode';
    }
  }
}

enum HdrSetting {
  auto('Auto'),
  on('On'),
  off('Off');

  final String typeCode;
  const HdrSetting(this.typeCode);

  factory HdrSetting.fromTypeCode(String typeCode) {
    try {
      return HdrSetting.values
          .firstWhere((element) => element.typeCode == typeCode);
    } on StateError {
      throw 'Unknown typeCode for HDR setting: $typeCode';
    }
  }
}

enum InputSource {
  blurayPlayer('0'),
  hdmi('1'),
  arc('2'),
  // 3-5 only available on UDP-205.
  optical('3'),
  coax('4'),
  usb('5');

  final String typeCode;
  const InputSource(this.typeCode);

  factory InputSource.fromTypeCode(String typeCode) {
    try {
      return InputSource.values
          .firstWhere((element) => element.typeCode == typeCode);
    } on StateError {
      throw 'Unknown typeCode for input source: $typeCode';
    }
  }
}

enum ScreenSaverSetting {
  on('ON'),
  off('OFF'),
  save('SAVE');

  final String typeCode;
  const ScreenSaverSetting(this.typeCode);

  factory ScreenSaverSetting.fromTypeCode(String typeCode) {
    try {
      return ScreenSaverSetting.values
          .firstWhere((element) => element.typeCode == typeCode);
    } on StateError {
      throw 'Unknown typeCode for screen saver setting: $typeCode';
    }
  }
}

enum App {
  disc('DIS'),
  music('MUS'),
  photo('PHO'),
  movie('MOV'),
  network('NET'),
  setup('SET');

  final String typeCode;
  const App(this.typeCode);

  factory App.fromTypeCode(String typeCode) {
    try {
      return App.values.firstWhere((element) => element.typeCode == typeCode);
    } on StateError {
      throw 'Unknown typeCode for App: $typeCode';
    }
  }
}

enum SacdPriority {
  multiChannel('M'),
  stereo('S'),
  cdMode('C');

  final String typeCode;
  const SacdPriority(this.typeCode);

  factory SacdPriority.fromTypeCode(String typeCode) {
    try {
      return SacdPriority.values
          .firstWhere((element) => element.typeCode == typeCode);
    } on StateError {
      throw 'Unknown typeCode for SACD priority: $typeCode';
    }
  }
}

enum SacdOutputMode {
  dsd('D'),
  pcm('P'),
  auto('A');

  final String typeCode;
  const SacdOutputMode(this.typeCode);

  factory SacdOutputMode.fromTypeCode(String typeCode) {
    try {
      return SacdOutputMode.values
          .firstWhere((element) => element.typeCode == typeCode);
    } on StateError {
      throw 'Unknown typeCode for SACD output mode: $typeCode';
    }
  }
}

enum PlaybackSpeed {
  s32xSlow('1/32'),
  s16xSlow('1/16'),
  s8xSlow('1/8'),
  s4xSlow('1/4'),
  s2xSlow('1/2'),
  s1('1'),
  s2('2'),
  s3('3'),
  s4('4'),
  s5('5');

  final String typeCode;
  const PlaybackSpeed(this.typeCode);

  factory PlaybackSpeed.fromTypeCode(String typeCode) {
    try {
      return PlaybackSpeed.values
          .firstWhere((element) => element.typeCode == typeCode);
    } on StateError {
      throw 'Unknown typeCode for playback speed: $typeCode';
    }
  }
}

enum DiscType {
  uhdBlueRay('UHBD', 'UHD Blu-ray'),
  blueRay('BDMV', 'Blu-ray'),
  dvdVideo('DVDV', 'DVD'),
  dvdAudio('DVDA', 'DVD Audio'),
  sacd('SACD', 'SACD'),
  cd('CDDA', 'CD'),
  data('DATA', 'Data'),
  videoCD('VCD2', 'Video CD'), // VCD 2.0
  svcd('SVCD', 'Super Video CD'),
  unknown('UNKW', 'Unknown');

  final String typeCode;
  final String displayName;
  const DiscType(this.typeCode, this.displayName);

  factory DiscType.fromTypeCode(String typeCode) {
    try {
      return DiscType.values
          .firstWhere((element) => element.typeCode == typeCode);
    } on StateError {
      throw 'Unknown typeCode for disc type: $typeCode';
    }
  }
}

enum AudioType {
  dolbyDigital('DD', 'Dolby Digital'),
  dolbyDigitalPlus('DP', 'DolbyDigitalPlus'),
  dolbyTrueHD('DT', 'Dolby TrueHD'),
  dts('TS', 'DTS'),
  dtsHdHighResolution('TH', 'DTS-HD High Resolution'),
  dtsHdMasterAudio('TM', 'DTS-HD Master Audio'),
  lPcm('PC', 'LPCM'),
  mpegAudio('MP', 'MPEG Audio'),
  cd('CD', 'CD Audio'),
  unknown('UN', 'Unknown');

  final String typeCode;
  final String displayName;
  const AudioType(this.typeCode, this.displayName);

  factory AudioType.fromTypeCode(String typeCode) {
    try {
      return AudioType.values
          .firstWhere((element) => element.typeCode == typeCode);
    } on StateError {
      throw 'Unknown typeCode for audio type: $typeCode';
    }
  }
}

enum ResultCode {
  ok('OK'),
  error('ER');

  final String typeCode;
  const ResultCode(this.typeCode);

  factory ResultCode.fromTypeCode(String typeCode) {
    try {
      return ResultCode.values
          .firstWhere((element) => element.typeCode == typeCode);
    } on StateError {
      throw 'Unknown typeCode for result code: $typeCode';
    }
  }
}

class Response {
  // These parameters are all optional only because the compiler is unhappy when
  // trying to assign them inside an `await for` block where there's a timeout
  // as is done with _rpc(). It thinks there's a chance that the function will
  // return a null value even when it should throw an exception. So we have to
  // initialize a Response object early in that function before having values
  // for these parameters.
  final ResultCode? resultCode;
  final String? commandCode;
  final String? parameters;

  const Response({this.resultCode, this.commandCode, this.parameters});
}

class Device {
  final String name;
  final InternetAddress address;
  final int port;

  /// The timestamp when the last command was sent. Used for deciding if we've
  /// waited long enough for a response to the last command.
  DateTime? _lastCommandTimestamp;

  /// The command code sent in the last command. Used for confirming a response
  /// is for the command last sent.
  String? _lastCommandCode;

  /// A stream of responses from the device which other components to listen to.
  /// This is handy for call and response flows where you want to block until
  /// the response has been received.
  // Use a broadcast stream so functions can start and stop listening.
  final StreamController<Response> _responses =
      StreamController<Response>.broadcast();
  Socket? _socket;
  VerboseMode? verboseMode;
  bool? powered;
  String? firmwareVersion;
  Position? position;
  bool threeDimensional = false;
  PlaybackStatus? playbackStatus;
  int? volume;
  bool? muted;
  DiscType discType = DiscType.unknown;
  AudioType? audioType;
  int? currentAudioTrack;
  int? availableAudioTracks;
  String? audioLanguage; // ISO 3166 country codes
  String? channels;
  int? currentSubtitleTrack;
  int? availableSubtitleTracks;
  String? subtitleLanguage; // ISO 3166 country codes
  int? inputSourceNumber;
  String? inputSourceName;
  AspectRatioSetting? aspectRatioSetting;

  Device(this.name, this.address, this.port);

  /// Estasblishes a socket to the Oppo player.
  ///
  /// If a connection has already been established, this method does nothing but
  /// log a warning.
  Future<void> connect() async {
    if (_socket != null) {
      _log.warning('connect() called on already connected Device.');
      return;
    }
    _socket = await Socket.connect(address, port,
        timeout: const Duration(seconds: 3));
    _log.info('Connected to device at ${address.address}.');
    final socket = _socket;
    if (socket != null) {
      socket.encoding = const AsciiCodec();
      socket.setOption(SocketOption.tcpNoDelay, true);
    }
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

  /// Set up the player for communication.
  ///
  /// This method should only be called after [startListener] or some equivalent
  /// method is called.
  Future<void> engage() async {
    if (!await queryPowerStatus()) {
      await powerOn();
      await _waitForPowerOn(Duration(seconds: 1), 10);
    }
    await setVerboseMode(VerboseMode.detailed);
  }

  Future<void> _waitForPowerOn(Duration delay, int attemptsRemaining) async {
    if (await queryPowerStatus()) {
      return;
    } else if (attemptsRemaining > 0) {
      attemptsRemaining--;
      await Future.delayed(
          delay, () => _waitForPowerOn(delay, attemptsRemaining));
    } else {
      throw TimeoutException('Timed out waiting for device to power on.');
    }
  }

  // TODO - Perhaps do something like ascii.decoder.bind(_socket) when connecting
  // and make the socket public so this layer of indirection can be removed.
  // Note that [connect] sets the encoding already, so why is this decode step
  // needed?
  Stream<String> stream() async* {
    if (_socket == null) connect();
    final socket = _socket;
    if (socket != null) {
      await for (final data in socket) {
        final decoded = ascii.decode(data);
        _log.finer('Socket received: $decoded');
        yield decoded;
      }
      _log.fine('Listener has stopped.');
    }
  }

  /// Listens to inbound packet stream and parses those packets.
  ///
  /// Flutter apps will probably want to implement a function like this inside a
  /// Provider/Consumer system. But for testing this package, it's handy to have
  /// this function.
  // TODO - I don't know why this function needs to be async. But if it's not,
  // then it seems we might send a command before we start listening for
  // responses.
  Future<void> startListener() async {
    stream().listen((event) {
      parseEvent(event);
    });
  }

  void parseEvent(String event) {
    if (!event.startsWith('@')) {
      throw ('Unable to parse stream event. '
          'The "@" prefix is missing: $event');
    }
    final messages = _splitEvent(event);
    messages.forEach(_parseMessage);
  }

  /// Splits a event off the stream into one or more messages.
  ///
  /// We can sometimes get multiple messages in a single event from the stream.
  /// Especially when a response to a query comes back around the same time as
  /// an update for something like the current playback position.
  Iterable<String> _splitEvent(String event) {
    // Each message begins with '@'. We split the event on '@' but keep the
    // leading '@' in each saved message since _parseMessage expects it.
    return event.substring(1, event.length).split('@').map((e) => '@$e');
  }

  void _parseMessage(String message) {
    _log.info('Received message: $message');
    final parts = message.split(' ');
    ResultCode resultCode;
    String commandCode;
    String parameters;
    // Updates do not include a resultCode since they are not responses to
    // commands or queries.
    if (message.startsWith('@U')) {
      commandCode = parts[0].trim().substring(1);
      parameters = parts.sublist(1).join(' ').trim();
      _parseUpdate(commandCode, parameters);
    } else {
      final part1 = parts[0].trim().substring(1);
      // part2 might be empty if it's being used for parameters.
      String part2 = '';
      if (parts.length > 1) part2 = parts[1].trim();
      // If part1 is a result code, the unit is using verbose mode <=1 and we
      // need to infer the command code from our last command.
      if (part1 == 'OK' || part1 == 'ER') {
        _log.warning('Parsing a verbose mode less than "major" response...');
        if (_lastCommandCode == null) {
          throw 'Got a verbose mode <=1 message but '
              'there was no pending response command: $message';
        } else {
          commandCode = _lastCommandCode!;
          resultCode = ResultCode.fromTypeCode(part1);
          parameters = part2;
        }
      } else {
        commandCode = part1;
        resultCode = ResultCode.fromTypeCode(part2);
        parameters = parts.sublist(2).join(' ').trim();
      }
      _responses.add(Response(
          resultCode: resultCode,
          commandCode: commandCode,
          parameters: parameters));
      _lastCommandTimestamp = null;
      _lastCommandCode = null;
      if (resultCode == ResultCode.error) {
        _log.severe('Got an error with command code $commandCode '
            'with parameters: $parameters');
      }
    }
  }

  void _parseUpdate(String commandCode, String parameters) {
    switch (commandCode) {
      case 'UPW':
        if (parameters == '1') {
          powered = true;
        } else if (parameters == '0') {
          powered = false;
        } else {
          _log.severe('Invalid UPW parameter: $parameters');
        }
        break;
      case 'UPL':
        try {
          playbackStatus = PlaybackStatus.fromTypeCode(parameters);
        } catch (e) {
          _log.severe(e);
        }
        break;
      case 'UVL':
        if (parameters == 'MUT') {
          muted = true;
          break;
        } else if (parameters == 'UMT') {
          // 'UMT' is not a documented parameter for UVL, but it's been seen in
          // the wild, in particular when the unit is powered off. It is assumed
          // it means unmuted. Which seems like a strange state to enter when
          // powered off.
          muted = false;
          break;
        }
        try {
          volume = int.parse(parameters);
        } catch (e) {
          _log.severe('Unable to parse volume value: $e');
        }
        break;
      case 'UDT':
        try {
          discType = DiscType.fromTypeCode(parameters);
        } catch (e) {
          _log.severe(e);
        }
        break;
      case 'UAT':
        AudioTypeUpdate update;
        try {
          update = _parseAudioTypeUpdate(parameters);
        } catch (e) {
          _log.severe(e);
          break;
        }
        audioType = update.type;
        currentAudioTrack = update.currentTrack;
        availableAudioTracks = update.availableTracks;
        audioLanguage = update.language;
        channels = update.channels;
        break;
      case 'UST':
        SubtitleTypeUpdate update;
        try {
          update = _parseSubtitleTypeUpdate(parameters);
        } catch (e) {
          _log.severe(e);
          break;
        }
        currentSubtitleTrack = update.currentTrack;
        availableSubtitleTracks = update.availableTracks;
        subtitleLanguage = update.language;
        break;
      case 'UIS':
        InputSourceUpdate update;
        try {
          update = _parseInputSourceUpdate(parameters);
        } catch (e) {
          _log.severe(e);
          break;
        }
        inputSourceNumber = update.inputSourceNumber;
        inputSourceName = update.inputSourceName;
        break;
      case 'U3D':
        if (parameters.trim() == '3D') {
          threeDimensional = true;
        } else {
          threeDimensional = false;
        }
        break;
      case 'UAR':
        try {
          aspectRatioSetting = _parseAspectRatioUpdate(parameters);
        } catch (e) {
          _log.severe(e);
        }
        break;
      // verboseMode.detailed messages below.
      case 'UTC':
        position = _parseTimeCodeUpdate(parameters);
        break;
      // TODO - implement.
      case 'UVO':
        break;
      default:
        _log.severe('[U] Unsupported command code: $commandCode');
        break;
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

  Future<void> _command(String code, {String parameters = ''}) async {
    if (_lastCommandTimestamp != null) {
      final waiting = DateTime.now().difference(_lastCommandTimestamp!);
      if (waiting > Duration(seconds: 10)) {
        _log.severe(
            'Giving up on getting a response for the previous command.');
        _lastCommandTimestamp = null;
        _lastCommandCode = null;
        return _command(code, parameters: parameters);
      }
      _log.fine('Waiting on a response to the previous command. '
          'Have been waiting $waiting. Will try again in 500ms.');
      await Future.delayed(const Duration(milliseconds: 500),
          () => _command(code, parameters: parameters));
      return;
    }
    final socket = _socket;
    final c = _formatCommand(code, parameters);
    if (socket != null) {
      _log.info('Sending command: $c');
      socket.write(c);
      _lastCommandTimestamp = DateTime.now();
      _lastCommandCode = code;
    } else {
      _log.severe('Socket is not open. Unable to send command code: $code');
    }
  }

  /// Wrapper to simulate procedure call symantecs for a command.
  ///
  /// This method blocks until a response is received for the command or until a
  /// preset timeout is reached, in which case an exception is thrown.
  Future<Response> _rpc(String code, {String parameters = ''}) async {
    Response response = Response();
    // Because with verboseMode.detailed, we might get unsoliticed responses, we
    // need to check all responses in a loop until we get a response to our last
    // command, or we timeout.
    // TODO - Is this a race condition? Should I use the listen() method instead
    // of the for loop.
    await _command(code, parameters: parameters);
    await for (final r in _responses.stream.timeout(_responseTimeout)) {
      if (r.commandCode == code) {
        response = r;
        break;
      }
    }
    if (response.resultCode == ResultCode.error) {
      throw '$code call returned an error result code.';
    }
    return response;
  }

  VerboseMode _parseVerboseMode(String parameters) {
    try {
      var v = VerboseMode.fromTypeCode(parameters);
      verboseMode = v;
      _log.fine('Verbose mode is: ${verboseMode.toString()}');
      return v;
    } catch (e) {
      throw 'Unexpected verbose mode: $e';
    }
  }

  Future<void> powerToggle() async => await _command('POW');
  Future<void> powerOn() async => await _rpc('PON');
  Future<void> powerOff() async => await _rpc('POF');
  Future<void> trayToggle() async => await _command('EJT');
  Future<void> dim() async => await _command('DIM');
  Future<void> pureAudio() async => await _command('PUR');
  Future<void> volumeUp() async => await _command('VUP');
  Future<void> volumeDown() async => await _command('VDN');
  Future<void> mute() async => await _command('MUT');
  // Buttons 0-9 on the numeric keypad.
  Future<void> number1() async => await _command('NU1');
  Future<void> number2() async => await _command('NU2');
  Future<void> number3() async => await _command('NU3');
  Future<void> number4() async => await _command('NU4');
  Future<void> number5() async => await _command('NU5');
  Future<void> number6() async => await _command('NU6');
  Future<void> number7() async => await _command('NU7');
  Future<void> number8() async => await _command('NU8');
  Future<void> number9() async => await _command('NU9');
  Future<void> number0() async => await _command('NU0');

  /// Clear numeric input.
  Future<void> clear() async => await _command('CLR');
  Future<void> goto() async => await _command('GOT');
  Future<void> home() async => await _command('HOM');
  Future<void> pageUp() async => await _command('PUP');
  Future<void> pageDown() async => await _command('PDN');

  /// Show/hide on-screen display.
  Future<void> osd() async => await _command('OSD');
  Future<void> topMenu() async => await _command('TTL');
  Future<void> popupMenu() async => await _command('MNU');
  Future<void> arrowUp() async => await _command('NUP');
  Future<void> arrowLeft() async => await _command('NLT');
  Future<void> arrowRight() async => await _command('NRT');
  Future<void> arrowDown() async => await _command('NDN');
  Future<void> enter() async => await _command('SEL');
  Future<void> setup() async => await _command('SET');
  Future<void> returnToPrevious() async => await _command('RET');
  Future<void> red() async => await _command('RED');
  Future<void> green() async => await _command('GRN');
  Future<void> blue() async => await _command('BLU');
  Future<void> yellow() async => await _command('YLW');
  Future<void> stop() async => await _command('STP');
  Future<void> play() async => await _command('PLA');
  Future<void> pause() async => await _command('PAU');
  Future<void> previous() async => await _command('PRE');
  Future<void> next() async => await _command('NXT');

  /// Fast reverse play.
  Future<void> reverse() async => await _command('REV');

  /// Fast forward play.
  Future<void> forward() async => await _command('FWD');

  /// Change audio or language track.
  Future<void> audio() async => await _command('AUD');

  /// Change subtitle language.
  Future<void> subtitle() async => await _command('SUB');

  /// Change camera angle.
  Future<void> angle() async => await _command('ANG');

  /// Zoom in/out and adjust aspect ratio.
  Future<void> zoom() async => await _command('ZOM');
  Future<void> secondaryAudioProgramToggle() async => await _command('SAP');

  /// Set A/B repeat play points.
  Future<void> repeatAB() async => await _command('ATB');
  Future<void> repeat() async => await _command('RPT');

  /// Picture-in-picture toggle.
  Future<void> pipToggle() async => await _command('PIP');
  Future<void> outputResolutionCycle() async => await _command('HDM');
  // Same as subtitle hold.
  Future<void> subtitleShift() async => await _command('SUH');
  Future<void> option() async => await _command('OPT');
  Future<void> threeDimensionalMenu() async => await _command('M3D');
  Future<void> pictureAdjustmentMenu() async => await _command('SEH');
  Future<void> hdrMenu() async => await _command('HDR');
  Future<void> outputResolutionAuto() async => await _command('RLH');

  /// Show defailed info. The same operation as long pressing the info button.
  Future<void> infoDetailed() async => await _command('INH');
  Future<void> audioVideoSyncMenu() async => await _command('AVS');
  Future<void> gaplessPlayback() async => await _command('GAP');
  Future<void> inputMenu() async => await _command('SRC');

  /// No operation.
  ///
  /// This command is documentd and therefore included. Probably it's only
  /// useful for testing.
  Future<void> noOp() async => await _command('NOP');

  Future<void> setVerboseMode(VerboseMode mode) async {
    await _rpc('SVM', parameters: mode.typeCode);
  }

  Future<void> setHdmiResolution(HdmiResolution hdmiResolution) async {
    await _command('SHD', parameters: hdmiResolution.typeCode);
  }

  Future<void> setZoomRatio(ZoomRatio zoomRatio) async {
    await _command('SZM', parameters: zoomRatio.typeCode);
  }

  Future<void> setVolume(int level) async {
    int sanitizedLevel = max(level, 0);
    sanitizedLevel = min(level, 100);
    await _command('SVL', parameters: sanitizedLevel.toString());
  }

  // This RPC seems to be redudant since there is mute().
  // Future<void> setMute() async => await _command('SVL', parameters: 'MUTE');

  Future<void> setRepeatMode(RepeatMode repeatMode) async {
    await _command('SRP', parameters: repeatMode.typeCode);
  }

  Future<void> searchTo(String position) async {
    await _command('SRH', parameters: position);
  }

  Future<void> searchToTitle(int title) async {
    await searchTo('T$title');
  }

  Future<void> searchToChapter(int chapter) async {
    await searchTo('C$chapter');
  }

  Future<void> searchToChapterTime(Duration position) async {
    await searchTo(
        'C ${position.inHours}:${position.inMinutes}:${position.inSeconds}');
  }

  Future<void> searchToTitleTime(Duration position) async {
    await searchTo(
        'T ${position.inHours}:${position.inMinutes}:${position.inSeconds}');
  }

  Future<void> directPlay() async => await _command('DPL');

  /// Clear command buffers.
  Future<void> reset() async => await _command('RST');

  Future<void> setSubtitleShift(int shift) async {
    int sanitizedShift = max(shift, -10);
    sanitizedShift = min(shift, 10);
    await _command('SSH', parameters: sanitizedShift.toString());
  }

  Future<void> setOsdPosition(int position) async {
    int sanitizedPosition = max(position, 0);
    sanitizedPosition = min(position, 5);
    await _command('SOP', parameters: sanitizedPosition.toString());
  }

  Future<void> setTimeInformationDisplay(
      TimeInformation timeInformation) async {
    await _command('STC', parameters: timeInformation.typeCode);
  }

  Future<void> setHdrSetting(HdrSetting setting) async {
    await _command('SHR', parameters: setting.typeCode);
  }

  Future<void> setInputSource(InputSource inputSource) async {
    await _command('SIS', parameters: inputSource.typeCode);
  }

  Future<void> setScreenSaver(ScreenSaverSetting setting) async {
    await _command('SSA', parameters: setting.typeCode);
  }

  Future<void> runApp(App app) async {
    await _command('APP', parameters: app.typeCode);
  }

  Future<void> setSacdPriority(SacdPriority priority) async {
    await _command('SSD', parameters: priority.typeCode);
  }

  Future<void> setSacdOutputMode(SacdOutputMode mode) async {
    await _command('SDP', parameters: mode.typeCode);
  }

  Future<void> setForwardPlaybackSpeed(PlaybackSpeed speed) async {
    await _command('FWD', parameters: speed.typeCode);
  }

  Future<void> setReversePlaybackSpeed(PlaybackSpeed speed) async {
    await _command('REV', parameters: speed.typeCode);
  }

  Future<VerboseMode> queryVerboseMode() async {
    final r = await _rpc('QVM');
    return _parseVerboseMode(r.parameters!);
  }

  Future<bool> queryPowerStatus() async {
    final r = await _rpc('QPW');
    bool p = r.parameters! == 'ON' ? true : false;
    powered = p;
    return p;
  }

  Future<String> queryFirmwareVersion() async {
    final r = await _rpc('QVR');
    String f = r.parameters!;
    firmwareVersion = f;
    return f;
  }

  Future<void> queryVolume() async => await _command('QVL');
  Future<void> queryResolution() async => await _command('QHD');
  Future<void> queryPlaybackStatus() async => await _command('QPL');
  Future<void> queryTrackOrTitle() async => await _command('QTK');
  Future<void> queryChapter() async => await _command('QCH');
  Future<void> queryTrackOrTitleElapsedTime() async => await _command('QTE');
  Future<void> queryTrackOrTitleRemainingTime() async => await _command('QTR');
  Future<void> queryChapterElapsedTime() async => await _command('QCE');
  Future<void> queryChapterRemainingTime() async => await _command('QCR');
  Future<void> queryTotalElapsedTime() async => await _command('QEL');
  Future<void> queryTotalRemainingTime() async => await _command('QRE');
  Future<void> queryDiskType() async => await _command('QDT');
  Future<void> queryAudioType() async => await _command('QAT');
  Future<void> querySubtitleType() async => await _command('QST');
  Future<void> querySubtitleShift() async => await _command('QSH');
  Future<void> queryOsdPosition() async => await _command('QOP');
  Future<void> queryRepeatMode() async => await _command('QRP');
  Future<void> queryZoomMode() async => await _command('QZM');
  Future<void> queryHdrSetting() async => await _command('QHR');
  Future<void> query3DStatus() async => await _command('Q3D');
  Future<void> queryHdrStatus() async => await _command('QHS');
  Future<void> queryInputSource() async => await _command('QIS');
  Future<void> queryCddbNumber() async => await _command('QCD');
  Future<void> queryMediaFileFormat() async => await _command('QFT');
  Future<void> queryMediaFileName() async => await _command('QFN');
  Future<void> queryTrackName() async => await _command('QTN');
  Future<void> queryTrackAlbum() async => await _command('QTA');
  Future<void> queryTrackPerformer() async => await _command('QTP');
  Future<void> queryAspectRatio() async => await _command('QAR');

  Future<int> queryDirectorySize() async {
    final r = await _rpc('QDS');
    try {
      return int.parse(r.parameters!);
    } on FormatException {
      throw FormatException('${r.parameters} was not a valid directory size.');
    }
  }

  Future<DirectoryItem> queryDirectoryItem(int index) async {
    if (index < 1) throw 'index must be a positive int.';
    final r = await _rpc('QDR', parameters: index.toString());
    final parameters = r.parameters!;
    DirectoryItemType type;
    String name;
    try {
      type = DirectoryItemType.fromTypeCode(parameters[0]);
      name = parameters.substring(1).trim();
    } catch (_) {
      // If no type parameter is provided, it seems we should assume the type is
      // file.
      type = DirectoryItemType.file;
      name = parameters.trim();
    }
    return DirectoryItem(type, name);
  }

  /// Fetch of list of directory items for the current context.
  ///
  /// The current context is, for example, the directory being viewed on the
  /// OSD, perhaps from a USB drive or network share.
  ///
  /// WARNING: This bit of the API is partly broken and has limited usefulness.
  /// There's no API method to select a directory item aside from manipulating
  /// the cursor position.
  Future<List<DirectoryItem>> directoryItems() async {
    List<DirectoryItem> items = [];
    final ds = await queryDirectorySize();
    for (int i = 1; i <= ds; i++) {
      try {
        items.add(await queryDirectoryItem(i));
      } catch (_) {
        // Ignore errors and try the next query. The API is known to be broken
        // on SMB share items.
      }
    }
    return items;
  }
}

Position _parseTimeCodeUpdate(String timeCode) {
  final parts = timeCode.split(' ');
  if (parts.length != 4) {
    throw 'Could not parse time code: $timeCode';
  }
  final title = int.parse(parts[0].trim());
  final chapter = int.parse(parts[1].trim());
  final timeInformation = TimeInformation.fromTypeCode(parts[2].trim());
  final clock = parts[3].trim();
  return Position(title, chapter, timeInformation, clock);
}

class AudioTypeUpdate {
  final AudioType type;
  final int currentTrack;
  final int availableTracks;
  final String language;
  final String channels;

  AudioTypeUpdate(this.type, this.currentTrack, this.availableTracks,
      this.language, this.channels);
}

AudioTypeUpdate _parseAudioTypeUpdate(String parameters) {
  final parts = parameters.split(' ');
  if (parts.length != 4) {
    throw 'Could not parse audio type update: $parameters';
  }
  final type = AudioType.fromTypeCode(parts[0].trim());
  int currentTrack;
  int availableTracks;
  try {
    final trackInfo = parts[1].trim().split('/').map(int.parse).toList();
    currentTrack = trackInfo[0];
    availableTracks = trackInfo[1];
  } catch (e) {
    throw 'Could not parse track info from audio type update: $parameters';
  }
  final language = parts[2].trim();
  final channels = parts[3].trim();
  return AudioTypeUpdate(
      type, currentTrack, availableTracks, language, channels);
}

class SubtitleTypeUpdate {
  final int currentTrack;
  final int availableTracks;
  final String language;

  SubtitleTypeUpdate(this.currentTrack, this.availableTracks, this.language);
}

SubtitleTypeUpdate _parseSubtitleTypeUpdate(String parameters) {
  final parts = parameters.split(' ');
  if (parts.length != 2) {
    throw 'Could not parse subtitle type update: $parameters';
  }
  int currentTrack;
  int availableTracks;
  try {
    // TODO - Maybe these fields might sometimes include 'xx'. The API docs say,
    // "If subtitle is set to off, use 00/xx where xx is the number of available
    // subtitle tracks. If no subtitle is available, use 00/00."
    final trackInfo = parts[0].trim().split('/').map(int.parse).toList();
    currentTrack = trackInfo[0];
    availableTracks = trackInfo[1];
  } catch (e) {
    throw 'Could not parse track info from subtitle type update: $parameters';
  }
  final language = parts[1].trim();
  return SubtitleTypeUpdate(currentTrack, availableTracks, language);
}

class InputSourceUpdate {
  final int inputSourceNumber;
  final String inputSourceName;

  InputSourceUpdate(this.inputSourceNumber, this.inputSourceName);
}

InputSourceUpdate _parseInputSourceUpdate(String parameters) {
  final parts = parameters.split(' ');
  if (parts.length != 2) {
    throw 'Could not parse input source update: $parameters';
  }
  int inputSourceNumber;
  try {
    inputSourceNumber = int.parse(parts[0].trim());
  } catch (e) {
    throw 'Could not parse input source number from input source update: $parameters';
  }
  final inputSourceName = parts[1].trim();
  return InputSourceUpdate(inputSourceNumber, inputSourceName);
}

AspectRatioSetting _parseAspectRatioUpdate(String parameters) {
  final update = parameters.trim().toUpperCase();
  if (update.length != 4) {
    throw 'Could not parse aspect ratio status update: $parameters';
  }
  switch (update) {
    case '16WW':
      return AspectRatioSetting(
        AspectRatio.ratio16x9,
        AspectRatioMode.wide,
        AspectRatioPlayback.wide,
      );
    case '16AW':
      return AspectRatioSetting(
        AspectRatio.ratio16x9,
        AspectRatioMode.wideAuto,
        AspectRatioPlayback.wide,
      );
    case '16A4':
      return AspectRatioSetting(
        AspectRatio.ratio16x9,
        AspectRatioMode.wideAuto,
        AspectRatioPlayback.ratio4x3,
      );
    case '21M0':
      return AspectRatioSetting(
        AspectRatio.ratio21x9,
        AspectRatioMode.moveable,
        AspectRatioPlayback.fullScreen,
      );
    case '21M1':
      return AspectRatioSetting(
        AspectRatio.ratio21x9,
        AspectRatioMode.moveable,
        AspectRatioPlayback.ratio16x9or4x3,
      );
    case '21M2':
      return AspectRatioSetting(
        AspectRatio.ratio21x9,
        AspectRatioMode.moveable,
        AspectRatioPlayback.ratio21x9,
      );
    case '21F0':
      return AspectRatioSetting(
        AspectRatio.ratio21x9,
        AspectRatioMode.fixed,
        AspectRatioPlayback.fullScreen,
      );
    case '21F1':
      return AspectRatioSetting(
        AspectRatio.ratio21x9,
        AspectRatioMode.fixed,
        AspectRatioPlayback.ratio16x9or4x3,
      );
    case '21F2':
      return AspectRatioSetting(
        AspectRatio.ratio21x9,
        AspectRatioMode.fixed,
        AspectRatioPlayback.ratio21x9,
      );
    case '21C0':
      return AspectRatioSetting(
        AspectRatio.ratio21x9,
        AspectRatioMode.cropped,
        AspectRatioPlayback.fullScreen,
      );
    case '21C1':
      return AspectRatioSetting(
        AspectRatio.ratio21x9,
        AspectRatioMode.cropped,
        AspectRatioPlayback.ratio16x9or4x3,
      );
    case '21C2':
      return AspectRatioSetting(
        AspectRatio.ratio21x9,
        AspectRatioMode.cropped,
        AspectRatioPlayback.ratio21x9,
      );
    default:
      throw 'Could not parse aspect ratio status update: $parameters';
  }
}
