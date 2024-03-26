import 'dart:math';
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
    device.startParser();
    await device.setVerboseMode(VerboseMode.detailed);
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
      return VerboseMode.values.firstWhere((p) => p.typeCode == typeCode);
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
  discMenu('MENU');

  final String typeCode;
  const PlaybackStatus(this.typeCode);

  factory PlaybackStatus.fromTypeCode(String typeCode) {
    try {
      return PlaybackStatus.values.firstWhere((p) => p.typeCode == typeCode);
    } on StateError {
      throw 'Unknown typeCode for playback status: $typeCode';
    }
  }
}

enum AspectRatio {
  ratio16x9,
  ratio21x9,
}

enum AspectRatioMode {
  wide,
  wideAuto,
  moveable,
  fixed,
  cropped,
}

enum AspectRatioPlayback {
  wide,
  ratio4x3,
  fullScreen,
  ratio16x9or4x3,
  ratio21x9,
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
      return TimeInformation.values.firstWhere((p) => p.typeCode == typeCode);
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
}

enum HdrSetting {
  auto('Auto'),
  on('On'),
  off('Off');

  final String typeCode;
  const HdrSetting(this.typeCode);
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
}

enum ScreenSaverSetting {
  on('ON'),
  off('OFF'),
  save('SAVE');

  final String typeCode;
  const ScreenSaverSetting(this.typeCode);
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
}

enum SacdPriority {
  multiChannel('M'),
  stereo('S'),
  cdMode('C');

  final String typeCode;
  const SacdPriority(this.typeCode);
}

enum SacdOutputMode {
  dsd('D'),
  pcm('P'),
  auto('A');

  final String typeCode;
  const SacdOutputMode(this.typeCode);
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
}

enum DiscType {
  uhdBlueRay('UHBD'),
  blueRay('BDMV'),
  dvdVideo('DVDV'),
  dvdAudio('DVDA'),
  sacd('SACD'),
  cd('CDDA'),
  data('DATA'),
  videoCD('VCD2'), // VCD 2.0
  svcd('SVCD'),
  unknown('UNKW');

  final String typeCode;
  const DiscType(this.typeCode);

