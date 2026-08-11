import 'api_client.dart';

class PromoValidationResult {
  final bool valid;
  final double discount;
  final String message;
  PromoValidationResult({required this.valid, required this.discount, required this.message});
}

/// Valide un code promo côté serveur — le calcul de remise n'est jamais
/// fait uniquement côté client pour éviter toute manipulation.
class PromoService {
  final ApiClient _api = ApiClient();

  Future<PromoValidationResult> validate(String code, double subtotal) async {
    try {
      final data = await _api.post('/promo/validate', data: {'code': code.trim().toUpperCase(), 'subtotal': subtotal});
      return PromoValidationResult(
        valid: data['valid'] == true,
        discount: (data['discount'] ?? 0).toDouble(),
        message: data['message'] ?? '',
      );
    } on ApiException catch (e) {
      return PromoValidationResult(valid: false, discount: 0, message: e.message);
    }
  }

  Future<List<Map<String, dynamic>>> fetchActive() async {
    final data = await _api.get('/promo/active');
    return List<Map<String, dynamic>>.from(data['codes']);
  }
}
