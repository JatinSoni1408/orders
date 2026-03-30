import 'local_storage_stub.dart'
    if (dart.library.io) 'local_storage_io.dart'
    as impl;

abstract class AppLocalStore {
  Future<String?> getString(String key);

  Future<void> setString(String key, String value);

  Future<void> remove(String key);
}

Future<AppLocalStore> createAppLocalStore() => impl.createAppLocalStore();
