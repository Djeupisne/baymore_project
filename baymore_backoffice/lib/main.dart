import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'config/api_config.dart';
import 'services/staff_auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'theme/app_theme.dart';
import 'services/token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Indispensable : sans ceci, tout DateFormat(..., 'fr_FR') lève une
  // exception au premier rendu. En web release, cette exception ne
  // s'affiche nulle part — le widget concerné (carte de commande,
  // étiquette de jour du graphique...) se contente de rendre un
  // rectangle gris vide à la place, sans aucun message d'erreur.
  await initializeDateFormatting('fr_FR', null);

  try {
    OneSignal.initialize(ApiConfig.oneSignalAppId);
    OneSignal.Notifications.requestPermission(true);
  } catch (e) {
    print('❌ Erreur OneSignal: $e');
  }

  // Nettoyer les tokens au démarrage pour éviter les erreurs
  await TokenStorage.clear();

  runApp(const BackofficeApp());
}

class BackofficeApp extends StatelessWidget {
  const BackofficeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baymore Back-office',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}