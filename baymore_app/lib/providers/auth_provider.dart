import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import '../models/order_status.dart';
import '../services/auth_service.dart';
import '../services/local_notification_service.dart';
import '../services/notification_service.dart';
import '../services/token_storage.dart';
import '../services/socket_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();
  AppUser? _profile;
  bool _loading = true;
  bool _walletListenerBound = false;

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
    _bindWalletListener();
    notifyListeners();
  }

  /// Écoute globale des mises à jour de commande : à chaque étape franchie
  /// (reçue -> prise en charge -> en route -> livrée), le client reçoit une
  /// notification locale immédiate tant que l'app tourne (premier plan ou
  /// arrière-plan, socket connecté). Ceci complète — sans la remplacer — la
  /// notification push OneSignal envoyée par le serveur, seule capable de
  /// réveiller l'app quand elle est totalement fermée.
  /// À "LIVRE" spécifiquement, on rafraîchit aussi le profil car le cashback
  /// et les points fidélité sont crédités côté serveur à ce moment-là.
  void _bindWalletListener() {
    if (_walletListenerBound) return;
    _walletListenerBound = true;
    
    // Rejoindre la room des clients pour recevoir les notifications de promos et catalogues
    SocketService().joinCustomerRoom();
    
    SocketService().socket.on('order:update', (data) {
      try {
        final map = Map<String, dynamic>.from(data);
        if (map['userId'] != _profile?.uid) return;
        final statusStr = map['status'] as String?;
        if (statusStr == null) return;

        final orderId = map['id'] as String?;
        _notifyStatusChange(statusStr, orderId);

        if (statusStr == 'LIVRE') {
          refreshProfile();
        }
      } catch (_) {}
    });

    // Écouter les notifications de codes promo (création, activation, désactivation)
    SocketService().socket.on('promo:notification', (data) {
      try {
        final map = Map<String, dynamic>.from(data);
        final type = map['type'] as String?;
        final title = map['title'] as String? ?? 'Baymore';
        final body = map['body'] as String? ?? '';
        final promoId = map['promoId'] as String?;
        final promoCode = map['promoCode'] as String?;
        
        if (type == null || body.isEmpty) return;
        
        NotificationType notificationType;
        switch (type) {
          case 'promotion':
            notificationType = NotificationType.promotion;
            break;
          case 'promo_disabled':
            notificationType = NotificationType.promoDisabled;
            break;
          default:
            notificationType = NotificationType.promotion;
        }
        
        // Afficher la notification système
        LocalNotificationService().show(title, body);
        
        // Enregistrer dans l'historique
        NotificationService().storePromoNotification(
          title: title,
          body: body,
          type: notificationType,
          promoId: promoId,
          promoCode: promoCode,
        );
      } catch (_) {}
    });

    // Écouter les notifications de nouveaux catalogues
    SocketService().socket.on('catalog:notification', (data) {
      try {
        final map = Map<String, dynamic>.from(data);
        final title = map['title'] as String? ?? 'Baymore';
        final body = map['body'] as String? ?? '';
        final catalogId = map['catalogId'] as String?;
        
        if (body.isEmpty) return;
        
        // Afficher la notification système
        LocalNotificationService().show(title, body);
        
        // Enregistrer dans l'historique
        NotificationService().storeCatalogNotification(
          title: title,
          body: body,
          catalogId: catalogId,
        );
      } catch (_) {}
    });
  }

  Future<void> _notifyStatusChange(String statusStr, String? orderId) async {
    final status = OrderStatusX.fromString(statusStr);
    final prefs = await SharedPreferences.getInstance();
    final isEnglish = prefs.getString('baymore_locale') == 'en';
    final title = isEnglish ? 'Baymore — Order update' : 'Baymore — Mise à jour de commande';
    final body = isEnglish ? _labelEn(status) : status.label;
    
    // Afficher la notification système
    await LocalNotificationService().show(title, body);
    
    // Enregistrer dans l'historique pour le badge et l'écran Notifications
    await NotificationService().storeOrderStatus(
      title: 'Mise à jour de commande',
      body: body,
      type: NotificationType.orderStatus,
      orderId: orderId,
    );
  }

  String _labelEn(OrderStatus status) {
    switch (status) {
      case OrderStatus.enAttente: return 'Order received';
      case OrderStatus.priseEnCharge: return 'Being prepared';
      case OrderStatus.enRoute: return 'On the way';
      case OrderStatus.livree: return 'Delivered';
      case OrderStatus.annulee: return 'Cancelled';
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? referralCode,
  }) async {
    _profile = await _service.registerWithEmail(name: name, email: email, phone: phone, password: password, referralCode: referralCode);
    _bindWalletListener();
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    _profile = await _service.loginWithEmail(email: email, password: password);
    _bindWalletListener();
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
