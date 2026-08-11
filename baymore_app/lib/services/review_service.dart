import '../models/review.dart';
import 'api_client.dart';

class ReviewService {
  final ApiClient _api = ApiClient();

  Future<List<Review>> fetchForProduct(String productId) async {
    final data = await _api.get('/products/$productId/reviews');
    return (data['reviews'] as List).map((r) => Review.fromJson(r)).toList();
  }

  Future<void> add(String productId, {required double rating, required String comment}) =>
      _api.post('/products/$productId/reviews', data: {'rating': rating, 'comment': comment});
}
