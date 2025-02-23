import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

// This port number seems to be used for two purposes.
// 1) The player broadcasts its existance every 10s to this destination port.
// 2) It's the source and destination port for the "OREMOTE LOGIN" call and
// responses initiated by the Oppo made MediaControl app.
const int _broadcastPort = 7624;
const int _httpPort = 436;
const int _serialPort = 23;
const Duration _responseTimeout = Duration(seconds: 10);

final _log = Logger('oppo');

void main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  Set<OppoID> ids = {};
  // Uncomment if you want to exercise the discovery feature. Also comment out
  // the ids.add() call below. While testing on WSL, it's convenient to skip
  // discovery.
  // final d = Discover();
  // final d = ActiveDiscover();
  // _log.info('Scanning for Oppo UDP-20X players...');
  // await for (final info in d.listen()) {
  //   _log.info('Found Oppo device at ${info.address.address}');
  //   d.close();
  //   ids.add(info);
  // }
  ids.add(OppoID(InternetAddress('192.168.86.139'), _serialPort, 'unknown'));

  if (ids.isNotEmpty) {
    var info = ids.first;
    final device = Device(info.name, info.address, info.port);
    await device.connect();
    await device.startListener();
    await device.engage();
  }
}

class OppoID {
  InternetAddress address;
  int port;
  String name;

  OppoID(this.address, this.port, this.name);

  @override
  int get hashCode => address.address.hashCode ^ port.hashCode;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OppoID &&
            address.address == other.address.address &&
            port == other.port;
  }

  /// Parses the becon packet sent by the player every 10s.
  factory OppoID.fromBeacon(Datagram datagram) {
    InternetAddress? address;
    int? port;
    String name = '';
    final decoded = ascii.decode(datagram.data);
    for (final line in decoded.split('\n')) {
      if (line.isEmpty) continue;
      // One user provided a packet capture showing this being the contents of
      // their beacon packet. They were running the Russian Jailbrake firmware
      // on a UDP-203.
      if (line.toUpperCase() == 'NOTIFY OPPO PLAYER SHUTDOWN') {
        throw 'player reports IP control is shutdown';
      }
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
          // This is the broadcast packet prefix. It has no data we need. And it
          // doesn't seem necessary to verify its contents.
          break;
        default:
          _log.warning('Unrecognized line in broadcast packet: $line');
          break;
      }
    }
    if (address == null) throw 'failed to find IP address';
    if (port == null) throw 'failed to find port';
    return OppoID(address, port, name);
  }

  factory OppoID.fromOremoteLoginResponse(Datagram datagram) {
    InternetAddress? address;
    String name = '';
    final decoded = ascii.decode(datagram.data);
    final parts = decoded.split(' ');
    if (parts.length != 7) {
      throw 'failed to parse OREMOTE LOGIN response: $decoded';
    }
    name = parts[0].replaceAll('_', ' ');
    final addressAndPort = parts[6].split(':');
    address = InternetAddress(addressAndPort[0]);
    // The port in the response packet seems to always be 19999. I don't know
    // what that is. I can't conntect to it with TCP. We'll be connecting to the
    // known ports [_serialPort] and [_httpPort]. _serialPort is used here since
    // its the port used for the documented API.
    return OppoID(address, _serialPort, name);
  }
}

class Discover {
  RawDatagramSocket? _socket;

  void close() {
    if (_socket != null) {
      _socket!.close();
      _log.fine('No longer listening for Oppo beacon packets.');
    }
  }

  Stream<OppoID> listen() async* {
    _socket =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, _broadcastPort);
    _socket!.writeEventsEnabled = false;
    _log.info('Listening for Oppo beacon packets.');
    await for (final event in _socket!) {
      if (event == RawSocketEvent.read) {
        final datagram = _socket!.receive();
        if (datagram == null) continue;
        try {
          yield OppoID.fromBeacon(datagram);
        } catch (e) {
          _log.warning('Failed to parse beacon packet: $e');
        }
      }
    }
  }
}

/// Call and response way to discover Oppo players.
///
/// This uses an undocumented process. Importantly, it seems necessary to send
/// the "call" message at least once after the player powers up from being
/// completely off or else the HTTP service on port 436 will not be reachable.
/// Aside from that benefit, this process should generally be able to discover
/// players more quickly than the documented discovery process, which listens
/// for a beacon packet sent by the player every 10s.
class ActiveDiscover {
  RawDatagramSocket? _socket;
  static const _pingMessage = 'NOTIFY OREMOTE LOGIN';

  Future<void> _open() async {
    if (_socket == null) {
      try {
        _socket = await RawDatagramSocket.bind(
            InternetAddress.anyIPv4, _broadcastPort);
        _socket!.broadcastEnabled = true;
      } catch (e) {
        _log.severe('Unable to bind socket for ActiveDiscover: $e');
      }
    }
  }

  void close() {
    if (_socket != null) {
      _socket!.close();
      _log.fine('No longer listening for Oppo OREMOTE LOGIN packets.');
    }
  }

  /// Sends the "call" part of the call and response.
  ///
  /// This could be useful to call without listening for a repsonse if you
  /// already know the address of the player but you only want to make the HTTP
  /// service on port 436 reachable.
  Future<void> ping() async {
    await _open();
    final bytesSent = _socket!.send(_pingMessage.codeUnits,
        InternetAddress('255.255.255.255'), _broadcastPort);
    if (bytesSent == 0) {
      _log.warning('Failed to send OREMOTE LOGIN packet.');
    } else {
      _log.fine('Sent: $_pingMessage');
    }
  }

  Stream<OppoID> listen() async* {
    await ping(); // [ping] also creates the socket.
    await for (final event in _socket!) {
      if (event == RawSocketEvent.read) {
        final datagram = _socket!.receive();
        if (datagram == null) continue;
        // Since we broadcast the ping on the same port we listen for the
        // response, we're going to see our own ping message. We meed to ignore
        // it.
        if (ascii.decode(datagram.data) == _pingMessage) continue;
        try {
          yield OppoID.fromOremoteLoginResponse(datagram);
        } catch (e) {
          _log.warning('Failed to parse OREMOTE LOGIN response packet: $e');
        }
      }
    }
  }
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
  fastReverse1('FRV1'),
  fastReverse2('FRV2'),
  fastReverse3('FRV3'),
  fastReverse4('FRV4'),
  fastReverse5('FRV5'),
  slowForwardHalf('SFW1'),
  slowForwardQuarter('SFW2'),
  slowForwardEighth('SFW3'),
  slowForwardSixteenth('SFW4'),
  slowForwardThirtySecond('SFW5'),
  slowReverseHalf('SRV1'),
  slowReverseQuarter('SRV2'),
  slowReverseEighth('SRV3'),
  slowReverseSixteenth('SRV4'),
  slowReverseThirtySecond('SRV5'),
  homeMenu('HOME'),
  mediaCenter('MCTR'),
  screenSaver('SCSV'),
  discMenu('MENU'),
  dlna('DLNA'), // undocumented
  setup('SETUP'), // only documented for the QPL command
  unknown('UNKNOW'); // undocumented

  final String typeCode;
  const PlaybackStatus(this.typeCode);

  factory PlaybackStatus.fromTypeCode(String typeCode) {
    try {
      // 'CLOSE' is undocumented but observed. It's so close to 'CLOS' it likely
      // means the same thing.
      if (typeCode == 'CLOSE') return PlaybackStatus.closingTray;
      return PlaybackStatus.values
          .firstWhere((element) => element.typeCode == typeCode);
    } on StateError {
      throw 'Unknown typeCode for playback status: $typeCode';
    }
  }

