import '../models/app_address.dart';
import 'api_client.dart';

class AddressService {
  final ApiClient _api = ApiClient();

  Future<List<AppAddress>> fetchAll() async {
    final data = await _api.get('/addresses');
    return (data['addresses'] as List).map((a) => AppAddress.fromJson(a)).toList();
  }

  Future<void> add(AppAddress address) => _api.post('/addresses', data: address.toJson());
  Future<void> update(AppAddress address) => _api.put('/addresses/${address.id}', data: address.toJson());
  Future<void> delete(String addressId) => _api.delete('/addresses/$addressId');
}
