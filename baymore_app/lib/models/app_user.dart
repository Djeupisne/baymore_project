class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final int loyaltyPoints;
  final int walletBalance;
  final String referralCode;
  final String? referredBy;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.loyaltyPoints = 0,
    this.walletBalance = 0,
    required this.referralCode,
    this.referredBy,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      loyaltyPoints: json['loyaltyPoints'] ?? 0,
      walletBalance: json['walletBalance'] ?? 0,
      referralCode: json['referralCode'] ?? '',
      referredBy: json['referredBy'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}
