import '../models/return_request.dart';
import 'api_client.dart';

class ReturnService {
  final ApiClient _api = ApiClient();

  Future<void> create({required String orderId, required String reason}) =>
      _api.post('/returns', data: {'orderId': orderId, 'reason': reason});

  Future<ReturnRequest?> fetchForOrder(String orderId) async {
    final data = await _api.get('/returns/order/$orderId');
    return data['request'] != null ? ReturnRequest.fromJson(data['request']) : null;
  }
}
