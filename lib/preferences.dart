import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oppo/oppo.dart' as oppo;

const String _settingLastDeviceName = 'lastDeviceName';
const String _settingLastDeviceAddress = 'lastDeviceAddress';
const String _settingLastDevicePort = 'lastDevicePort';
const String _settingLargeModeClock = 'largeModeClock';

final _log = Logger('preferences');

class Preferences {
  final SharedPreferences _sharedPreferences;

  const Preferences(this._sharedPreferences);

  String? get lastDeviceName =>
      _sharedPreferences.getString(_settingLastDeviceName);

  String? get lastDeviceAddress =>
      _sharedPreferences.getString(_settingLastDeviceAddress);

  int? get lastDevicePort => _sharedPreferences.getInt(_settingLastDevicePort);

  // TODO(jpwoodbu) Consider whether it's really OK that all the setters ignore
  // errors. They do this because setters cannot be async.
  set lastDevice(oppo.OppoID id) {
    _sharedPreferences.setString(_settingLastDeviceName, id.name).ignore();
    _sharedPreferences
        .setString(_settingLastDeviceAddress, id.address.address)
        .ignore();
    _sharedPreferences.setInt(_settingLastDevicePort, id.port).ignore();
    _log.info('Saved last device: ${id.address.address}');
  }

  void clearLastDevice() {
    _sharedPreferences.remove(_settingLastDeviceName).ignore();
    _sharedPreferences.remove(_settingLastDeviceAddress).ignore();
    _sharedPreferences.remove(_settingLastDevicePort).ignore();
  }

  bool? get largeModeClock =>
      _sharedPreferences.getBool(_settingLargeModeClock);

  set largeModeClock(bool enabled) {
    _sharedPreferences.setBool(_settingLargeModeClock, enabled).ignore();
  }
}
