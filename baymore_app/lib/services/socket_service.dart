import 'package:socket_io_client/socket_io_client.dart' as io_client;
import '../config/api_config.dart';

/// Connexion Socket.io unique, partagée par toute l'app — remplace les
/// listeners temps réel Firestore. Utilisée pour le suivi de commande en
/// direct (voir OrderService.watchOrder).
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io_client.Socket? _socket;

  io_client.Socket get socket {
    _socket ??= io_client.io(
      ApiConfig.socketUrl,
      io_client.OptionBuilder().setTransports(['websocket']).enableAutoConnect().build(),
    );
    return _socket!;
  }

  void watchOrder(String orderId) => socket.emit('order:watch', orderId);
  void unwatchOrder(String orderId) => socket.emit('order:unwatch', orderId);
  void joinStaffRoom() => socket.emit('staff:join');
  
  /// Rejoindre la room des clients pour recevoir les notifications de promos et catalogues
  void joinCustomerRoom() => socket.emit('customer:join');
  void leaveCustomerRoom() => socket.emit('customer:leave');
  
  /// Écouter les notifications de promotions/codes promo
  void onPromoNotification(void Function(Map<String, dynamic>) callback) {
    socket.off('promo:notification'); // Supprimer d'éventuels anciens listeners
    socket.on('promo:notification', (data) => callback(data));
  }
  
  /// Écouter les notifications de nouveaux catalogues
  void onCatalogNotification(void Function(Map<String, dynamic>) callback) {
    socket.off('catalog:notification'); // Supprimer d'éventuels anciens listeners
    socket.on('catalog:notification', (data) => callback(data));
  }
  
  /// Supprimer les écouteurs
  void offPromoNotification() => socket.off('promo:notification');
  void offCatalogNotification() => socket.off('catalog:notification');
}
