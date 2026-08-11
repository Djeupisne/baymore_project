import 'product.dart';

class CartItem {
  final Product product;
  final String? size;
  final String? color;
  int quantity;

  CartItem({
    required this.product,
    this.size,
    this.color,
    this.quantity = 1,
  });

  double get lineTotal => product.price * quantity;

  /// Identifiant unique de la ligne (même produit + variante différente = ligne distincte)
  String get lineKey => '${product.id}_${size ?? ''}_${color ?? ''}';

  Map<String, dynamic> toOrderMap() {
    return {
      'productId': product.id,
      'name': product.name,
      'image': product.images.isNotEmpty ? product.images.first : '',
      'price': product.price,
      'size': size,
      'color': color,
      'quantity': quantity,
    };
  }
}
