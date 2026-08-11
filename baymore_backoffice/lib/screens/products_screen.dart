import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../theme/app_colors.dart';
import 'product_form_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _service = ProductService();
  late Future<List<Product>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchAll();
  }

  Future<void> _reload() async {
    setState(() => _future = _service.fetchAll());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.ink,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un article'),
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductFormScreen()));
          _reload();
        },
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<Product>>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final products = snap.data!;
            if (products.isEmpty) {
              return const Center(child: Text('Aucun article. Ajoutez le premier avec le bouton ci-dessous.', style: TextStyle(color: AppColors.muted)));
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: products.length,
              itemBuilder: (context, i) {
                final p = products[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 48, height: 48,
                        child: p.images.isNotEmpty
                            ? CachedNetworkImage(imageUrl: p.images.first, fit: BoxFit.cover)
                            : Container(color: AppColors.line),
                      ),
                    ),
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    subtitle: Text('${p.category} · ${p.subCategory} · Stock: ${p.stock}', style: const TextStyle(fontSize: 11)),
                    trailing: Text('${p.price.toStringAsFixed(0)} F', style: const TextStyle(fontWeight: FontWeight.w700)),
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => ProductFormScreen(existing: p)));
                      _reload();
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
