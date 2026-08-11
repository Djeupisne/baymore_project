import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/product_filters.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

/// Feuille de filtres (taille, couleur, prix), calculée à partir des
/// valeurs réellement présentes dans les produits affichés — pas de
/// filtre qui ne renverrait aucun résultat.
Future<ProductFilters?> showProductFilterSheet(
  BuildContext context, {
  required List<Product> availableProducts,
  required ProductFilters current,
}) {
  final allSizes = availableProducts.expand((p) => p.sizes).toSet().toList()..sort();
  final allColors = availableProducts.expand((p) => p.colors).toSet().toList()..sort();
  final prices = availableProducts.map((p) => p.price).toList();
  final minBound = prices.isEmpty ? 0.0 : prices.reduce((a, b) => a < b ? a : b);
  final maxBound = prices.isEmpty ? 100000.0 : prices.reduce((a, b) => a > b ? a : b);

  return showModalBottomSheet<ProductFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) => _FilterSheetContent(
      allSizes: allSizes,
      allColors: allColors,
      minBound: minBound,
      maxBound: maxBound,
      current: current,
    ),
  );
}

class _FilterSheetContent extends StatefulWidget {
  final List<String> allSizes;
  final List<String> allColors;
  final double minBound;
  final double maxBound;
  final ProductFilters current;
  const _FilterSheetContent({required this.allSizes, required this.allColors, required this.minBound, required this.maxBound, required this.current});

  @override
  State<_FilterSheetContent> createState() => _FilterSheetContentState();
}

class _FilterSheetContentState extends State<_FilterSheetContent> {
  late RangeValues _priceRange;
  late Set<String> _sizes;
  late Set<String> _colors;

  @override
  void initState() {
    super.initState();
    final lo = widget.current.minPrice ?? widget.minBound;
    final hi = widget.current.maxPrice ?? widget.maxBound;
    _priceRange = RangeValues(lo.clamp(widget.minBound, widget.maxBound), hi.clamp(widget.minBound, widget.maxBound));
    _sizes = {...widget.current.sizes};
    _colors = {...widget.current.colors};
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Filtrer', style: TextStyle(fontFamily: 'Fraunces', fontSize: 18, fontWeight: FontWeight.w600)),
              TextButton(
                onPressed: () => setState(() {
                  _priceRange = RangeValues(widget.minBound, widget.maxBound);
                  _sizes.clear();
                  _colors.clear();
                }),
                child: const Text('Réinitialiser', style: TextStyle(color: AppColors.goldDeep, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ]),
            const SizedBox(height: 12),
            Text('Prix : ${Formatters.cfa(_priceRange.start)} — ${Formatters.cfa(_priceRange.end)}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
            RangeSlider(
              values: _priceRange,
              min: widget.minBound,
              max: widget.maxBound == widget.minBound ? widget.minBound + 1 : widget.maxBound,
              activeColor: AppColors.ink,
              inactiveColor: AppColors.line,
              onChanged: (v) => setState(() => _priceRange = v),
            ),
            if (widget.allSizes.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Taille', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: widget.allSizes.map((s) {
                final selected = _sizes.contains(s);
                return FilterChip(
                  label: Text(s),
                  selected: selected,
                  onSelected: (v) => setState(() => v ? _sizes.add(s) : _sizes.remove(s)),
                  selectedColor: AppColors.ink,
                  labelStyle: TextStyle(color: selected ? Colors.white : AppColors.ink, fontWeight: FontWeight.w700, fontSize: 12),
                  backgroundColor: AppColors.ivory,
                  side: const BorderSide(color: AppColors.line),
                );
              }).toList()),
            ],
            if (widget.allColors.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Couleur', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: widget.allColors.map((c) {
                final selected = _colors.contains(c);
                return FilterChip(
                  label: Text(c),
                  selected: selected,
                  onSelected: (v) => setState(() => v ? _colors.add(c) : _colors.remove(c)),
                  selectedColor: AppColors.ink,
                  labelStyle: TextStyle(color: selected ? Colors.white : AppColors.ink, fontWeight: FontWeight.w700, fontSize: 12),
                  backgroundColor: AppColors.ivory,
                  side: const BorderSide(color: AppColors.line),
                );
              }).toList()),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final noPriceFilter = _priceRange.start <= widget.minBound && _priceRange.end >= widget.maxBound;
                  Navigator.pop(context, ProductFilters(
                    minPrice: noPriceFilter ? null : _priceRange.start,
                    maxPrice: noPriceFilter ? null : _priceRange.end,
                    sizes: _sizes,
                    colors: _colors,
                  ));
                },
                child: const Text('Appliquer les filtres'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
