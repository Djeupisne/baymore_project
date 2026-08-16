import '../models/catalog.dart';
import 'api_client.dart';

class CatalogService {
  final ApiClient _api = ApiClient();

  Future<List<Catalog>> fetchAll({bool? active}) async {
    final queryParams = <String, dynamic>{};
    if (active != null) {
      queryParams['active'] = active.toString();
    }
    final data = await _api.get('/catalogs', query: queryParams.isNotEmpty ? queryParams : null);
    return (data['catalogs'] as List).map((c) => Catalog.fromJson(c)).toList();
  }

  Future<Catalog> fetchById(String id) async {
    final data = await _api.get('/catalogs/$id');
    return Catalog.fromJson(data['catalog']);
  }

  Future<void> create(Catalog catalog) => _api.post('/catalogs', data: catalog.toJson());

  Future<void> update(String id, Catalog catalog) => _api.put('/catalogs/$id', data: catalog.toJson());

  Future<void> delete(String id) => _api.delete('/catalogs/$id');
}
