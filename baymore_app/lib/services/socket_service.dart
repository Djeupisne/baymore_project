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
}
