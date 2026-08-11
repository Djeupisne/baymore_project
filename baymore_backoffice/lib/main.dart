import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'config/api_config.dart';
import 'services/staff_auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  OneSignal.initialize(ApiConfig.oneSignalAppId);
  OneSignal.Notifications.requestPermission(true);
  runApp(const BackofficeApp());
}

class BackofficeApp extends StatefulWidget {
  const BackofficeApp({super.key});
  @override
  State<BackofficeApp> createState() => _BackofficeAppState();
}

class _BackofficeAppState extends State<BackofficeApp> {
  final _authService = StaffAuthService();

  @override
  void initState() {
    super.initState();
    _authService.restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baymore Back-office',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: StreamBuilder<StaffUser?>(
        stream: _authService.authStateChanges,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return snap.data == null ? const LoginScreen() : const DashboardScreen();
        },
      ),
    );
  }
}
