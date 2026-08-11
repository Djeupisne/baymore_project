import 'product.dart';

/// Filtres appliqués côté client sur une liste de produits déjà récupérée
/// (recherche ou catégorie) — évite d'avoir besoin d'index Firestore
/// composites complexes pour un catalogue de taille boutique.
class ProductFilters {
  final double? minPrice;
  final double? maxPrice;
  final Set<String> sizes;
  final Set<String> colors;

  const ProductFilters({this.minPrice, this.maxPrice, this.sizes = const {}, this.colors = const {}});

  bool get isActive => minPrice != null || maxPrice != null || sizes.isNotEmpty || colors.isNotEmpty;

  int get activeCount {
    int n = 0;
    if (minPrice != null || maxPrice != null) n++;
    if (sizes.isNotEmpty) n++;
    if (colors.isNotEmpty) n++;
    return n;
  }

  ProductFilters copyWith({double? minPrice, double? maxPrice, Set<String>? sizes, Set<String>? colors, bool clearPrice = false}) {
    return ProductFilters(
      minPrice: clearPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPrice ? null : (maxPrice ?? this.maxPrice),
      sizes: sizes ?? this.sizes,
      colors: colors ?? this.colors,
    );
  }

  List<Product> apply(List<Product> products) {
    return products.where((p) {
      if (minPrice != null && p.price < minPrice!) return false;
      if (maxPrice != null && p.price > maxPrice!) return false;
      if (sizes.isNotEmpty && !p.sizes.any((s) => sizes.contains(s))) return false;
      if (colors.isNotEmpty && !p.colors.any((c) => colors.contains(c))) return false;
      return true;
    }).toList();
  }
}
