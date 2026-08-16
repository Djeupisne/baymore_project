class Catalog {
  final String id;
  final String name;
  final String description;
  final String? image;
  final List<String> productIds;
  final bool isActive;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Catalog({
    required this.id,
    required this.name,
    required this.description,
    this.image,
    required this.productIds,
    required this.isActive,
    this.startsAt,
    this.endsAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Catalog.fromJson(Map<String, dynamic> json) => Catalog(
        id: json['id'],
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        image: json['image'],
        productIds: List<String>.from(json['productIds'] ?? []),
        isActive: json['isActive'] ?? true,
        startsAt: json['startsAt'] != null ? DateTime.parse(json['startsAt']) : null,
        endsAt: json['endsAt'] != null ? DateTime.parse(json['endsAt']) : null,
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'image': image,
        'productIds': productIds,
        'isActive': isActive,
        'startsAt': startsAt?.toIso8601String(),
        'endsAt': endsAt?.toIso8601String(),
      };
}
