class Product {
  final String id;
  final String name;
  final String category;
  final String subCategory;
  final double price;
  final double? oldPrice;
  final List<String> images;
  final String description;
  final List<String> sizes;
  final List<String> colors;
  final double rating;
  final int ratingCount;
  final int stock;
  final bool isNew;
  final bool isPromo;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.subCategory,
    required this.price,
    this.oldPrice,
    required this.images,
    required this.description,
    this.sizes = const [],
    this.colors = const [],
    this.rating = 0,
    this.ratingCount = 0,
    this.stock = 0,
    this.isNew = false,
    this.isPromo = false,
  });

  bool get inStock => stock > 0;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      subCategory: json['subCategory'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      oldPrice: json['oldPrice'] != null ? (json['oldPrice']).toDouble() : null,
      images: List<String>.from(json['images'] ?? []),
      description: json['description'] ?? '',
      sizes: List<String>.from(json['sizes'] ?? []),
      colors: List<String>.from(json['colors'] ?? []),
      rating: (json['rating'] ?? 0).toDouble(),
      ratingCount: json['ratingCount'] ?? 0,
      stock: json['stock'] ?? 0,
      isNew: json['isNew'] ?? false,
      isPromo: json['isPromo'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'subCategory': subCategory,
      'price': price.round(),
      'oldPrice': oldPrice?.round(),
      'images': images,
      'description': description,
      'sizes': sizes,
      'colors': colors,
      'stock': stock,
      'isNew': isNew,
      'isPromo': isPromo,
    };
  }
}
