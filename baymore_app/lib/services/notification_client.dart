import 'api_client.dart';

/// Service pour gérer les notifications push côté client
/// Permet d'envoyer des notifications pour les nouveaux codes promo,
/// les codes promo désactivés, et les nouveaux catalogues
class NotificationClient {
  final ApiClient _api = ApiClient();

  /// Notifie tous les utilisateurs qu'un nouveau code promo est disponible
  Future<void> sendPromoNotification({
    required String promoId,
    required String promoCode,
    required String title,
    required String body,
  }) async {
    await _api.post('/notifications/promo', data: {
      'promoId': promoId,
      'promoCode': promoCode,
      'title': title,
      'body': body,
      'type': 'promotion',
    });
  }

  /// Notifie tous les utilisateurs qu'un code promo a été désactivé
  Future<void> sendPromoDisabledNotification({
    required String promoId,
    required String promoCode,
    required String title,
    required String body,
  }) async {
    await _api.post('/notifications/promo-disabled', data: {
      'promoId': promoId,
      'promoCode': promoCode,
      'title': title,
      'body': body,
      'type': 'promo_disabled',
    });
  }

  /// Notifie tous les utilisateurs qu'un nouveau catalogue est disponible
  Future<void> sendCatalogNotification({
    required String catalogId,
    required String title,
    required String body,
  }) async {
    await _api.post('/notifications/catalog', data: {
      'catalogId': catalogId,
      'title': title,
      'body': body,
      'type': 'catalog',
    });
  }
}
