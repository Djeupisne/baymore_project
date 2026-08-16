import 'dart:convert';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AppNotification {
  final String title;
  final String body;
  final DateTime receivedAt;
  bool read;

  AppNotification({required this.title, required this.body, required this.receivedAt, this.read = false});

  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
        'receivedAt': receivedAt.toIso8601String(),
        'read': read,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        receivedAt: DateTime.tryParse(json['receivedAt'] as String? ?? '') ?? DateTime.now(),
        read: json['read'] as bool? ?? false,
      );
}

/// Initialise OneSignal — remplace Firebase Cloud Messaging. L'association
/// d'un appareil à un compte Baymore précis se fait via `OneSignal.login`
/// (appelé dans AuthService à la connexion/inscription) : le backend
/// cible ensuite directement l'utilisateur par son id, sans jeton à gérer
/// côté app.
///
/// Les notifications reçues sont aussi enregistrées localement (SharedPreferences)
/// pour alimenter l'écran "Notifications" accessible depuis l'accueil, OneSignal
/// n'exposant pas d'historique consultable côté client.
class NotificationService {
  static const _storageKey = 'baymore_notifications_history';
  static final List<void Function()> _listeners = [];

  void init() {
    OneSignal.initialize(ApiConfig.oneSignalAppId);
    OneSignal.Notifications.requestPermission(true);

    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      _store(event.notification.title ?? 'Baymore', event.notification.body ?? '');
      event.notification.display();
    });

    OneSignal.Notifications.addClickListener((event) {
      _store(event.notification.title ?? 'Baymore', event.notification.body ?? '');
    });
  }

  static void addListener(void Function() cb) => _listeners.add(cb);
  static void removeListener(void Function() cb) => _listeners.remove(cb);

  Future<void> _store(String title, String body) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _readAll(prefs);
    list.insert(0, AppNotification(title: title, body: body, receivedAt: DateTime.now()));
    await prefs.setString(_storageKey, jsonEncode(list.map((n) => n.toJson()).toList()));
    for (final cb in _listeners) {
      cb();
    }
  }

  Future<List<AppNotification>> fetchAll() async {
    final prefs = await SharedPreferences.getInstance();
    return _readAll(prefs);
  }

  Future<List<AppNotification>> _readAll(SharedPreferences prefs) async {
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> markAllRead() async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _readAll(prefs);
    for (final n in list) {
      n.read = true;
    }
    await prefs.setString(_storageKey, jsonEncode(list.map((n) => n.toJson()).toList()));
    for (final cb in _listeners) {
      cb();
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    for (final cb in _listeners) {
      cb();
    }
  }

  Future<int> unreadCount() async {
    final list = await fetchAll();
    return list.where((n) => !n.read).length;
  }
}
