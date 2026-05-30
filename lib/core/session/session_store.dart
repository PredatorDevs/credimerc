import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_session.dart';

class SessionStore {
  SessionStore({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';

  final FlutterSecureStorage _secureStorage;

  Future<AuthSession?> read() async {
    final accessToken = await _secureStorage.read(key: _kAccessToken);
    final refreshToken = await _secureStorage.read(key: _kRefreshToken);

    if (accessToken == null || refreshToken == null) {
      return null;
    }

    return AuthSession(accessToken: accessToken, refreshToken: refreshToken);
  }

  Future<void> write(AuthSession session) async {
    await _secureStorage.write(key: _kAccessToken, value: session.accessToken);
    await _secureStorage.write(key: _kRefreshToken, value: session.refreshToken);
  }

  Future<void> clear() async {
    await _secureStorage.delete(key: _kAccessToken);
    await _secureStorage.delete(key: _kRefreshToken);
  }
}
