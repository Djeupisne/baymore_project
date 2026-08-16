class PromoCode {
  final String code;
  final String type; // PERCENT, FIXED
  final double value;
  final double? maxDiscount;
  final double? minOrder;
  final bool active;
  final DateTime? expiresAt;
  final String description;

  PromoCode({
    required this.code,
    required this.type,
    required this.value,
    this.maxDiscount,
    this.minOrder,
    this.active = true,
    this.expiresAt,
    this.description = '',
  });

  factory PromoCode.fromJson(Map<String, dynamic> json) {
    return PromoCode(
      code: json['code'],
      type: json['type'] ?? 'PERCENT',
      value: (json['value'] ?? 0).toDouble(),
      maxDiscount: json['maxDiscount'] != null ? (json['maxDiscount']).toDouble() : null,
      minOrder: json['minOrder'] != null ? (json['minOrder']).toDouble() : null,
      active: json['active'] ?? true,
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'type': type,
        'value': value.round(),
        'maxDiscount': maxDiscount?.round(),
        'minOrder': minOrder?.round(),
        'active': active,
        'expiresAt': expiresAt?.toIso8601String(),
        'description': description,
      };
}
