import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oppo/oppo.dart' as oppo;

const String _kSettingLastDeviceName = 'lastDeviceName';
const String _kSettingLastDeviceAddress = 'lastDeviceAddress';
const String _kSettingLastDevicePort = 'lastDevicePort';

final _log = Logger('preferences');

/// Record the last device we connected to.
/// 
/// This function exists instead of a bunch of setters in the [Preferences]
/// class because setters can't be async.
Future<void> saveLastDevice(oppo.OppoID id) async {
  final p = await SharedPreferences.getInstance();
  await p.setString(_kSettingLastDeviceName, id.name);
  await p.setString(_kSettingLastDeviceAddress, id.address.address);
  await p.setInt(_kSettingLastDevicePort, id.port);
  _log.info('Saved last device: ${id.address.address}');
}

Future<bool> clearLastDevice() async {
  final p = await SharedPreferences.getInstance();
  return await p.clear();
}

class Preferences {
  final SharedPreferences _sharedPreferences;

  const Preferences(this._sharedPreferences);

  String? get lastDeviceName =>
      _sharedPreferences.getString(_kSettingLastDeviceName);

  String? get lastDeviceAddress =>
      _sharedPreferences.getString(_kSettingLastDeviceAddress);

  int? get lastDevicePort => _sharedPreferences.getInt(_kSettingLastDevicePort);
}
