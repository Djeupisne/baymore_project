import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notifications système LOCALES — déclenchées directement par l'app quand
/// elle détecte un événement en temps réel (via Socket.io, déjà utilisé pour
/// le suivi de commande), sans passer par le serveur push.
///
/// Complète les push OneSignal envoyées par le backend : celles-ci sont
/// indispensables pour prévenir le client quand l'app est complètement
/// fermée, mais nécessitent que le serveur appelle l'API OneSignal à chaque
/// changement de statut (voir la route PATCH /orders/:id/status côté
/// backend). Les notifications locales, elles, fonctionnent dès que l'app
/// tourne (premier plan ou arrière-plan, tant que le socket est connecté) —
/// une sécurité immédiate en attendant/en plus de la configuration serveur.
class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  int _idCounter = 0;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true);
    await _plugin.initialize(const InitializationSettings(android: androidInit, iOS: iosInit));

    const channel = AndroidNotificationChannel(
      'baymore_orders',
      'Suivi de commande',
      description: 'Alertes à chaque étape de la livraison de vos commandes',
      importance: Importance.high,
    );
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
  }

  Future<void> show(String title, String body) async {
    if (!_initialized) await init();
    _idCounter++;
    await _plugin.show(
      _idCounter,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'baymore_orders',
          'Suivi de commande',
          channelDescription: 'Alertes à chaque étape de la livraison de vos commandes',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
