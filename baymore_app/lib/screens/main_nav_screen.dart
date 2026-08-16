import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../providers/cart_provider.dart';
import '../theme/app_colors.dart';
import 'cart/cart_screen.dart';
import 'favorites/favorites_screen.dart';
import 'home/home_screen.dart';
import 'orders/orders_screen.dart';
import 'profile/profile_screen.dart';

/// Coquille de navigation principale — reproduit la barre du bas de la
/// maquette (Découvrir / Favoris / Panier / Commandes / Menu).
class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});
  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _index = 0;

  List<Widget> get _screens => [
        const HomeScreen(),
        const FavoritesScreen(),
        CartScreen(onContinueShopping: () => setState(() => _index = 0)),
        const OrdersScreen(),
        const ProfileScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().itemCount;
    final strings = AppStrings.of(context);

    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.storefront_outlined), activeIcon: const Icon(Icons.storefront), label: strings.navShop),
          BottomNavigationBarItem(icon: const Icon(Icons.favorite_border), activeIcon: const Icon(Icons.favorite), label: strings.navFavorites),
          BottomNavigationBarItem(
            icon: Container(
              width: 46, height: 46,
              decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
              child: Stack(children: [
                const Center(child: Icon(Icons.shopping_cart_outlined, color: AppColors.gold, size: 20)),
                if (cartCount > 0)
                  Positioned(
                    right: 4, top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: AppColors.rose, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text('$cartCount', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                    ),
                  ),
              ]),
            ),
            label: '',
          ),
          BottomNavigationBarItem(icon: const Icon(Icons.receipt_long_outlined), activeIcon: const Icon(Icons.receipt_long), label: strings.navOrders),
          BottomNavigationBarItem(icon: const Icon(Icons.menu), label: strings.navMenu),
        ],
      ),
    );
  }
}
