/// Adresses de votre backend une fois déployé sur Render — à remplacer
/// après le déploiement (voir baymore_backend/README.md).
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'https://baymore-project.onrender.com/api';
  static const String socketUrl = 'https://baymore-project.onrender.com';

  /// OneSignal App ID — Settings > Keys & IDs sur onesignal.com
  static const String oneSignalAppId = 'f013ee6b-00d5-4017-bc03-1cf5379095d9';

  /// Clé API Google Maps — DOIT être exactement la même valeur que celle
  /// mise dans android/app/src/main/AndroidManifest.xml (com.google.android.geo.API_KEY)
  /// et ios/Runner/AppDelegate.swift (GMSServices.provideAPIKey). Il faut
  /// aussi activer l'API "Directions API" sur ce projet Google Cloud (en
  /// plus de "Maps SDK for Android/iOS") pour que l'itinéraire suivant les
  /// routes s'affiche — sinon la carte retombe automatiquement sur une
  /// ligne droite entre le livreur et le client, sans planter.
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
}
