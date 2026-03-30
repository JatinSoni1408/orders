import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import 'local_storage.dart';

const String _windowsLocalStoreFileName = 'shared_preferences.json';

Future<AppLocalStore> createAppLocalStore() async {
  final preferences = await SharedPreferences.getInstance();
  if (Platform.isWindows) {
    return _WindowsExecutableDirectoryLocalStore(preferences);
  }
  return _SharedPreferencesAppLocalStore(preferences);
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

class _WindowsExecutableDirectoryLocalStore implements AppLocalStore {
  _WindowsExecutableDirectoryLocalStore(this._fallbackPreferences);

  final SharedPreferences _fallbackPreferences;
  Map<String, Object?>? _cache;
  bool _migrationChecked = false;

  File get _storageFile {
    final executableDirectory = File(Platform.resolvedExecutable).parent.path;
    return File(
      '$executableDirectory${Platform.pathSeparator}$_windowsLocalStoreFileName',
    );
  }

  @override
  Future<String?> getString(String key) async {
    try {
      final data = await _readAll();
      final value = data[key];
      return value is String ? value : null;
    } catch (_) {
      return _fallbackPreferences.getString(key);
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      final data = await _readAll();
      if (!data.containsKey(key)) {
        return;
      }
      data.remove(key);
      await _writeAll(data);
    } catch (_) {
      await _fallbackPreferences.remove(key);
    }
  }

  @override
  Future<void> setString(String key, String value) async {
    try {
      final data = await _readAll();
      data[key] = value;
      await _writeAll(data);
    } catch (_) {
      await _fallbackPreferences.setString(key, value);
    }
  }

  Future<Map<String, Object?>> _readAll() async {
    if (_cache != null) {
      return _cache!;
    }

    final file = _storageFile;
    if (!file.existsSync()) {
      await _migrateFromSharedPreferencesIfNeeded(file);
      if (!file.existsSync()) {
        _cache = <String, Object?>{};
        return _cache!;
      }
    }

    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      _cache = <String, Object?>{};
      return _cache!;
    }

    final decoded = jsonDecode(content);
    if (decoded is Map<String, dynamic>) {
      _cache = Map<String, Object?>.from(decoded);
      return _cache!;
    }
    if (decoded is Map) {
      _cache = decoded.map((key, value) => MapEntry(key.toString(), value));
      return _cache!;
    }

    _cache = <String, Object?>{};
    return _cache!;
  }

  Future<void> _writeAll(Map<String, Object?> data) async {
    final file = _storageFile;
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    await file.writeAsString(jsonEncode(data));
    _cache = Map<String, Object?>.from(data);
  }

  Future<void> _migrateFromSharedPreferencesIfNeeded(File targetFile) async {
    if (_migrationChecked) {
      return;
    }
    _migrationChecked = true;

    final keys = _fallbackPreferences.getKeys();
    if (keys.isEmpty) {
      return;
    }

    final migratedValues = <String, Object?>{};
    for (final key in keys) {
      final value = _fallbackPreferences.get(key);
      if (value is String ||
          value is bool ||
          value is int ||
          value is double ||
          value is List<String>) {
        migratedValues[key] = value;
      }
    }

    if (migratedValues.isEmpty) {
      return;
    }

    if (!targetFile.existsSync()) {
      targetFile.createSync(recursive: true);
    }
    await targetFile.writeAsString(jsonEncode(migratedValues));
    _cache = Map<String, Object?>.from(migratedValues);
  }
}
