import '../models/order.dart';
import '../models/order_status.dart';
import 'api_client.dart';

class OrderService {
  final ApiClient _api = ApiClient();

  Future<List<AppOrder>> fetchAll() async {
    final data = await _api.get('/orders');
    return (data['orders'] as List).map((o) => AppOrder.fromJson(o)).toList();
  }

  Future<void> advanceStatus(String orderId, OrderStatus newStatus) =>
      _api.patch('/orders/$orderId/status');

  Future<void> cancel(String orderId) => _api.patch('/orders/$orderId/status', data: {'status': 'ANNULE'});

  Future<void> assignDriver(String orderId, String name, String phone) =>
      _api.patch('/orders/$orderId/driver', data: {'driverName': name, 'driverPhone': phone});

  Future<void> updateDriverPosition(String orderId, double lat, double lng) =>
      _api.patch('/orders/$orderId/driver-position', data: {'lat': lat, 'lng': lng});
}
