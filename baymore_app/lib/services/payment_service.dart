import 'api_client.dart';

/// Déclenche le paiement Mobile Money (Flooz / T-Money) via le backend,
/// qui contacte CinetPay et renvoie une URL de paiement hébergée sécurisée.
class PaymentService {
  final ApiClient _api = ApiClient();

  Future<String> initiatePayment(String orderId) async {
    final data = await _api.post('/payments/initiate', data: {'orderId': orderId});
    return data['paymentUrl'] as String;
  }
}
