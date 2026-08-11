import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../config/api_config.dart';

/// Initialise OneSignal — remplace Firebase Cloud Messaging. L'association
/// d'un appareil à un compte Baymore précis se fait via `OneSignal.login`
/// (appelé dans AuthService à la connexion/inscription) : le backend
/// cible ensuite directement l'utilisateur par son id, sans jeton à gérer
/// côté app.
class NotificationService {
  void init() {
    OneSignal.initialize(ApiConfig.oneSignalAppId);
    OneSignal.Notifications.requestPermission(true);
  }
}
