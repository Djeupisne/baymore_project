import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../models/product.dart';
import '../../models/product_filters.dart';
import '../../services/product_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/product_card.dart';
import '../../widgets/product_filter_sheet.dart';
import '../product/product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final _controller = TextEditingController(text: widget.initialQuery ?? '');
  final _service = ProductService();
  String _query = '';
  ProductFilters _filters = const ProductFilters();
  Future<List<Product>>? _future;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialQuery;
    if (initial != null && initial.trim().isNotEmpty) {
      _query = initial;
      _future = _service.search(initial);
    }
  }

  void _onChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _future = null);
      return;
    }
    // Petite pause avant d'interroger le serveur pour éviter une requête
    // à chaque frappe (le catalogue n'est plus filtré localement).
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() => _future = _service.search(value));
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: strings.t('searchHint'),
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search, size: 20),
          ),
          onChanged: _onChanged,
        ),
      ),
      body: _future == null
          ? EmptyState(
              icon: Icons.search,
              title: strings.t('searchPromptTitle'),
              message: strings.t('searchPromptMsg'),
            )
          : FutureBuilder<List<Product>>(
              future: _future,
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final allResults = snap.data!;
                final results = _filters.apply(allResults);

                return Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(children: [
                      Text(strings.tf('resultsCount', ['${results.length}']), style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final updated = await showProductFilterSheet(context, availableProducts: allResults, current: _filters);
                          if (updated != null) setState(() => _filters = updated);
                        },
                        icon: const Icon(Icons.tune, size: 16),
                        label: Text(_filters.isActive ? '${strings.t('filters')} (${_filters.activeCount})' : strings.t('filters')),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          side: BorderSide(color: _filters.isActive ? AppColors.ink : AppColors.line),
                          foregroundColor: AppColors.ink,
                        ),
                      ),
                    ]),
                  ),
                  Expanded(
                    child: results.isEmpty
                        ? EmptyState(
                            icon: Icons.search_off,
                            title: allResults.isEmpty ? strings.tf('noResultsFor', [_query]) : strings.t('noResultsFiltered'),
                            message: allResults.isEmpty ? strings.t('tryOtherKeyword') : strings.t('tryWiderFilters'),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(20),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: .68),
                            itemCount: results.length,
                            itemBuilder: (context, i) => ProductCard(
                              product: results[i],
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: results[i].id))),
                            ),
                          ),
                  ),
                ]);
              },
            ),
    );
  }
}
