class Product {
  final String id;
  final String name;
  final String category;
  final String subCategory;
  final double price;
  final List<String> images;
  final String description;
  final int stock;
  final bool isNew;
  final bool isPromo;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.subCategory,
    required this.price,
    required this.images,
    required this.description,
    required this.stock,
    this.isNew = false,
    this.isPromo = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'],
        name: json['name'] ?? '',
        category: json['category'] ?? '',
        subCategory: json['subCategory'] ?? '',
        price: (json['price'] ?? 0).toDouble(),
        images: List<String>.from(json['images'] ?? []),
        description: json['description'] ?? '',
        stock: json['stock'] ?? 0,
        isNew: json['isNew'] ?? false,
        isPromo: json['isPromo'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'subCategory': subCategory,
        'price': price.round(),
        'images': images,
        'description': description,
        'stock': stock,
        'isNew': isNew,
        'isPromo': isPromo,
        'sizes': [],
        'colors': [],
      };
}
