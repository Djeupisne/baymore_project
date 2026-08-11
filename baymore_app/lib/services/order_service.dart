import 'dart:async';
import '../models/order.dart';
import 'api_client.dart';
import 'socket_service.dart';

/// Création et suivi des commandes via l'API REST + Socket.io pour le
/// temps réel (remplace les listeners Firestore).
class OrderService {
  final ApiClient _api = ApiClient();

  Future<String> createOrder(Map<String, dynamic> orderPayload) async {
    final data = await _api.post('/orders', data: orderPayload);
    return data['order']['id'];
  }

  /// Flux temps réel d'une commande précise — utilisé par l'écran de
  /// suivi. Récupère l'état initial via l'API puis écoute les mises à
  /// jour poussées par le serveur via Socket.io.
  Stream<AppOrder?> watchOrder(String orderId) {
    late StreamController<AppOrder?> controller;
    final socketService = SocketService();
    void onUpdate(dynamic data) {
      final order = AppOrder.fromJson(Map<String, dynamic>.from(data));
      if (order.id == orderId) controller.add(order);
    }

    controller = StreamController<AppOrder?>(
      onListen: () async {
        try {
          final data = await _api.get('/orders/$orderId');
          controller.add(AppOrder.fromJson(data['order']));
        } catch (_) {
          controller.add(null);
        }
        socketService.watchOrder(orderId);
        socketService.socket.on('order:update', onUpdate);
      },
      onCancel: () {
        socketService.unwatchOrder(orderId);
        socketService.socket.off('order:update', onUpdate);
      },
    );
    return controller.stream;
  }

  Future<List<AppOrder>> fetchMine({required bool active}) async {
    final data = await _api.get('/orders/mine', query: {'scope': active ? 'active' : 'history'});
    return (data['orders'] as List).map((o) => AppOrder.fromJson(o)).toList();
  }

  Future<void> cancelOrder(String orderId) => _api.patch('/orders/$orderId/cancel');

  // ---- Réservé au staff (back-office) ----

  Future<List<AppOrder>> fetchAllForStaff() async {
    final data = await _api.get('/orders');
    return (data['orders'] as List).map((o) => AppOrder.fromJson(o)).toList();
  }

  Future<void> advanceStatus(String orderId) => _api.patch('/orders/$orderId/status');

  Future<void> cancelAsStaff(String orderId) => _api.patch('/orders/$orderId/status', data: {'status': 'ANNULE'});

  Future<void> assignDriver(String orderId, String name, String phone) =>
      _api.patch('/orders/$orderId/driver', data: {'driverName': name, 'driverPhone': phone});

  Future<void> updateDriverPosition(String orderId, double lat, double lng) =>
      _api.patch('/orders/$orderId/driver-position', data: {'lat': lat, 'lng': lng});
}
