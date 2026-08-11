import 'order_status.dart';

class AppOrder {
  final String id;
  final String userId;
  final List<Map<String, dynamic>> items;
  final double total;
  final String deliveryMode;
  final String deliveryAddress;
  final String paymentMethod;
  final String paymentStatus;
  final OrderStatus status;
  final String? driverName;
  final String? driverPhone;
  final DateTime createdAt;

  AppOrder({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.deliveryMode,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    this.driverName,
    this.driverPhone,
    required this.createdAt,
  });

  factory AppOrder.fromJson(Map<String, dynamic> json) {
    return AppOrder(
      id: json['id'],
      userId: json['userId'] ?? '',
      items: List<Map<String, dynamic>>.from(json['items'] ?? []),
      total: (json['total'] ?? 0).toDouble(),
      deliveryMode: json['deliveryMode'] ?? 'DOMICILE',
      deliveryAddress: json['deliveryAddress'] ?? '',
      paymentMethod: json['paymentMethod'] ?? 'especes',
      paymentStatus: json['paymentStatus'] ?? 'NON_REQUIS',
      status: OrderStatusX.fromString(json['status'] ?? 'EN_ATTENTE'),
      driverName: json['driverName'],
      driverPhone: json['driverPhone'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}
