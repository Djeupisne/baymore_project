/// Adresses de votre backend une fois déployé sur Render — à remplacer
/// après le déploiement (voir baymore_backend/README.md). Doit pointer
/// vers le MÊME backend que l'app cliente baymore_app.
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'https://baymore-project.onrender.com/api';
  static const String socketUrl = 'https://baymore-project.onrender.com';

  /// OneSignal App ID — Settings > Keys & IDs sur onesignal.com (même app
  /// OneSignal que baymore_app, pour cibler les comptes staff par leur id).
  static const String oneSignalAppId = 'f013ee6b-00d5-4017-bc03-1cf5379095d9';
}
