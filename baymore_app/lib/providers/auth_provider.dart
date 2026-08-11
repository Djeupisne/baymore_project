import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/token_storage.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();
  AppUser? _profile;
  bool _loading = true;

  AppUser? get profile => _profile;
  bool get isLoggedIn => _profile != null;
  bool get loading => _loading;
  String? get uid => _profile?.uid;

  AuthProvider() {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final hasSession = await _service.hasSession();
    if (hasSession) {
      _profile = await _service.fetchProfile();
      // Un token invalide/expiré sans refresh valide : on repart propre.
      if (_profile == null) await TokenStorage.clear();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? referralCode,
  }) async {
    _profile = await _service.registerWithEmail(name: name, email: email, phone: phone, password: password, referralCode: referralCode);
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    _profile = await _service.loginWithEmail(email: email, password: password);
    notifyListeners();
  }

  Future<void> logout() async {
    await _service.signOut();
    _profile = null;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    _profile = await _service.fetchProfile();
    notifyListeners();
  }
}
