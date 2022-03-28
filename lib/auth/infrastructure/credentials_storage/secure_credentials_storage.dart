import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oauth2/oauth2.dart';
import 'credentials_storage.dart';

class SecureCredentialsStorage implements CredentialsStorage {
  final FlutterSecureStorage _storage;

  SecureCredentialsStorage(this._storage);

  static const _key = 'oauth2_credentials';

  Credentials? _cachedCredentials;

  @override
  Future<Credentials?> read() async {
    if (_cachedCredentials != null) {
      return _cachedCredentials;
    }

    final json = await _storage.read(key: _key);

    if (json == null) {
      return null;
    }

    //if the json is malformed, we will take as if the user is not
    //authenticated.
    try {
      return _cachedCredentials = Credentials.fromJson(json);
    } on FormatException {
      log('Format Exception on reading credentials');
      return null;
    }
  }

  @override
  Future<void> save(Credentials credentials) {
    //here we will always cache the credentials in order to be able to
    //access them while not having closed the app.
    _cachedCredentials = credentials;

    return _storage.write(key: _key, value: credentials.toJson());
  }

  @override
  Future<void> clear() {
    _cachedCredentials = null;
    return _storage.delete(key: _key);
  }
}
