import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../models/app_user.dart';
import 'api_client.dart';
import 'token_storage.dart';

/// Authentification via le backend Baymore (JWT) — remplace Firebase Auth.
class AuthService {
  final ApiClient _api = ApiClient();

  Future<AppUser> registerWithEmail({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? referralCode,
  }) async {
    final data = await _api.post('/auth/register', data: {
      'name': name, 'email': email, 'phone': phone, 'password': password,
      if (referralCode != null && referralCode.isNotEmpty) 'referralCode': referralCode,
    });
    await TokenStorage.save(accessToken: data['accessToken'], refreshToken: data['refreshToken']);
    final user = AppUser.fromJson(data['user']);
    await OneSignal.login(user.uid);
    return user;
  }

  Future<AppUser> loginWithEmail({required String email, required String password}) async {
    final data = await _api.post('/auth/login', data: {'email': email, 'password': password});
    await TokenStorage.save(accessToken: data['accessToken'], refreshToken: data['refreshToken']);
    final user = AppUser.fromJson(data['user']);
    await OneSignal.login(user.uid);
    return user;
  }

  Future<AppUser?> fetchProfile() async {
    try {
      final data = await _api.get('/auth/me');
      return AppUser.fromJson(data['user']);
    } on ApiException {
      return null;
    }
  }

  Future<void> updateProfile({String? name, String? phone}) => _api.patch('/auth/me', data: {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
      });

  Future<void> deleteAccount() => _api.delete('/auth/me');

  Future<void> signOut() async {
    await OneSignal.logout();
    await TokenStorage.clear();
  }

  Future<bool> hasSession() async => (await TokenStorage.accessToken) != null;
}
