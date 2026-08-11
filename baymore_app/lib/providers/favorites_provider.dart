import 'package:flutter/foundation.dart';
import '../services/api_client.dart';

/// Favoris du client, synchronisés via l'API — remplace le champ
/// Firestore favoriteIds.
class FavoritesProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  final Set<String> _favoriteIds = {};
  bool _loaded = false;

  Set<String> get favoriteIds => _favoriteIds;
  bool isFavorite(String productId) => _favoriteIds.contains(productId);

  /// Recharge les favoris pour l'utilisateur actuellement connecté (ou
  /// vide la liste si personne n'est connecté).
  Future<void> bindUser(String? uid) async {
    _favoriteIds.clear();
    _loaded = false;
    if (uid == null) {
      notifyListeners();
      return;
    }
    try {
      final data = await _api.get('/favorites');
      _favoriteIds.addAll(List<String>.from(data['favoriteIds'] ?? []));
    } on ApiException {
      // pas de session valide — reste vide
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> toggle(String productId) async {
    if (_favoriteIds.contains(productId)) {
      _favoriteIds.remove(productId);
      notifyListeners();
      await _api.delete('/favorites/$productId');
    } else {
      _favoriteIds.add(productId);
      notifyListeners();
      await _api.post('/favorites/$productId');
    }
  }
}
