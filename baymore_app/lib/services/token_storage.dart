import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stockage chiffré des jetons de session (remplace la gestion de session
/// automatique de Firebase Auth).
class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _accessKey = 'baymore_access_token';
  static const _refreshKey = 'baymore_refresh_token';

  static Future<void> save({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  static Future<void> saveAccessToken(String accessToken) async {
    await _storage.write(key: _accessKey, value: accessToken);
  }

  static Future<String?> get accessToken => _storage.read(key: _accessKey);
  static Future<String?> get refreshToken => _storage.read(key: _refreshKey);

  static Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
