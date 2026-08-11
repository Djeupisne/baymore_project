class Customer {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final int loyaltyPoints;
  final DateTime createdAt;

  Customer({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.loyaltyPoints,
    required this.createdAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      uid: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      loyaltyPoints: json['loyaltyPoints'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}
