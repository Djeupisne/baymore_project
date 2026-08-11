import 'dart:async';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'api_client.dart';
import 'socket_service.dart';
import 'token_storage.dart';

class StaffUser {
  final String id;
  final String name;
  final String email;
  StaffUser({required this.id, required this.name, required this.email});
  factory StaffUser.fromJson(Map<String, dynamic> json) =>
      StaffUser(id: json['id'], name: json['name'] ?? '', email: json['email'] ?? '');
}

/// Authentifie un membre de l'équipe via le backend Baymore. Le serveur
/// vérifie lui-même que le compte a bien le rôle STAFF (voir POST
/// /auth/staff/login) — refuse toute connexion cliente ici.
class StaffAuthService {
  static final StaffAuthService _instance = StaffAuthService._internal();
  factory StaffAuthService() => _instance;
  StaffAuthService._internal();

  final ApiClient _api = ApiClient();
  final _authController = StreamController<StaffUser?>.broadcast();

  Stream<StaffUser?> get authStateChanges => _authController.stream;

  Future<void> restoreSession() async {
    final token = await TokenStorage.accessToken;
    if (token == null) {
      _authController.add(null);
      return;
    }
    try {
      final data = await _api.get('/auth/me');
      final user = StaffUser.fromJson(data['user']);
      await OneSignal.login(user.id);
      SocketService().joinStaffRoom();
      _authController.add(user);
    } on ApiException {
      await TokenStorage.clear();
      _authController.add(null);
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final data = await _api.post('/auth/staff/login', data: {'email': email, 'password': password});
      await TokenStorage.save(accessToken: data['accessToken'], refreshToken: data['refreshToken']);
      final user = StaffUser.fromJson(data['user']);
      await OneSignal.login(user.id);
      SocketService().joinStaffRoom();
      _authController.add(user);
      return user.name;
    } on ApiException {
      return null;
    }
  }

  Future<void> logout() async {
    await OneSignal.logout();
    await TokenStorage.clear();
    _authController.add(null);
  }
}
