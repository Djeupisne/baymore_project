import '../models/product.dart';
import 'api_client.dart';

/// Accès au catalogue produit via l'API REST. Contrairement à Firestore,
/// il n'y a pas de flux temps réel ici — les écrans rechargent la liste
/// à l'ouverture et via "tirer pour actualiser" (le catalogue change
/// rarement pendant qu'un client parcourt la boutique).
class ProductService {
  final ApiClient _api = ApiClient();

  Future<List<Product>> fetchAll() async {
    final data = await _api.get('/products');
    return (data['products'] as List).map((p) => Product.fromJson(p)).toList();
  }

  Future<List<Product>> fetchByCategory(String category) async {
    final data = await _api.get('/products', query: {'category': category});
    return (data['products'] as List).map((p) => Product.fromJson(p)).toList();
  }

  Future<List<Product>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final data = await _api.get('/products', query: {'search': query});
    return (data['products'] as List).map((p) => Product.fromJson(p)).toList();
  }

  Future<Product?> getById(String id) async {
    try {
      final data = await _api.get('/products/$id');
      return Product.fromJson(data['product']);
    } on ApiException {
      return null;
    }
  }
}
