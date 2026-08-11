import '../models/review.dart';
import 'api_client.dart';

/// Modération des avis. Contrairement à l'app client (qui les lit par
/// produit), le staff a besoin de voir tous les avis de tous les
/// produits — on agrège donc en récupérant chaque produit puis ses avis.
class ReviewModerationService {
  final ApiClient _api = ApiClient();

  Future<List<Review>> fetchAll() async {
    final productsData = await _api.get('/products');
    final products = List<Map<String, dynamic>>.from(productsData['products']);
    final all = <Review>[];
    for (final p in products) {
      final data = await _api.get('/products/${p['id']}/reviews');
      all.addAll((data['reviews'] as List).map((r) => Review.fromJson(r)));
    }
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  Future<void> delete(String reviewId) => _api.delete('/products/reviews/$reviewId');
}
