import 'package:shared_preferences/shared_preferences.dart';

import 'local_storage.dart';

Future<AppLocalStore> createAppLocalStore() async {
  return _SharedPreferencesAppLocalStore(await SharedPreferences.getInstance());
}

class _SharedPreferencesAppLocalStore implements AppLocalStore {
  _SharedPreferencesAppLocalStore(this._preferences);

  final SharedPreferences _preferences;

  @override
  Future<String?> getString(String key) async => _preferences.getString(key);

  @override
  Future<void> remove(String key) => _preferences.remove(key);

  @override
  Future<void> setString(String key, String value) =>
      _preferences.setString(key, value);
}
