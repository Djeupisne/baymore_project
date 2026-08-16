import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/api_config.dart';

/// Récupère un itinéraire réel (suivant les routes) entre deux points via
/// l'API Google Directions. Si aucune clé n'est configurée ou que l'appel
/// échoue (API non activée, pas de réseau...), retourne simplement `null`
/// pour que l'appelant puisse basculer sur une ligne droite — jamais
/// d'exception qui ferait planter l'écran de suivi.
class DirectionsService {
  final Dio _dio = Dio();

  Future<List<LatLng>?> fetchRoute({required LatLng origin, required LatLng destination}) async {
    if (ApiConfig.googleMapsApiKey.isEmpty || ApiConfig.googleMapsApiKey == 'YOUR_GOOGLE_MAPS_API_KEY') return null;
    try {
      final response = await _dio.get('https://maps.googleapis.com/maps/api/directions/json', queryParameters: {
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        'mode': 'driving',
        'key': ApiConfig.googleMapsApiKey,
      });
      final data = response.data as Map<String, dynamic>;
      if (data['status'] != 'OK') return null;
      final routes = data['routes'] as List;
      if (routes.isEmpty) return null;
      final points = routes.first['overview_polyline']['points'] as String;
      return _decodePolyline(points);
    } catch (_) {
      return null;
    }
  }

  /// Décodage de l'encodage polyline standard de Google (algorithme public).
  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }
}
