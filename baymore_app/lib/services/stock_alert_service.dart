import 'api_client.dart';

/// Permet au client de demander à être notifié dès qu'un article en
/// rupture de stock redevient disponible.
class StockAlertService {
  final ApiClient _api = ApiClient();

  Future<bool> isSubscribed(String productId) async {
    final data = await _api.get('/stock-alerts/$productId');
    return data['subscribed'] == true;
  }

  Future<void> subscribe(String productId) => _api.post('/stock-alerts/$productId');
  Future<void> unsubscribe(String productId) => _api.delete('/stock-alerts/$productId');
}
