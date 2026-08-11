import '../models/customer.dart';
import '../models/order.dart';

import 'api_client.dart';

class CustomerService {
  final ApiClient _api = ApiClient();

  Future<List<Customer>> fetchAll({String? search}) async {
    final data = await _api.get('/customers', query: search != null && search.isNotEmpty ? {'search': search} : null);
    return (data['customers'] as List).map((c) => Customer.fromJson(c)).toList();
  }

  Future<List<AppOrder>> fetchOrdersFor(String uid) async {
    final data = await _api.get('/customers/$uid/orders');
    return (data['orders'] as List).map((o) => AppOrder.fromJson(o)).toList();
  }
}