  factory DiscType.fromTypeCode(String typeCode) {
    try {
      return DiscType.values.firstWhere((p) => p.typeCode == typeCode);
    } on StateError {
      throw 'Unknown typeCode for disc type: $typeCode';
    }
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

enum ResultCode {
  ok('OK'),
  error('ER');

  final String typeCode;
  const ResultCode(this.typeCode);

  factory ResultCode.fromTypeCode(String typeCode) {
    try {
      return ResultCode.values.firstWhere((p) => p.typeCode == typeCode);
    } on StateError {
      throw 'Unknown typeCode for result code: $typeCode';
    }
  }
}

class Response {
  final ResultCode responseCode;
  final String commandCode;
  final String parameters;

  const Response(this.responseCode, this.commandCode, this.parameters);
}

class Device {
  final String name;
  final InternetAddress address;
  final int port;
  DateTime? _pendingResponseTimestamp;
  String? _pendingResponseCommandCode;
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
  DiscType? discType;

  Device(this.name, this.address, this.port);

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

  Stream<String> stream() async* {
    if (_socket == null) connect();
    final socket = _socket;
    if (socket != null) {
      _log.info('Listening for inbound packets.');
      await for (final data in socket) {
        final decoded = ascii.decode(data);
        _log.info('Listener received: $decoded');
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
  Future<void> startParser() async {
    _log.info('Starting parser');
    await for (final packet in stream()) {
      parseMessage(packet);
    }
  }

  void parseMessage(String response) {
    if (!response.startsWith('@')) {
      throw 'Unable to parse response. The "@" prefix is missing: $response';
    }
    final parts = response.split(' ');
    ResultCode resultCode;
    String commandCode;
    String parameters;
    // Updates do not include a resultCode since they are not responses to
    // commands or queries.
    if (response.startsWith('@U')) {
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
        _log.warning('Parsing a verbose mode <=1 response...');
        if (_pendingResponseCommandCode == null) {
          throw 'Got a verbose mode <=1 response but '
              'there was no pending response command: $response';
        } else {
          commandCode = _pendingResponseCommandCode!;
          resultCode = ResultCode.fromTypeCode(part1);
          parameters = part2;
        }
      } else {
        commandCode = part1;
        resultCode = ResultCode.fromTypeCode(part2);
        parameters = parts.sublist(2).join(' ').trim();
      }
      _responses.add(Response(resultCode, commandCode, parameters));
      _parseResponse(commandCode, resultCode, parameters);
    }
  }

  // TODO - maybe delete this function and handle parsing in query functions.
  // I'm a bit tempted to keep this for nonquery responses.
  void _parseResponse(
      String commandCode, ResultCode resultCode, String parameters) {
    _pendingResponseTimestamp = null;
    _pendingResponseCommandCode = null;
    if (resultCode == ResultCode.error) {
      _log.severe('Got an error with command code $commandCode '
          'with parameters: $parameters');
      return;
    }
    _log.info('Handling response for command code: $commandCode');
    switch (commandCode) {
      case 'QVM' || 'SVM':
        _parseVerboseMode(parameters);
        break;
      case 'QPW' || 'PON' || 'POF' || 'POW':
        // powered = parameters == 'ON' ? true : false;
        break;
      case 'QVR':
        firmwareVersion = parameters;
        break;
      default:
        _log.warning('[R] Unsupported command code: $commandCode');
        break;
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
      // TODO - implement.
      case 'UAT':
        break;
      // TODO - implement.
      case 'UST':
        break;
      // TODO - implement.
      case 'UIS':
        break;
      // TODO - implement.
      case 'U3D':
        break;
      // TODO - implement.
      case 'UAR':
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

  void _parseVerboseMode(String parameters) {
    try {
      verboseMode = VerboseMode.fromTypeCode(parameters);
    } catch (e) {
      _log.severe('Unexpected verbose mode: $parameters');
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
    if (_pendingResponseTimestamp != null) {
      final waiting = DateTime.now().difference(_pendingResponseTimestamp!);
      if (waiting > Duration(seconds: 10)) {
        _log.severe(
            'Giving up on getting a response for the previous command.');
        _pendingResponseTimestamp = null;
        _pendingResponseCommandCode = null;
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
      _pendingResponseTimestamp = DateTime.now();
      _pendingResponseCommandCode = code;
    } else {
      _log.severe('Socket is not open. Unable to send command code: $code');
    }
  }

  Future<void> powerToggle() async => await _command('POW');
  Future<void> powerOn() async => await _command('PON');
  Future<void> powerOff() async => await _command('POF');
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
  Future<void> setUp() async => await _command('SET');
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
    await _command('SVM', parameters: mode.typeCode);
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

  // TODO - In the API docs, their position example is 0:12:13. As such, it's
  // unclear which, if any, fields require zero padding.
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

  Future<void> queryDirectoryItem(int index) async {
    if (index < 1) throw 'index must be a positive int.';
    await _command('QDR', parameters: index.toString());
  }

  Future<void> queryVerboseMode() async => await _command('QVM');

  // TODO - I see need a function to complete a Future once a particular state
  // has changed, with a timeout. Maybe take the condition as a closure? That
  // does make the function completely generic.
  Future<void> queryPowerStatus() async {
    await _command('QPW');
    await for (final r in _responses.stream.timeout(Duration(seconds: 10))) {
      if (r.commandCode == 'QPW') {
        powered = r.parameters == 'ON' ? true : false;
        break;
      }
    }
  }

  Future<void> queryFirmwareVersion() async => await _command('QVR');
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
  Future<void> queryDirectorySize() async => await _command('QDS');
  Future<void> queryAspectRatio() async => await _command('QAR');
}
