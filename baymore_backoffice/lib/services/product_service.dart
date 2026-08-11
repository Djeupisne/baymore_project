import '../models/product.dart';
import 'api_client.dart';

class ProductService {
  final ApiClient _api = ApiClient();

  Future<List<Product>> fetchAll() async {
    final data = await _api.get('/products');
    return (data['products'] as List).map((p) => Product.fromJson(p)).toList();
  }

  Future<void> create(Product product) => _api.post('/products', data: product.toJson());
  Future<void> update(String id, Product product) => _api.put('/products/$id', data: product.toJson());
  Future<void> delete(String id) => _api.delete('/products/$id');
}
