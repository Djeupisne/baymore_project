import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import 'main_nav_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.loading) {
      return const Scaffold(
        backgroundColor: AppColors.ink,
        body: Center(
          child: Text('B', style: TextStyle(fontFamily: 'Fraunces', color: AppColors.gold, fontSize: 48, fontWeight: FontWeight.w700)),
        ),
      );
    }

    // Que le client soit connecté ou non, la boutique reste consultable ;
    // la connexion n'est demandée qu'au moment de commander (voir CheckoutScreen).
    return const MainNavScreen();
  }
}
