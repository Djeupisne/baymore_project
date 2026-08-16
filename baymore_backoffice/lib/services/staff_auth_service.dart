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

      try {
        await OneSignal.login(user.id);
        SocketService().joinStaffRoom();
      } catch (e) {
        print('⚠️ OneSignal non disponible: $e');
      }

      _authController.add(user);
    } catch (e) {
      print('❌ Erreur restoreSession: $e');
      await TokenStorage.clear();
      _authController.add(null);
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      print('🔑 Tentative de connexion pour: $email');
      final data = await _api.post('/auth/staff/login', data: {'email': email, 'password': password});
      print('✅ Données reçues: $data');

      final accessToken = data['accessToken'];
      final refreshToken = data['refreshToken'];

      if (accessToken == null || refreshToken == null) {
        print('❌ Tokens manquants dans la réponse!');
        return null;
      }

      await TokenStorage.save(accessToken: accessToken, refreshToken: refreshToken);
      final user = StaffUser.fromJson(data['user']);
      print('👤 Utilisateur: ${user.email} (${user.name})');

      try {
        await OneSignal.login(user.id);
        SocketService().joinStaffRoom();
      } catch (e) {
        print('⚠️ OneSignal non disponible: $e');
      }

      _authController.add(user);
      return user.name;
    } on ApiException catch (e) {
      print('❌ ApiException: ${e.message} (status: ${e.statusCode})');
      return null;
    } catch (e) {
      print('❌ Erreur inconnue: $e');
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await OneSignal.logout();
    } catch (e) {
      print('⚠️ OneSignal non disponible: $e');
    }
    await TokenStorage.clear();
    _authController.add(null);
  }

  Future<void> clearSession() async {
    await TokenStorage.clear();
    _authController.add(null);
  }
}