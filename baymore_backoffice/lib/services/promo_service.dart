import '../models/promo_code.dart';
import 'api_client.dart';

class PromoCodeService {
  final ApiClient _api = ApiClient();

  Future<List<PromoCode>> fetchAll() async {
    final data = await _api.get('/promo');
    return (data['codes'] as List).map((c) => PromoCode.fromJson(c)).toList();
  }

  Future<void> save(PromoCode promo) => _api.put('/promo/${promo.code.trim().toUpperCase()}', data: promo.toJson());
  Future<void> delete(String code) => _api.delete('/promo/$code');
  Future<void> toggleActive(String code, bool active) => _api.patch('/promo/$code/active', data: {'active': active});
}
