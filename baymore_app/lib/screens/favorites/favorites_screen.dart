import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_strings.dart';
import '../../models/product.dart';
import '../../providers/favorites_provider.dart';
import '../../services/product_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/product_card.dart';
import '../product/product_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<Product>> _future;

  @override
  void initState() {
    super.initState();
    _future = ProductService().fetchAll();
  }

  @override
  Widget build(BuildContext context) {
    final favIds = context.watch<FavoritesProvider>().favoriteIds;
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('favoritesTitle'))),
      body: favIds.isEmpty
          ? EmptyState(
              icon: Icons.favorite_border,
              title: strings.t('noFavoritesTitle'),
              message: strings.t('noFavoritesMsg'),
            )
          : FutureBuilder<List<Product>>(
              future: _future,
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final favProducts = snap.data!.where((p) => favIds.contains(p.id)).toList();
                if (favProducts.isEmpty) {
                  return EmptyState(icon: Icons.favorite_border, title: strings.t('noFavoritesTitle'), message: strings.t('favoritesWillAppear'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: .68),
                  itemCount: favProducts.length,
                  itemBuilder: (context, i) => ProductCard(
                    product: favProducts[i],
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: favProducts[i].id))),
                  ),
                );
              },
            ),
    );
  }
}
