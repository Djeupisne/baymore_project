import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/favorites_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

class BaymoreApp extends StatelessWidget {
  const BaymoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()..hydrate()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      child: const _AuthFavoritesBinder(),
    );
  }
}

/// Relie les favoris au client actuellement connecté : dès que l'utilisateur
/// se connecte ou se déconnecte, FavoritesProvider écoute le bon document.
class _AuthFavoritesBinder extends StatelessWidget {
  const _AuthFavoritesBinder();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<FavoritesProvider>().bindUser(auth.uid);
        });
        return MaterialApp(
          title: 'Baymore',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const SplashScreen(),
        );
      },
    );
  }
}
