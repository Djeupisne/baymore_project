import 'dart:convert';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

enum NotificationType {
  orderStatus,
  promotion,
  promoDisabled,
  newProduct,
  restock,
  newOrder,
  message,
  catalog,
  unknown,
}

extension NotificationTypeX on NotificationType {
  static NotificationType fromString(String? s) {
    switch (s) {
      case 'order_status':
        return NotificationType.orderStatus;
      case 'promotion':
        return NotificationType.promotion;
      case 'promo_disabled':
        return NotificationType.promoDisabled;
      case 'new_product':
        return NotificationType.newProduct;
      case 'restock':
        return NotificationType.restock;
      case 'new_order':
        return NotificationType.newOrder;
      case 'message':
        return NotificationType.message;
      case 'catalog':
        return NotificationType.catalog;
      default:
        return NotificationType.unknown;
    }
  }
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;
  final NotificationType type;
  final Map<String, dynamic>? data;
  bool read;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.type = NotificationType.unknown,
    this.data,
    this.read = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'receivedAt': receivedAt.toIso8601String(),
        'type': type.name,
        'data': data,
        'read': read,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        receivedAt: DateTime.tryParse(json['receivedAt'] as String? ?? '') ?? DateTime.now(),
        type: NotificationTypeX.fromString(json['type'] as String?),
        data: json['data'] as Map<String, dynamic>?,
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
      final typeStr = event.notification.additionalData?['type'] as String?;
      _store(
        event.notification.title ?? 'Baymore',
        event.notification.body ?? '',
        type: NotificationTypeX.fromString(typeStr),
        data: event.notification.additionalData != null
            ? Map<String, dynamic>.from(event.notification.additionalData!)
            : null,
      );
      event.notification.display();
    });

    OneSignal.Notifications.addClickListener((event) {
      final typeStr = event.notification.additionalData?['type'] as String?;
      _store(
        event.notification.title ?? 'Baymore',
        event.notification.body ?? '',
        type: NotificationTypeX.fromString(typeStr),
        data: event.notification.additionalData != null
            ? Map<String, dynamic>.from(event.notification.additionalData!)
            : null,
      );
      _handleNavigation(typeStr, event.notification.additionalData);
    });
  }

  static void addListener(void Function() cb) => _listeners.add(cb);
  static void removeListener(void Function() cb) => _listeners.remove(cb);

  void _handleNavigation(String? type, Map<String, dynamic>? data) {
    // Navigation contextuelle selon le type de notification
    // Sera implémentée avec un système de routing profond si nécessaire
    switch (type) {
      case 'order_status':
      case 'new_order':
        // Naviguer vers le suivi de commande
        break;
      case 'promotion':
      case 'promo_disabled':
      case 'new_product':
      case 'restock':
        // Naviguer vers le détail du produit ou la liste des promotions
        break;
      case 'catalog':
        // Naviguer vers le catalogue
        break;
      default:
        break;
    }
  }

  Future<void> _store(String title, String body, {NotificationType type = NotificationType.unknown, Map<String, dynamic>? data}) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _readAll(prefs);
    final id = data?['orderId']?.toString() ??
               data?['productId']?.toString() ??
               data?['promoId']?.toString() ??
               '${DateTime.now().millisecondsSinceEpoch}';
    list.insert(0, AppNotification(
      id: id,
      title: title,
      body: body,
      receivedAt: DateTime.now(),
      type: type,
      data: data,
    ));
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

  Future<void> markAsRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _readAll(prefs);
    for (final n in list) {
      if (n.id == id) {
        n.read = true;
        break;
      }
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

  /// Méthode pour enregistrer une notification de statut de commande
  /// Appelée par AuthProvider quand une commande change de statut
  Future<void> storeOrderStatus({
    required String title,
    required String body,
    required NotificationType type,
    String? orderId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _readAll(prefs);
    final id = orderId ?? '${DateTime.now().millisecondsSinceEpoch}';
    
    // Vérifier si une notification avec le même orderId existe déjà pour éviter les doublons
    final existingIndex = list.indexWhere((n) => n.data?['orderId'] == orderId && n.type == type);
    if (existingIndex != -1) {
      // Mettre à jour la notification existante au lieu d'en créer une nouvelle
      list[existingIndex] = AppNotification(
        id: id,
        title: title,
        body: body,
        receivedAt: DateTime.now(),
        type: type,
        data: {'orderId': orderId},
        read: false,
      );
    } else {
      list.insert(0, AppNotification(
        id: id,
        title: title,
        body: body,
        receivedAt: DateTime.now(),
        type: type,
        data: {'orderId': orderId},
        read: false,
      ));
    }
    
    await prefs.setString(_storageKey, jsonEncode(list.map((n) => n.toJson()).toList()));
    for (final cb in _listeners) {
      cb();
    }
  }

  /// Méthode pour enregistrer une notification de code promo (nouveau ou désactivé)
  /// Appelée quand l'administrateur crée ou désactive un code promo
  Future<void> storePromoNotification({
    required String title,
    required String body,
    required NotificationType type,
    String? promoId,
    String? promoCode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _readAll(prefs);
    final id = promoId ?? '${DateTime.now().millisecondsSinceEpoch}';
    
    // Vérifier si une notification avec le même promoId existe déjà pour éviter les doublons
    final existingIndex = list.indexWhere((n) => n.data?['promoId'] == promoId && n.type == type);
    if (existingIndex != -1) {
      // Mettre à jour la notification existante
      list[existingIndex] = AppNotification(
        id: id,
        title: title,
        body: body,
        receivedAt: DateTime.now(),
        type: type,
        data: {'promoId': promoId, 'promoCode': promoCode},
        read: false,
      );
    } else {
      list.insert(0, AppNotification(
        id: id,
        title: title,
        body: body,
        receivedAt: DateTime.now(),
        type: type,
        data: {'promoId': promoId, 'promoCode': promoCode},
        read: false,
      ));
    }
    
    await prefs.setString(_storageKey, jsonEncode(list.map((n) => n.toJson()).toList()));
    for (final cb in _listeners) {
      cb();
    }
  }

  /// Méthode pour enregistrer une notification de nouveau catalogue
  /// Appelée quand l'administrateur publie un nouveau catalogue
  Future<void> storeCatalogNotification({
    required String title,
    required String body,
    String? catalogId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _readAll(prefs);
    final id = catalogId ?? '${DateTime.now().millisecondsSinceEpoch}';
    
    list.insert(0, AppNotification(
      id: id,
      title: title,
      body: body,
      receivedAt: DateTime.now(),
      type: NotificationType.catalog,
      data: {'catalogId': catalogId},
      read: false,
    ));
    
    await prefs.setString(_storageKey, jsonEncode(list.map((n) => n.toJson()).toList()));
    for (final cb in _listeners) {
      cb();
    }
  }
}
