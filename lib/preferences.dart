import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'oppo.dart' as oppo;

const String _settingLastDeviceName = 'lastDeviceName';
const String _settingLastDeviceAddress = 'lastDeviceAddress';
const String _settingLastDevicePort = 'lastDevicePort';

final _log = Logger('preferences');

/// Record the last device we connected to.
/// 
/// This function exists instead of a bunch of setters in the [Preferences]
/// class because setters can't be async.
Future<void> saveLastDevice(oppo.OppoID id) async {
  final p = await SharedPreferences.getInstance();
  await p.setString(_settingLastDeviceName, id.name);
  await p.setString(_settingLastDeviceAddress, id.address.address);
  await p.setInt(_settingLastDevicePort, id.port);
  _log.info('Saved last device: ${id.address.address}');
}

class Preferences {
  final SharedPreferences _sharedPreferences;

  const Preferences(this._sharedPreferences);

  String? get lastDeviceName =>
      _sharedPreferences.getString(_settingLastDeviceName);

  String? get lastDeviceAddress =>
      _sharedPreferences.getString(_settingLastDeviceAddress);

  int? get lastDevicePort => _sharedPreferences.getInt(_settingLastDevicePort);
}
