import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_strings.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../services/product_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/product_card.dart';
import '../product/product_detail_screen.dart';
import 'category_products_screen.dart';
import 'search_screen.dart';
import '../notifications/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _productService = ProductService();
  late Future<List<Product>> _future;

  static const _categories = [
    {'key': 'femme', 'label': 'FEMME', 'color': AppColors.rose, 'icon': Icons.checkroom_outlined},
    {'key': 'homme', 'label': 'HOMME', 'color': AppColors.sage, 'icon': Icons.style_outlined},
    {'key': 'enfant', 'label': 'ENFANT', 'color': AppColors.sand, 'icon': Icons.child_care_outlined},
    {'key': 'beaute', 'label': 'BEAUTÉ', 'color': AppColors.plum, 'icon': Icons.spa_outlined},
  ];

  String _categoryLabel(String key, AppStrings strings) {
    switch (key) {
      case 'femme': return strings.categoryWomen;
      case 'homme': return strings.categoryMen;
      case 'enfant': return strings.categoryKids;
      case 'beaute': return strings.categoryBeauty;
      default: return key;
    }
  }

  @override
  void initState() {
    super.initState();
    _future = _productService.fetchAll();
  }

  Future<void> _refresh() async {
    setState(() => _future = _productService.fetchAll());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final strings = AppStrings.of(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Container(
                          width: 34, height: 34,
                          decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: const Text('B', style: TextStyle(fontFamily: 'Fraunces', color: AppColors.gold, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 10),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(strings.t('lomeTogo'), style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                          Text(
                            auth.profile != null ? 'Bonjour, ${auth.profile!.name.split(' ').first}' : 'Bienvenue chez Baymore',
                              style: const TextStyle(fontFamily: 'Fraunces', fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.ink)),
                        ]),
                      ]),
                      Row(children: [
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                          child: const CircleAvatar(
                            radius: 18, backgroundColor: Colors.white,
                            child: Icon(Icons.search, color: AppColors.ink, size: 19),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                          child: const CircleAvatar(
                            radius: 18, backgroundColor: Colors.white,
                            child: Icon(Icons.notifications_none_rounded, color: AppColors.ink, size: 20),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Row(
                    children: _categories.map((c) {
                      final label = _categoryLabel(c['key'] as String, strings);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => CategoryProductsScreen(categoryKey: c['key'] as String, label: label))),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
                            child: Column(children: [
                              Icon(c['icon'] as IconData, color: c['color'] as Color),
                              const SizedBox(height: 6),
                              Text(label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700)),
                            ]),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.rose, AppColors.sand], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(strings.t('newCollection'), style: const TextStyle(color: Colors.white, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    const Text('-20% sur les sacs', style: TextStyle(fontFamily: 'Fraunces', color: Colors.white, fontSize: 19, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen(initialQuery: 'sac'))),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(20)),
                        child: Text(strings.discover, style: const TextStyle(color: AppColors.ivory, fontSize: 11.5, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ]),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: Text(strings.t('recommendedForYou'), style: Theme.of(context).textTheme.titleLarge),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: FutureBuilder<List<Product>>(
                  future: _future,
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.only(top: 40), child: Center(child: CircularProgressIndicator())));
                    }
                    final products = snap.data!.take(20).toList();
                    if (products.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 30),
                          child: Text(strings.t('catalogPreparing'),
                              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                        ),
                      );
                    }
                    return SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: .68),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => ProductCard(
                          product: products[i],
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: products[i].id))),
                        ),
                        childCount: products.length,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
