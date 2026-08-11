class AppAddress {
  final String id;
  final String label;
  final String fullAddress;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  AppAddress({
    required this.id,
    required this.label,
    required this.fullAddress,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  factory AppAddress.fromJson(Map<String, dynamic> json) {
    return AppAddress(
      id: json['id'],
      label: json['label'] ?? '',
      fullAddress: json['fullAddress'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'fullAddress': fullAddress,
      'latitude': latitude,
      'longitude': longitude,
      'isDefault': isDefault,
    };
  }
}
