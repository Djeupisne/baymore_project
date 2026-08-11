import 'package:socket_io_client/socket_io_client.dart' as io_client;
import '../config/api_config.dart';

/// Connexion Socket.io unique — le staff rejoint la room "staff" pour
/// recevoir en direct les nouvelles commandes et les mises à jour, sans
/// avoir à rafraîchir manuellement l'écran Commandes.
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

  void joinStaffRoom() => socket.emit('staff:join');
  void watchOrder(String orderId) => socket.emit('order:watch', orderId);
  void unwatchOrder(String orderId) => socket.emit('order:unwatch', orderId);
}