  /// Responses to the QPL command are formatted differently from the updates
  /// from the UPL command. This factory translates those which are different.
  factory PlaybackStatus.fromQueryResponse(String response) {
    switch (response) {
      case 'PAUSE':
        return PlaybackStatus.playbackPaused;
      case 'STEP':
        return PlaybackStatus.forwardFrameByFrame;
      case 'FREV':
        return PlaybackStatus.fastReverse1;
      case 'FFWD':
        return PlaybackStatus.fastForward1;
      case 'SFWD':
        return PlaybackStatus.slowForwardHalf;
      case 'SREV':
        return PlaybackStatus.slowReverseHalf;
      case 'HOME MENU':
        return PlaybackStatus.homeMenu;
      case 'MEDIA CENTER':
        return PlaybackStatus.mediaCenter;
      case 'SCREEN SAVER':
        return PlaybackStatus.screenSaver;
      case 'DISC MENU':
        return PlaybackStatus.discMenu;
      default:
        return PlaybackStatus.fromTypeCode(response);
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

  factory AspectRatioSetting.fromUpdateParameters(String parameters) {
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

  factory AspectRatioSetting.fromQueryResponse(String typeCode) =>
      AspectRatioSetting.fromUpdateParameters(typeCode);
}

enum TimeInformation {
  totalElapsedTime('Total elapsed time', 'E'),
  totalRemainingTime('Total remaining time', 'R'),
  titleElapsedTime('Title elapsed time', 'T'),
  titleRemainingTime('Title remaining time', 'X'),
  // It's typical to be playing tracks (audio) when using these modes, so don't
  // mention chapters in their display names.
  chapterOrTrackElapsedTime('Track elapsed time', 'C'),
  chapterOrTrackRemainingTime('Track remaining time', 'K');

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

  factory Position.fromTimeCodeUpdate(String text) {
    final parts = text.split(' ');
    if (parts.length != 4) {
      throw 'Could not parse time code: $text';
    }
    final title = int.parse(parts[0].trim());
    final chapter = int.parse(parts[1].trim());
    final timeInformation = TimeInformation.fromTypeCode(parts[2].trim());
    final clock = parts[3].trim();
    return Position(title, chapter, timeInformation, clock);
  }
}

enum DirectoryItemType {
  usb('U'),
  opticalDisc('O'),
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

/// Parameters passed to [setHdmiResolution]. This is distict from
/// [VideoResolution] in that it includes not just valid HDMI resolutions, but
/// also conceputal modes like 'auto'.
enum HdmiResolution {
  auto('AUTO', 'Auto'),
  src('SRC', 'Source direct'),
  uhdAuto('UDH_AUTO', 'UHD Auto'),
  udh24('UHD24', 'UHD 24Hz'),
  uhd50('UHD50', 'UHD 50Hz'),
  uhd60('UHD60', 'UHD 60Hz'),
  r1080pAuto('1080P_AUTO', '1080p Auto'),
  r1080p24('1080P24', '1080p 24Hz'),
  r1080p50('1080P50', '1080p 50Hz'),
  r1080p60('1080P60', '1080p 60Hz'),
  r1080i50('1080I50', '1080i 50Hz'),
  r1080i60('1080I60', '1080i 60Hz'),
  r720p50('720P50', '720p 50Hz'),
  r720p60('720P60', '720p 60Hz'),
  r576p('576P', '576p'),
  r576i('576I', '576i'),
  r480p('480P', '480p'),
  r480i('480I', '480i');

  final String typeCode;
  final String displayName;
  const HdmiResolution(this.typeCode, this.displayName);

  factory HdmiResolution.fromTypeCode(String typeCode) {
    try {
      return HdmiResolution.values
          .firstWhere((element) => element.typeCode == typeCode);
    } on StateError {
      throw 'Unknown typeCode for HDMI resolution: $typeCode';
    }
  }
}

enum VideoResolution {
  r480i60('_480I60', '480i 60Hz'),
  r480p60('_480P60', '480p 60Hz'),
  r576i50('_576I50', '576i 50Hz'),
  r576p50('_576P50', '576p 50Hz'),
  r720p50('_720P50', '720p 50Hz'),
  r720p60('_720P60', '720p 60Hz'),
  r1080i50('1080I50', '1080i 50Hz'),
  r1080i60('1080I60', '1080i 60Hz'),
  r1080p23('1080P23', '1080p 23.97Hz'),
  r1080p24('1080P24', '1080p 24Hz'),
  r1080p30('1080P30', '1080p 30Hz'),
  r1080p50('1080P50', '1080p 50Hz'),
  r1080p60('1080P60', '1080p 60Hz'),
  rUhd24('_UHD24_', 'UHD 24Hz'), // Not documented, but observed.
  rUhd30('_UHD30_', 'UHD 30Hz'),
  rUhd50('_UHD50_', 'UHD 50Hz'),
  rUhd60('_UHD60_', 'UHD 60Hz'),
  rOther('_OTHER_', 'Other');

  final String typeCode;
  final String displayName;
  const VideoResolution(this.typeCode, this.displayName);

  factory VideoResolution.fromTypeCode(String typeCode) {
    try {
      return VideoResolution.values
          .firstWhere((element) => element.typeCode == typeCode);
    } on StateError {
      throw 'Unknown typeCode for Video resolution: $typeCode';
    }
  }
}

// The commented out values are ones which are rejected by my UDP-203. Maybe the
// UDP-205 will accept them, but until I know for sure, I'm going to keep them
// commented out.
enum ZoomRatio {
  aspectRatioCorrection('AR', 'Stretch'),
  fullScreen('FS', 'Fullscreen'),
  underScan('US', 'Underscan'),
  // oneQuarter('1/4', '1/4x');
  // oneThird('1/3', '1/3x'),
  oneHalf('1/2', '1/2x'),
  onePointTwoX('1.2', '1.2x'),
  onePointThreeX('1.3', '1.3x'),
  onePointFiveX('1.5', '1.5x'),
  twoX('2', '2x'),
  // threeX('3', '3x'),
  // fourX('4', '4x'),
  oneX('1', 'Off');

  final String typeCode;
  final String displayName;
  const ZoomRatio(this.typeCode, this.displayName);

  factory ZoomRatio.fromTypeCode(String typeCode) {
    try {
      return ZoomRatio.values
          .firstWhere((element) => element.typeCode == typeCode);
    } on StateError {
      throw 'Unknown typeCode for zoom ratio: $typeCode';
    }
  }

  factory ZoomRatio.fromQueryResponse(String text) {
    final parts = text.split(' ');
    int mode;
    try {
      mode = int.parse(parts[0].trim());
    } catch (e) {
      throw 'Could not parse zoom mode response: $text, $e';
    }
    switch (mode) {
      case 0:
        return ZoomRatio.oneX;
      case 1:
        return ZoomRatio.aspectRatioCorrection;
      case 2:
        return ZoomRatio.fullScreen;
      case 3:
        return ZoomRatio.underScan;
      case 4:
        return ZoomRatio.onePointTwoX;
      case 5:
        return ZoomRatio.onePointThreeX;
      case 6:
        return ZoomRatio.onePointFiveX;
      case 7:
        return ZoomRatio.twoX;
      // case 8:
      //   return ZoomRatio.threeX;
      // case 9:
      //   return ZoomRatio.fourX;
      case 10:
        return ZoomRatio.oneHalf;
      // case 11:
      //   return ZoomRatio.oneThird;
      // case 12:
      //   return ZoomRatio.oneQuarter;
      default:
        throw 'Unknown zoom mode code: $mode';
    }
  }
}

enum RepeatMode {
  chapter('CH', 'Chatper'),
  titleOrTrack('TT', 'Title/Track (One)'),
  all('ALL', 'All'),
  shuffle('SHF', 'Shuffle'),
  random('RND', 'Random'),
  one('', 'One'), // Only documented in the QRP response.
  off('OFF', 'Off');

  final String typeCode;
  final String displayName;
  const RepeatMode(this.typeCode, this.displayName);

  factory RepeatMode.fromTypeCode(String typeCode) {
    try {
      return RepeatMode.values
          .firstWhere((element) => element.typeCode == typeCode);
    } on StateError {
      throw 'Unknown typeCode for repeat mode: $typeCode';
    }
  }

  factory RepeatMode.fromQueryResponse(String text) {
    final parts = text.split(' ');
    int mode;
    try {
      mode = int.parse(parts[0].trim());
    } catch (e) {
      throw 'Could not parse repeat mode response: $text, $e';
    }
    switch (mode) {
      case 0:
        return RepeatMode.off;
      case 1:
        return RepeatMode.one;
      case 2:
        return RepeatMode.chapter;
      case 3:
        return RepeatMode.all;
      case 4:
        return RepeatMode.titleOrTrack;
      case 5:
        return RepeatMode.shuffle;
      case 6:
        return RepeatMode.random;
      default:
        throw 'Unknown repeat mode: $mode';
    }
  }
}

enum HdrSetting {
  auto('Auto', 'Auto'),
  on('On', 'Forced'),
  // Only documented for the QHR response.
  stripMetadata('StripMetadata', 'Strip Metadata'),
  // While documented, the off command always fails.
  off('Off', 'Off');

  final String typeCode;
  final String displayName;
  const HdrSetting(this.typeCode, this.displayName);

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
  blurayPlayer('0', 'BD Player'),
  hdmi('1', 'HDMI Input'),
  arc('2', 'HDMI ARC'),
  // 3-5 only available on UDP-205.
  optical('3', 'Optical'),
  coax('4', 'Coax'),
  usb('5', 'USB');

  final String typeCode;
  final String displayName;
  const InputSource(this.typeCode, this.displayName);

  factory InputSource.fromTypeCode(String typeCode) {
    try {
      return InputSource.values
          .firstWhere((element) => element.typeCode == typeCode);
    } on StateError {
      throw 'Unknown typeCode for input source: $typeCode';
    }
  }

  factory InputSource.fromQueryResponse(String text) {
    final parts = text.split(' ');
    int source;
    try {
      source = int.parse(parts[0].trim());
    } catch (e) {
      throw 'Could not parse input source response: $text, $e';
    }
    switch (source) {
      case 0:
        return InputSource.blurayPlayer;
      case 1:
        return InputSource.hdmi;
      case 2:
        return InputSource.arc;
      case 3:
        return InputSource.optical;
      case 4:
        return InputSource.coax;
      case 5:
        return InputSource.usb;
      default:
        throw 'Unknown input source: $source';
    }
  }
}

enum ScreenSaverSetting {
  on('ON', 'On'),
  off('OFF', 'Off'),
  save('SAVE', 'Energy Saver');

  final String typeCode;
  final String displayName;
  const ScreenSaverSetting(this.typeCode, this.displayName);

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
  disc('DIS', 'Disc'),
  music('MUS', 'Music'),
  photo('PHO', 'Photos'),
  movie('MOV', 'Movies'),
  network('NET', 'Network'),
  setup('SET', 'Setup');

  final String typeCode;
  final String displayName;
  const App(this.typeCode, this.displayName);

  factory App.fromTypeCode(String typeCode) {
    try {
      return App.values.firstWhere((element) => element.typeCode == typeCode);
    } on StateError {
      throw 'Unknown typeCode for App: $typeCode';
    }
  }
}

enum SacdPriority {
  multiChannel('M', 'multi-channel'),
  stereo('S', 'stereo'),
  cdMode('C', 'CD');

  final String typeCode;
  final String displayName;
  const SacdPriority(this.typeCode, this.displayName);

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
  dsd('D', 'DSD'),
  pcm('P', 'PCM'),
  auto('A', 'Auto');

  final String typeCode;
  final String displayName;
  const SacdOutputMode(this.typeCode, this.displayName);

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
  unknown('UNKW', 'Unknown'),
  noDisc('NO-DISC', 'No disc'); // Only documented for the QDT command.

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

  factory DiscType.fromQueryResponse(String text) {
    switch (text) {
      case 'BD-MV':
        return DiscType.blueRay;
      case 'DVD-VIDEO':
        return DiscType.dvdVideo;
      case 'DVD-AUDIO':
        return DiscType.dvdAudio;
      case 'DATA-DISC':
        return DiscType.data;
      case 'UNKNOW-DISC':
        return DiscType.unknown;
      default:
        return DiscType.fromTypeCode(text);
    }
  }
}

enum AudioType {
  // The API docs say the typeCode should always be 2 chars, but in the field a
  // typeCode of 'PCM' has been observed when playing back CDs.
  dolbyDigital('DD', 'Dolby Digital'),
  dolbyDigitalPlus('DP', 'DolbyDigitalPlus'),
  dolbyTrueHD('DT', 'Dolby TrueHD'),
  dts('TS', 'DTS'),
  dtsHdHighResolution('TH', 'DTS-HD High Resolution'),
  dtsHdMasterAudio('TM', 'DTS-HD Master Audio'),
  lPcm('PC', 'LPCM'),
  pcm('PCM', 'PCM'), // Not documented, but observed.
  mpegAudio('MP', 'MPEG Audio'),
  cd('CD', 'CD Audio'),
  ac('AC', 'AAC'), // Not documented, but observed.
  dsd('DSD', 'DSD'), // Not documented, but observed.
  flac('FLAC', 'FLAC'), // Not documented, but observed.
  // Meridian Lossless Packing
  mlp('MLP', 'MLP'), // Not documented, but observed (only via HTTP).
  unknown('UN', 'Unknown');

  final String typeCode;
  final String displayName;
  const AudioType(this.typeCode, this.displayName);

  factory AudioType.fromTypeCode(String typeCode) {
    try {
      // Sometimes the player uses DDP instead of DP. :|
      if (typeCode == 'DDP') return AudioType.dolbyDigitalPlus;
      return AudioType.values
          .firstWhere((element) => element.typeCode == typeCode);
    } on StateError {
      throw 'Unknown typeCode for audio type: $typeCode';
    }
  }

  factory AudioType.fromQueryResponse(String text) {
    // I suspect there are way more of these. The API docs only provide a few
    // examples.
    switch (text) {
      case 'AAC':
        return AudioType.ac;
      case 'DTS':
        return AudioType.dts;
      case 'DTS-HD':
        return AudioType.dtsHdHighResolution;
      case 'LPCM':
        return AudioType.lPcm;
      default:
        return AudioType.fromTypeCode(text);
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

  /// A stream of responses from the device which other components listen to.
  /// This is handy for call and response flows where you want to block until
  /// the response has been received.
  // A broadcast stream is used here so functions can start and stop listening.
  final StreamController<Response> _responses =
      StreamController<Response>.broadcast();
  Socket? _socket;
  VerboseMode? verboseMode;
  bool? powered;
  String? firmwareVersion;
  Position? position;
  bool threeDimensional = false;
  PlaybackStatus playbackStatus = PlaybackStatus.unknown;
  int? volume;
  bool? muted;
  DiscType discType = DiscType.unknown;
  AudioType audioType = AudioType.unknown;
  int? currentAudioTrack;
  int? availableAudioTracks;
  String? audioLanguage; // ISO 3166 country codes
  String? audioExtraInfo; // E.g. "44.1/16", "44.1"; The API is inconsistent.
  String? channels;
  int? currentSubtitleTrack;
  int? availableSubtitleTracks;
  String? subtitleLanguage; // ISO 3166 country codes
  int? inputSourceNumber;
  String? inputSourceName;
  AspectRatioSetting? aspectRatioSetting;
  VideoResolution? contentResolution;
  VideoResolution? outputResolution;
  bool? usbIn; // Whether a USB storage device is connected.

  Device(this.name, this.address, this.port);

  /// Clear fields except [playbackStatus].
  ///
  /// This function is used both when [playbackStatus] is
  /// [PlaybackStatus.playbackStopped] and when the player is powered off.
  void _clearFields() {
    audioType = AudioType.unknown;
    currentAudioTrack = null;
    availableAudioTracks = null;
    position = null;
    audioLanguage = null;
    channels = null;
    subtitleLanguage = null;
    currentSubtitleTrack = null;
    availableSubtitleTracks = null;
    contentResolution = null;
    outputResolution = null;
  }

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
    _socket!.setOption(SocketOption.tcpNoDelay, true);
    // Sets encoding for writing strings.
    _socket!.encoding = const AsciiCodec();
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.destroy();
      _socket = null;
      _log.info('Socket destroyed.');
    }
  }

  Stream<String> stream() {
    if (_socket == null) {
      throw 'Cannot return stream. Socket disconnected.';
    }
    return _socket!.transform(ascii.decoder.cast());
  }

  /// Set up the player for communication.
  ///
  /// This method should only be called after [startListener] or some equivalent
  /// method is called.
  Future<void> engage() async {
    if (!await queryPowerStatus()) {
      await powerOn();
      await _waitForPowerOn(const Duration(seconds: 1), 10);
    }
    // Send an ActiveDiscover ping to ensure the HTTP service is enabled on the
    // player.
    final d = ActiveDiscover();
    d.ping();
    d.close();
    await setVerboseMode(VerboseMode.detailed);
    await fetchState();
  }

  Future<void> fetchState() async {
    Future<void> wrapper(Function f) async {
      try {
        await f();
      } catch (e) {
        _log.warning('Error fetching initial state: $e');
      }
    }

    await wrapper(queryPowerStatus); // Useful when reconnecting.
    await wrapper(queryPlaybackStatus);
    await wrapper(queryTrackOrTitle);
    await wrapper(queryDiscType);
    await wrapper(queryAudioType);
    await wrapper(queryVolume); // also fetches muted state
    await wrapper(querySubtitleType);
    await wrapper(queryFirmwareVersion);
    // Note, there's no query functions that return the data that UVO does
    // (in/out HDMI resolution).
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

  /// Listens to inbound packet stream and parses those packets.
  ///
  /// Flutter apps will probably want to implement a function like this inside a
  /// Provider/Consumer system. But for testing this package, it's handy to have
  /// this function.
  // I don't know why this function needs to be async. But if it's not,
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
    // The time code updates are very noisy.
    final level = message.startsWith('@UTC') ? Level.FINE : Level.INFO;
    _log.log(level, 'Received message: $message');
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
      // If part1 is a result code, the player is using verbose mode <=1 and we
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
      _responses.add(
        Response(
            resultCode: resultCode,
            commandCode: commandCode,
            parameters: parameters.isEmpty ? null : parameters),
      );
      _lastCommandTimestamp = null;
      _lastCommandCode = null;
      if (resultCode == ResultCode.error) {
        _log.warning('Got an error with command code $commandCode '
            'with parameters: $parameters');
      }
    }
  }

  void _parseUpdate(String commandCode, String parameters) async {
    switch (commandCode) {
      case 'UPW':
        if (parameters == '1') {
          powered = true;
        } else if (parameters == '0') {
          powered = false;
          playbackStatus = PlaybackStatus.unknown;
          _clearFields();
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
        if (playbackStatus == PlaybackStatus.openTray) {
          discType = DiscType.unknown;
        }
        if (playbackStatus == PlaybackStatus.playbackStopped) {
          _clearFields();
        }
        break;
      case 'UVL':
        VolumeResponse r;
        try {
          r = VolumeResponse.fromString(parameters);
        } catch (e) {
          _log.severe('Unable to parse volume value: $e');
          break;
        }
        muted = r.muted;
        volume = r.volume;
        break;
      case 'UDT':
        try {
          discType = DiscType.fromTypeCode(parameters);
        } catch (e) {
          _log.severe(e);
        }
        break;
      case 'UAT':
        _AudioTypeUpdate update;
        try {
          update = _AudioTypeUpdate.fromUpdateParameters(parameters);
        } on _PcmAudioTypeException {
          audioType = AudioType.pcm;
          break;
        } catch (e) {
          _log.severe(e);
          break;
        }

        audioType = await _correctAudioType(update.type);
        currentAudioTrack = update.currentTrack;
        availableAudioTracks = update.availableTracks;
        audioLanguage = update.language;
        channels = update.channels;
        break;
      case 'UST':
        _SubtitleTypeUpdate update;
        try {
          update = _SubtitleTypeUpdate.fromUpdateParameters(parameters);
        } catch (e) {
          _log.severe(e);
          break;
        }
        currentSubtitleTrack = update.currentTrack;
        availableSubtitleTracks = update.availableTracks;
        subtitleLanguage = update.language;
        break;
      case 'UIS':
        _InputSourceUpdate update;
        try {
          update = _InputSourceUpdate.fromUpdateParameters(parameters);
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
          aspectRatioSetting =
              AspectRatioSetting.fromUpdateParameters(parameters);
        } catch (e) {
          _log.severe(e);
        }
        break;
      case 'UTC':
        position = Position.fromTimeCodeUpdate(parameters);
        if (position?.clock == '00:00:01') {
          // This is a workaround for the player sometimes not knowing the audio
          // type right after a play command is issued. Querying the audio type
          // once playback has confirmed to be started should be more reliable.
          try {
            await queryAudioType();
          } catch (e) {
            // Log and move on. Logging happens inside the call.
          }
          // If this fails, log (happens inside the call) and move on.
          // This is a workaround for the player almost always not updating the
          // playback status once something just started playing.
          try {
            await queryPlaybackStatus();
          } catch (e) {
            // Log and move on. Logging happens inside the call.
          }
          // Workaround not getting track info updates when playback starts in
          // some cases.
          try {
            await queryTrackOrTitle();
          } catch (e) {
            // log
          }
        }
        break;
      case 'UVO':
        _VideoResolutionUpdate update;
        try {
          update = _VideoResolutionUpdate.fromString(parameters);
        } catch (e) {
          _log.severe(e);
          break;
        }
        contentResolution = update.contentResolution;
        outputResolution = update.outputResolution;
        break;
      case 'USB':
        switch (parameters) {
          case 'IN':
            usbIn = true;
            break;
          case 'OU':
            usbIn = false;
            break;
          default:
            usbIn = null;
            break;
        }
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
      if (waiting > const Duration(seconds: 10)) {
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
    Response response = const Response();
    // Because with verboseMode.detailed, we might get unsoliticed responses, we
    // need to check all responses in a loop until we get a response to our last
    // command, or we timeout.
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

  Future<void> stop() async {
    final response = await _rpc('STP');
    // It's been observed that in some cases, when a FULL STOP response is
    // returned, there's no update regarding playback status having changed.
    if (response.parameters == 'FULL STOP') {
      playbackStatus = PlaybackStatus.playbackStopped;
      _clearFields();
    }
  }

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
  /// WARNING: Doesn't get a response on my UDP-203.
  Future<void> angle() async => await _command('ANG');

  /// Zoom in/out and adjust aspect ratio.
  Future<void> zoom() async => await _command('ZOM');

  /// WARNING: Doesn't get a response on my UDP-203.
  Future<void> secondaryAudioProgramToggle() async => await _command('SAP');

  /// Set A/B repeat play points.
  Future<void> repeatAB() async => await _command('ATB');
  Future<void> repeat() async => await _command('RPT');

  /// Picture-in-picture toggle.
  /// WARNING: Doesn't get a response on my UDP-203.
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

  Future<void> inputMenu() async => await _command('SRC');

  /// No operation.
  ///
  /// This command is documented and therefore included. Probably it's only
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

  // WARNING: This is exceptionally janky on my UDP-203. The volume does change,
  // but to a value that is not even close to the input. Maybe it's interpreting
  // the values using a different base, but I failed to see any patterns.
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

  // WARNING: This is mostly non-responsive on my UDP-203. There are plenty of
  // contexts in which it will return an OK result code, but then not act, even
  // when using the IR remote to jump to a time works fine.
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

  /// Opens the "Program Play" menu when playing CDs. Similar to pushing the
  /// yellow button. However, it starts DVD playback over from the beginning.
  /// Since this function is not present on the UDP-203 IR remote, and its
  /// useful functionality seems to be duplicated with other functions, it's
  /// probably best to avoid using this.
  Future<void> directPlay() async => await _command('DPL');

  /// Clear command buffers.
  Future<void> reset() async => await _command('RST');

  Future<void> setSubtitleShift(int shift) async {
    int sanitizedShift = max(shift, -10);
    sanitizedShift = min(sanitizedShift, 10);
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

  // This is very janky on the player. With BDs sometimes the fractional speeds
  // get transposed to whole number speeds. On DVDs, sometimes asking for speed
  // 3 gives you speed 1. It's all over the place.
  Future<void> setForwardPlaybackSpeed(PlaybackSpeed speed) async {
    await _command('FWD', parameters: speed.typeCode);
  }

  // The comment above applies here too.
  Future<void> setReversePlaybackSpeed(PlaybackSpeed speed) async {
    await _command('REV', parameters: speed.typeCode);
  }

  Future<VerboseMode> queryVerboseMode() async {
    final r = await _rpc('QVM');
    final v = VerboseMode.fromTypeCode(r.parameters!);
    verboseMode = v;
    _log.fine('Verbose mode is: ${verboseMode.toString()}');
    return v;
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

  Future<VolumeResponse> queryVolume() async {
    final r = await _rpc('QVL');
    final vr = VolumeResponse.fromString(r.parameters!);
    muted = vr.muted;
    volume = vr.volume;
    return vr;
  }

  /// Queries the current HDMI resolution setting.
  ///
  /// This is distinct from what data is provided by the UVO update packet. UVO
  /// updates tell what the resolution of the content is as well as the current
  /// HDMI output resolution. This function might return something like the HDMI
  /// resolution setting is set to match whatever the source is.
  Future<HdmiResolution> queryHdmiResolution() async {
    final r = await _rpc('QHD');
    return HdmiResolution.fromTypeCode(r.parameters!);
  }

  Future<PlaybackStatus> queryPlaybackStatus() async {
    final r = await _rpc('QPL');
    var p = PlaybackStatus.fromQueryResponse(r.parameters!);
    // Workaround the playback status sometimes returning that the tray is
    // closing continuously.
    if (p == PlaybackStatus.closingTray) {
      final g = await getGlobalInfo();
      if (g.somethingIsPlaying()) {
        p = PlaybackStatus.playbackStarted;
        _log.info('Corrected playback status with HTTP API.');
      }
    }
    playbackStatus = p;
    return p;
  }

  Future<TrackInfo> queryTrackOrTitle() async {
    final r = await _rpc('QTK');
    final ti = TrackInfo.fromString(r.parameters!);
    // Only update the cached value if the returned data appears valid.
    // Sometimes the returned data is 00/00.
    if (ti.currentTrack != 0) {
      currentAudioTrack = ti.currentTrack;
      availableAudioTracks = ti.availableTracks;
    }
    return ti;
  }

  Future<TrackInfo> queryChapter() async {
    final r = await _rpc('QCH');
    final ti = TrackInfo.fromString(r.parameters!);
    if (position != null) {
      position!.chapter = ti.currentTrack;
    }
    return ti;
  }

  Future<String> queryTrackOrTitleElapsedTime() async {
    final r = await _rpc('QTE');
    return _parseClockText(r.parameters!);
  }

  Future<String> queryTrackOrTitleRemainingTime() async {
    final r = await _rpc('QTR');
    return _parseClockText(r.parameters!);
  }

  Future<String> queryChapterElapsedTime() async {
    final r = await _rpc('QCE');
    return _parseClockText(r.parameters!);
  }

  Future<String> queryChapterRemainingTime() async {
    final r = await _rpc('QCR');
    return _parseClockText(r.parameters!);
  }

  Future<String> queryTotalElapsedTime() async {
    final r = await _rpc('QEL');
    return _parseClockText(r.parameters!);
  }

  Future<String> queryTotalRemainingTime() async {
    final r = await _rpc('QRE');
    return _parseClockText(r.parameters!);
  }

  Future<DiscType> queryDiscType() async {
    final r = await _rpc('QDT');
    final d = DiscType.fromQueryResponse(r.parameters!);
    discType = d;
    return d;
  }

  Future<AudioTypeResponse> queryAudioType() async {
    final r = await _rpc('QAT');
    // Sometimes the player doesn't return an audio type parameter but the
    // result code was not an error.
    if (r.parameters == null) {
      audioType = AudioType.unknown;
      return AudioTypeResponse(AudioType.unknown);
    }
    final audioTypeResponse = AudioTypeResponse.fromString(r.parameters!);
    audioType = await _correctAudioType(audioTypeResponse.type);
    // Permit the response to set these values to null. That might be valid.
    currentAudioTrack = audioTypeResponse.currentTrack;
    availableAudioTracks = audioTypeResponse.availableTracks;
    audioLanguage = audioTypeResponse.language;
    audioExtraInfo = audioTypeResponse.extraInfo;
    return audioTypeResponse;
  }

  Future<SubtitleTypeResponse> querySubtitleType() async {
    final r = await _rpc('QST');
    final subtitleTypeResponse = SubtitleTypeResponse.fromString(r.parameters!);
    currentSubtitleTrack = subtitleTypeResponse.currentTrack;
    availableSubtitleTracks = subtitleTypeResponse.availableTracks;
    // Do not set the [subtitleLanguage] attribute since the formatting is not
    // the same in the query response as it is in the update text (E.g. English
    // instead of ENG, at least according to the API doc.). Setting it here
    // might lead to display jank in the UI.
    return subtitleTypeResponse;
  }

  Future<int> querySubtitleShift() async {
    final r = await _rpc('QSH');
    int shift;
    try {
      shift = int.parse(r.parameters!);
    } catch (e) {
      throw 'Could not parse subtitle shift response: ${r.parameters}';
    }
    if (shift < -10 || shift > 10) {
      throw 'Subtitle shift is out of range (-10..10): $shift';
    }
    return shift;
  }

  Future<int> queryOsdPosition() async {
    final r = await _rpc('QOP');
    int osdPosition;
    try {
      osdPosition = int.parse(r.parameters!);
    } catch (e) {
      throw 'Could not parse OSD position response: ${r.parameters}';
    }
    if (osdPosition < 0 || osdPosition > 5) {
      throw 'OSD position is out of range (0..5): $osdPosition';
    }
    return osdPosition;
  }

  Future<RepeatMode> queryRepeatMode() async {
    final r = await _rpc('QRP');
    return RepeatMode.fromQueryResponse(r.parameters!);
  }

  Future<ZoomRatio> queryZoomMode() async {
    final r = await _rpc('QZM');
    return ZoomRatio.fromQueryResponse(r.parameters!);
  }

  Future<HdrSetting> queryHdrSetting() async {
    final r = await _rpc('QHR');
    return HdrSetting.fromTypeCode(r.parameters!);
  }

  Future<bool> query3dStatus() async {
    final r = await _rpc('Q3D');
    if (r.parameters == '3D') {
      threeDimensional = true;
      return true;
    }
    threeDimensional = false;
    return false;
  }

  Future<HdrStatus> queryHdrStatus() async {
    final r = await _rpc('QHS');
    return HdrStatus.fromTypeCode(r.parameters!);
  }

  Future<InputSource> queryInputSource() async {
    final r = await _rpc('QIS');
    return InputSource.fromQueryResponse(r.parameters!);
  }

  /// WARNING: broken
  /// The API docs show the response format for this command to be
  /// violating their documented response structure Their example shows
  /// QC1 and QC2 prefixed before the result code. And indeed, the QCD command
  /// returns TWO responses, one prefixed with QC1 (CDDB1 probably) and QC2
  /// (CDBB2 probably). The low-level functions in this module currently do not
  /// allow for a command to return two responses nor a response that's not
  /// prefixed with the command code sent in the request.
  Future<String> queryCddbNumber() async {
    final r = await _rpc('QCD');
    return r.parameters!;
  }

  /// WARNING: partially broken
  /// Tested with SMB: Returns ER INVALID.
  /// Tested with DLNA: OK
  Future<String> queryMediaFileFormat() async {
    final r = await _rpc('QFT');
    return r.parameters!;
  }

  /// WARNING: broken
  /// Tested with SMB: Returns ER INVALID.
  /// Tested with DLNA: No response.
  Future<String> queryMediaFileName() async {
    final r = await _rpc('QFN');
    return r.parameters!;
  }

  /// WARNING: partially broken
  /// Tested with SMB: Returns ER INVALID.
  /// Tested with DLNA: OK
  Future<String> queryTrackName() async {
    final r = await _rpc('QTN');
    return r.parameters!;
  }

  /// WARNING: partially broken
  /// Tested with SMB: Returns ER INVALID.
  /// Tested with DLNA: OK (truncated)
  Future<String> queryTrackAlbum() async {
    final r = await _rpc('QTA');
    return r.parameters!;
  }

  /// WARNING: partially broken
  /// Tested with SMB: Returns ER INVALID.
  /// Tested with DLNA: OK
  Future<String> queryTrackPerformer() async {
    final r = await _rpc('QTP');
    return r.parameters!;
  }

  Future<AspectRatioSetting> queryAspectRatio() async {
    final r = await _rpc('QAR');
    return AspectRatioSetting.fromQueryResponse(r.parameters!);
  }

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

  String get _httpAuthority => '${address.address}:$_httpPort';
  Uri _uri(String path) => Uri.http(_httpAuthority, path);

  // TODO - This is likely an anti-pattern. The logger might not print which
  // class/method really logged the message. And generally having to both log
  // and throw makes it seem like there's a layering violation someplace.
  void _logAndThrow(String message, [Level level = Level.WARNING]) {
    _log.log(level, message);
    throw (message);
  }

  dynamic _httpRpc(String path) async {
    _log.info('Making HTTP RPC to $path');
    final response = await http.get(_uri(path));
    if (response.statusCode != 200) {
      _logAndThrow('Received HTTP status: ${response.statusCode}');
    }
    final data = jsonDecode(response.body);
    _log.info('HTTP response: ${response.body}');
    if (!data['success']) {
      _logAndThrow('JSON response reports failure.');
    }
    return jsonDecode(response.body);
  }

  Future<Id3Info> getMusicLocalId3Info() async {
    final data = await _httpRpc('getmusiclocalid3info');
    final id3info = data['userdata'];
    return Id3Info(
      title: id3info['title'],
      artist: id3info['artist'],
      album: id3info['album'],
      // 'year' is sometimes an int, sometimes a String.
      year: id3info['year'].toString(),
    );
  }

  Future<List<AudioTrack>> getAudioMenuList() async {
    final data = await _httpRpc('getaudiomenulist');
    List<AudioTrack> ret = [];
    for (final a in data['audio_list']) {
      ret.add(AudioTrack(a['name'], a['index'], a['selected']));
    }
    return ret;
  }

  Future<GlobalInfo> getGlobalInfo() async {
    final data = await _httpRpc('getglobalinfo');
    return GlobalInfo(
      isAudioPlaying: data['is_audio_playing'],
      isPicPlaying: data['is_pic_playing'],
      isVideoPlaying: data['is_video_playing'],
      isBdmvPlaying: data['is_bdmv_playing'],
      isDiscPlaying: data['is_disc_playing'],
    );
  }

  /// Workaround getting the wrong [AudioType] from the serial API.
  ///
  /// Workaround the serial API returning the wrong audio type when it's
  /// Dolby TrueHD. The HTTP API can provide the correct audio type. But
  /// the HTTP API doesn't work in many cases, so we're only using it for
  /// this workaround.
  Future<AudioType> _correctAudioType(AudioType audioType) async {
    _log.fine('Reported AudioType is ${audioType.displayName}');
    if (audioType == AudioType.dolbyDigital ||
        audioType == AudioType.unknown ||
        audioType == AudioType.dtsHdHighResolution) {
      try {
        final audioTracks = await getAudioMenuList();
        _log.fine('Fetched audio menu list.');
        for (final track in audioTracks) {
          if (track.selected) {
            _log.fine('Found selected track.');
            if (track.name.contains('Dolby TrueHD')) {
              _log.info('Corrected audio type to Dolby TrueHD.');
              return AudioType.dolbyTrueHD;
            }
            if (track.name.contains('MLP')) {
              _log.info('Corrected audio type to MLP.');
              return AudioType.mlp;
            }
            if (track.name.contains('DTS-HD MA')) {
              _log.info('Corrected audio type to DTS-HD MA.');
              return AudioType.dtsHdMasterAudio;
            }
            if (track.name.contains('FLAC')) {
              _log.info('Corrected audio type to FLAC.');
              return AudioType.flac;
            }
          } else {
            continue;
          }
        }
      } catch (e) {
        _log.warning('Failed to apply bad audio type workaround: $e');
      }
    }
    return audioType;
  }
}

class _AudioTypeUpdate {
  final AudioType type;
  final int currentTrack;
  final int availableTracks;
  final String language;
  final String channels;

  _AudioTypeUpdate(this.type, this.currentTrack, this.availableTracks,
      this.language, this.channels);

  factory _AudioTypeUpdate.fromUpdateParameters(String parameters) {
    final parts = parameters.split(' ');
    final type = AudioType.fromTypeCode(parts[0].trim());
    if (type == AudioType.pcm) {
      throw _PcmAudioTypeException(
          'The PCM audio type update does not include any other fields normally in a UAT message');
    }
    TrackInfo trackInfo;
    try {
      trackInfo = TrackInfo.fromString(parts[1]);
    } catch (e) {
      throw 'Could not parse track info from audio type update: $parameters';
    }
    final language = parts[2].trim();
    final channels = parts[3].trim();
    return _AudioTypeUpdate(
      type,
      trackInfo.currentTrack,
      trackInfo.availableTracks,
      language,
      channels,
    );
  }
}

class _PcmAudioTypeException implements Exception {
  final String message;

  _PcmAudioTypeException(this.message);
}

class _SubtitleTypeUpdate {
  final int currentTrack;
  final int availableTracks;
  final String language;

  _SubtitleTypeUpdate(this.currentTrack, this.availableTracks, this.language);

  factory _SubtitleTypeUpdate.fromUpdateParameters(String parameters) {
    final parts = parameters.split(' ');
    if (parts.length != 2) {
      throw 'Could not parse subtitle type update: $parameters';
    }
    TrackInfo trackInfo;
    try {
      trackInfo = TrackInfo.fromString(parts[0]);
    } catch (e) {
      throw 'Could not parse track info from subtitle type update: $parameters';
    }
    final language = parts[1].trim();
    return _SubtitleTypeUpdate(
        trackInfo.currentTrack, trackInfo.availableTracks, language);
  }
}

class _InputSourceUpdate {
  final int inputSourceNumber;
  final String inputSourceName;

  _InputSourceUpdate(this.inputSourceNumber, this.inputSourceName);

  factory _InputSourceUpdate.fromUpdateParameters(String parameters) {
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
    return _InputSourceUpdate(inputSourceNumber, inputSourceName);
  }
}

class _VideoResolutionUpdate {
  final VideoResolution contentResolution;
  final VideoResolution outputResolution;

  _VideoResolutionUpdate(this.contentResolution, this.outputResolution);

  factory _VideoResolutionUpdate.fromString(String text) {
    final parts = text.split(' ');
    if (parts.length != 2 ||
        parts[0].trim().length != 7 ||
        parts[1].trim().length != 7) {
      throw 'Could not parse video resolution update: $text';
    }
    final contentResolution = VideoResolution.fromTypeCode(parts[0].trim());
    final outputResolution = VideoResolution.fromTypeCode(parts[1].trim());
    return _VideoResolutionUpdate(contentResolution, outputResolution);
  }
}

class VolumeResponse {
  final bool muted;
  final int? volume;

  VolumeResponse({required this.muted, this.volume});

  factory VolumeResponse.fromString(String text) {
    if (text == 'MUT') {
      return VolumeResponse(muted: true);
    } else if (text == 'UMT') {
      // 'UMT' is not a documented parameter for UVL, but it's been seen in
      // the wild, in particular when the unit is powered off. It is assumed
      // it means unmuted. Which seems like a strange state to enter when
      // powered off.
      return VolumeResponse(muted: false);
    }
    try {
      return VolumeResponse(muted: false, volume: int.parse(text));
    } catch (e) {
      throw 'Unable to parse volume value: $e';
    }
  }
}

class TrackInfo {
  final int currentTrack;
  final int availableTracks;

  TrackInfo(this.currentTrack, this.availableTracks);

  factory TrackInfo.fromString(String text) {
    final trackInfo = text.split('/').map(int.parse).toList();
    if (trackInfo.length != 2) throw 'Too many segments in track info: $text';
    return TrackInfo(trackInfo[0], trackInfo[1]);
  }
}

bool validateClockText(String text) {
  final segments = text.split(':');
  if (segments.length != 3) return false;
  for (final s in segments) {
    if (s.length > 2 || !RegExp(r'^[0-9]+$').hasMatch(s)) {
      return false;
    }
  }
  return true;
}

String _parseClockText(String text) {
  if (validateClockText(text)) {
    return text;
  } else {
    throw 'Could not parse clock text: $text';
  }
}

class AudioTypeResponse {
  AudioType type;
  int? currentTrack;
  int? availableTracks;
  String? language;
  String? extraInfo;

  AudioTypeResponse(this.type);

  factory AudioTypeResponse.fromString(String parameters) {
    _log.fine('Audio type response paramaters: $parameters');
    final parts = parameters.split(' ');
    var r = AudioTypeResponse(AudioType.unknown);
    TrackInfo? trackInfo;
    if (parts.length > 1) {
      r = AudioTypeResponse(AudioType.fromQueryResponse(parts[0]));
      try {
        trackInfo = TrackInfo.fromString(parts[1].trim());
        r.currentTrack = trackInfo.currentTrack;
        r.availableTracks = trackInfo.availableTracks;
        // If the text includes valid track info it will sometimes also include
        // a language token.
        if (parts.length == 3) r.language = parts[2].trim();
      } catch (e) {
        // When playing a CD, sometimes we get parameter text like 'PCM 44.1/16'
        // not track info and language. When playing a FLAC over DLNA, sometimes
        // the text is like 'FLAC 44.1'.
        _log.info('Audio type response did not include track info. '
            'Asigning given parameters to "extraInfo".');
        r.extraInfo = parts.sublist(1).join(' ');
      }
    } else {
      final parameter = parts[0].trim();
      // Getting a single parameter back might mean we only got track info.
      try {
        trackInfo = TrackInfo.fromString(parameter);
        r.currentTrack = trackInfo.currentTrack;
        r.availableTracks = trackInfo.availableTracks;
      } catch (_) {
        // Move on to the next way to parse.
      }

      // Sometimes we only get back the audio type itself.
      try {
        r = AudioTypeResponse(AudioType.fromTypeCode(parameter));
      } catch (_) {
        // Move on to the next way to parse.
      }
    }
    return r;
  }
}

class SubtitleTypeResponse {
  String language;
  int? currentTrack;
  int? availableTracks;

  SubtitleTypeResponse(this.language);

  factory SubtitleTypeResponse.fromString(String parameters) {
    if (parameters.toLowerCase() == 'subtitle off') {
      return SubtitleTypeResponse('OFF');
    }
    final parts = parameters.split(' ');
    if (parts.length == 1) return SubtitleTypeResponse(parts[0].trim());
    if (parts.length == 2) {
      final r = SubtitleTypeResponse(parts[1].trim());
      final trackInfo = TrackInfo.fromString(parts[0].trim());
      r.currentTrack = trackInfo.currentTrack;
      r.availableTracks = trackInfo.availableTracks;
      return r;
    } else {
      throw 'Could not parse subtitle type response: $parameters';
    }
  }
}

enum HdrStatus {
  hdr('HDR'),

  /// Returned if [HdrSetting] is [HdrSetting.off] or
  /// [HdrSetting.stripMetadata].
  sdr('SDR'),
  dov('DOV'); // I don't know what DOV means.

  final String typeCode;
  const HdrStatus(this.typeCode);

  factory HdrStatus.fromTypeCode(String typeCode) {
    for (final status in HdrStatus.values) {
      if (status.typeCode == typeCode) return status;
    }
    throw 'Unknown HDR status type code: $typeCode';
  }
}

class Id3Info {
  final String title;
  final String artist;
  final String album;
  final String year;

  const Id3Info(
      {this.title = '', this.artist = '', this.album = '', this.year = ''});

  bool get isEmpty {
    return [title, artist, album, year].every((element) => element.isEmpty);
  }
}

class AudioTrack {
  final String name;
  final int index;
  final bool selected;

  const AudioTrack(this.name, this.index, this.selected);
}

class GlobalInfo {
  final bool isAudioPlaying;
  final bool isPicPlaying;
  final bool isVideoPlaying;
  final bool isBdmvPlaying;
  final bool isDiscPlaying;

  const GlobalInfo({
    required this.isAudioPlaying,
    required this.isPicPlaying,
    required this.isVideoPlaying,
    required this.isBdmvPlaying,
    required this.isDiscPlaying,
  });

  bool somethingIsPlaying() {
    return [
      isAudioPlaying,
      isPicPlaying,
      isVideoPlaying,
      isBdmvPlaying,
      isDiscPlaying,
    ].any((element) => element == true);
  }
}

class FakeDevice extends Device {
  final _fakeStream = StreamController<String>();
  Duration _fakeClock = Duration.zero;
  final AudioType _fakeAudioType = AudioType.dolbyTrueHD;
  final int _fakeCurrentAudioTrack = 1;
  final int _fakeAvailableAudioTracks = 2;
  final String _fakeChannels = '7.1';
  final int _fakeCurrentSubtitleTrack = 1;
  final int _fakeAvailableSubtitleTracks = 5;
  final String _fakeSubtitleLanguage = 'ENG';
  final AspectRatioSetting _fakeAspectRatioSetting = AspectRatioSetting(
    AspectRatio.ratio16x9,
    AspectRatioMode.wideAuto,
    AspectRatioPlayback.wide,
  );
  final VideoResolution _fakeContentResolution = VideoResolution.r1080p24;
  final VideoResolution _fakeOutputResolution = VideoResolution.rUhd24;
  int _subtitleShift = 0;
  int _osdPosition = 0;

  FakeDevice(super.name, super.address, super.port) {
    powered = true;
    firmwareVersion = 'fake-1.0.0';
    audioType = _fakeAudioType;
    currentAudioTrack = _fakeCurrentAudioTrack;
    availableAudioTracks = _fakeAvailableAudioTracks;
    channels = _fakeChannels;
    currentSubtitleTrack = _fakeCurrentSubtitleTrack;
    availableSubtitleTracks = _fakeAvailableSubtitleTracks;
    subtitleLanguage = _fakeSubtitleLanguage;
    aspectRatioSetting = _fakeAspectRatioSetting;
    contentResolution = _fakeContentResolution;
    outputResolution = _fakeOutputResolution;
    playbackStatus = PlaybackStatus.playbackStarted;
    setupPositionUpdates();
  }

  void setupPositionUpdates() async {
    await for (final _ in Stream.periodic(const Duration(seconds: 1))) {
      if (playbackStatus == PlaybackStatus.playbackStarted ||
          playbackStatus == PlaybackStatus.fastForward1 ||
          playbackStatus == PlaybackStatus.fastReverse1) {
        if (playbackStatus == PlaybackStatus.fastReverse1) {
          _fakeClock -= const Duration(seconds: 3);
        } else if (playbackStatus == PlaybackStatus.fastForward1) {
          _fakeClock += const Duration(seconds: 3);
        } else {
          _fakeClock += const Duration(seconds: 1);
        }

        // Restore the fake values for things which get cleared when playback is
        // stopped.
        audioType = _fakeAudioType;
        currentAudioTrack = _fakeCurrentAudioTrack;
        availableAudioTracks = _fakeAvailableAudioTracks;
        channels = _fakeChannels;
        currentSubtitleTrack = _fakeCurrentSubtitleTrack;
        availableSubtitleTracks = _fakeAvailableSubtitleTracks;
        subtitleLanguage = _fakeSubtitleLanguage;
        aspectRatioSetting = _fakeAspectRatioSetting;
        contentResolution = _fakeContentResolution;
        outputResolution = _fakeOutputResolution;

        final paddedCurrentAudioTrack =
            currentAudioTrack.toString().padLeft(3, '0');
        final paddedAvailableAudioTracks =
            availableAudioTracks.toString().padLeft(3, '0');
        final paddedHours = _fakeClock.inHours.toString().padLeft(2, '0');
        final paddedMinutes =
            (_fakeClock.inMinutes % 60).toString().padLeft(2, '0');
        final paddedSeconds =
            (_fakeClock.inSeconds % 60).toString().padLeft(2, '0');
        _fakeStream
            .add('@UTC $paddedCurrentAudioTrack $paddedAvailableAudioTracks C '
                '$paddedHours:$paddedMinutes:$paddedSeconds');
      }
    }
  }

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> engage() async {}

  @override
  Stream<String> stream() async* {
    await for (final event in _fakeStream.stream) {
      yield event;
    }
  }

  @override
  Future<void> _command(String code, {String parameters = ''}) async {
    _log.fine('FakeDevice command: $code $parameters');
  }

  @override
  Future<Id3Info> getMusicLocalId3Info() async {
    return const Id3Info(
      album: 'Piano Man',
      artist: 'Billy Joel',
      title: 'Piano Man',
      year: '1974',
    );
  }

  @override
  Future<void> play() async => _fakeStream.add('@UPL PLAY');

  @override
  Future<void> pause() async {
    if (playbackStatus == PlaybackStatus.playbackPaused) {
      _fakeStream.add('@UPL PLAY');
    } else if (playbackStatus == PlaybackStatus.playbackStopped) {
      // do nothing 
    } else {
      _fakeStream.add('@UPL PAUS');
    }
  }

  @override
  Future<void> stop() async {
    _fakeStream.add('@UPL STOP');
    _fakeClock = Duration.zero;
  }

  @override
  Future<void> forward() async {
    _fakeStream.add('@UPL FFW1');
  }

  @override
  Future<void> reverse() async {
    _fakeStream.add('@UPL FRV1');
  }

  @override
  Future<void> powerOn() async {
    _fakeStream.add('@UPW 1');
    // Yes, stopped. This is so the UI will display some playback status icon.
    playbackStatus = PlaybackStatus.playbackStopped;
  }

  @override
  Future<void> powerOff() async {
    _fakeStream.add('@UPW 0');
    playbackStatus = PlaybackStatus.playbackStopped;
    _fakeClock = Duration.zero;
    position = null;
  }

  @override
  Future<int> querySubtitleShift() async => _subtitleShift;

  @override
  Future<void> setSubtitleShift(int shift) async {
    _subtitleShift = shift;
  }

  @override
  Future<int> queryOsdPosition() async => _osdPosition;

  @override
  Future<void> setOsdPosition(int position) async {
    _osdPosition = position;
  }
}
