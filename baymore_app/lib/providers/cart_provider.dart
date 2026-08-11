import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/product_service.dart';

/// Panier d'achat. Persisté sur l'appareil (shared_preferences) afin que
/// le client ne perde jamais son panier en fermant l'app par accident —
/// il est restauré automatiquement au prochain lancement.
class CartProvider extends ChangeNotifier {
  static const _storageKey = 'baymore_cart_v1';
  final Map<String, CartItem> _items = {};
  bool _hydrated = false;

  List<CartItem> get items => _items.values.toList();
  int get itemCount => _items.values.fold(0, (sum, i) => sum + i.quantity);
  bool get isEmpty => _items.isEmpty;

  double get subtotal =>
      _items.values.fold(0.0, (sum, i) => sum + i.lineTotal);

  /// À appeler une fois au démarrage de l'app (voir app.dart) pour recharger
  /// le panier sauvegardé — revérifie la disponibilité de chaque article.
  Future<void> hydrate() async {
    if (_hydrated) return;
    _hydrated = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) return;
      final List<dynamic> lines = jsonDecode(raw);
      final productService = ProductService();
      for (final line in lines) {
        final product = await productService.getById(line['productId']);
        if (product == null || !product.inStock) continue;
        final key = '${product.id}_${line['size'] ?? ''}_${line['color'] ?? ''}';
        _items[key] = CartItem(
          product: product,
          size: line['size'],
          color: line['color'],
          quantity: line['quantity'] ?? 1,
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Impossible de restaurer le panier : $e');
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lines = _items.values.map((i) => {
            'productId': i.product.id,
            'size': i.size,
            'color': i.color,
            'quantity': i.quantity,
          }).toList();
      await prefs.setString(_storageKey, jsonEncode(lines));
    } catch (e) {
      debugPrint('Impossible de sauvegarder le panier : $e');
    }
  }

  void addItem(Product product, {String? size, String? color, int quantity = 1}) {
    final key = '${product.id}_${size ?? ''}_${color ?? ''}';
    if (_items.containsKey(key)) {
      _items[key]!.quantity += quantity;
    } else {
      _items[key] = CartItem(product: product, size: size, color: color, quantity: quantity);
    }
    notifyListeners();
    _persist();
  }

  void increment(String lineKey) {
    _items[lineKey]?.quantity++;
    notifyListeners();
    _persist();
  }

  void decrement(String lineKey) {
    final item = _items[lineKey];
    if (item == null) return;
    if (item.quantity <= 1) {
      _items.remove(lineKey);
    } else {
      item.quantity--;
    }
    notifyListeners();
    _persist();
  }

  void removeItem(String lineKey) {
    _items.remove(lineKey);
    notifyListeners();
    _persist();
  }

  void clear() {
    _items.clear();
    notifyListeners();
    _persist();
  }

  List<Map<String, dynamic>> toOrderItems() =>
      _items.values.map((i) => i.toOrderMap()).toList();
}
