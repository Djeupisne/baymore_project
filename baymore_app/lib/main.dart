import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'services/local_notification_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser la localisation des dates pour les deux langues supportées
  // (FR et EN) — sinon DateFormat plante dès qu'on bascule sur l'anglais.
  await initializeDateFormatting('fr_FR', null);
  await initializeDateFormatting('en_US', null);

  NotificationService().init();
  await LocalNotificationService().init();
  runApp(const BaymoreApp());
}