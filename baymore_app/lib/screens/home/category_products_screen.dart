import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/product_filters.dart';
import '../../services/product_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/product_card.dart';
import '../../widgets/product_filter_sheet.dart';
import '../product/product_detail_screen.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String categoryKey;
  final String label;
  const CategoryProductsScreen({super.key, required this.categoryKey, required this.label});
  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final _service = ProductService();
  ProductFilters _filters = const ProductFilters();
  late Future<List<Product>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchByCategory(widget.categoryKey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.label)),
      body: FutureBuilder<List<Product>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final allProducts = snap.data!;
          final products = _filters.apply(allProducts);

          if (allProducts.isEmpty) {
            return const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Aucun article ici pour le moment',
              message: 'De nouveaux articles arrivent bientôt dans cette catégorie.',
            );
          }

          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(children: [
                Text('${products.length} article(s)', style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () async {
                    final updated = await showProductFilterSheet(context, availableProducts: allProducts, current: _filters);
                    if (updated != null) setState(() => _filters = updated);
                  },
                  icon: const Icon(Icons.tune, size: 16),
                  label: Text(_filters.isActive ? 'Filtres (${_filters.activeCount})' : 'Filtres'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    side: BorderSide(color: _filters.isActive ? AppColors.ink : AppColors.line),
                    foregroundColor: AppColors.ink,
                  ),
                ),
              ]),
            ),
            Expanded(
              child: products.isEmpty
                  ? const EmptyState(icon: Icons.filter_alt_off_outlined, title: 'Aucun article avec ces filtres', message: 'Essayez d\'élargir vos filtres.')
                  : GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: .68),
                      itemCount: products.length,
                      itemBuilder: (context, i) => ProductCard(
                        product: products[i],
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: products[i].id))),
                      ),
                    ),
            ),
          ]);
        },
      ),
    );
  }
}
