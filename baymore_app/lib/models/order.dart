import 'order_status.dart';

enum DeliveryMode { domicile, retrait }

extension DeliveryModeX on DeliveryMode {
  static DeliveryMode fromString(String v) => v == 'RETRAIT' ? DeliveryMode.retrait : DeliveryMode.domicile;
  String get asString => this == DeliveryMode.retrait ? 'RETRAIT' : 'DOMICILE';
  String get label => this == DeliveryMode.retrait ? 'Retrait en boutique' : 'Livraison à domicile';
}

class OrderStatusEvent {
  final OrderStatus status;
  final DateTime timestamp;
  OrderStatusEvent({required this.status, required this.timestamp});

  factory OrderStatusEvent.fromJson(Map<String, dynamic> json) {
    return OrderStatusEvent(
      status: OrderStatusX.fromString(json['status'] ?? ''),
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
    );
  }
}

class AppOrder {
  final String id;
  final String userId;
  final List<Map<String, dynamic>> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final String? promoCode;
  final double total;
  final DeliveryMode deliveryMode;
  final String deliveryAddress;
  final String paymentMethod; // especes, flooz, tmoney
  final String paymentStatus; // NON_REQUIS, EN_ATTENTE, PAYE, ECHOUE
  final OrderStatus status;
  final List<OrderStatusEvent> statusHistory;
  final String? driverName;
  final String? driverPhone;
  final double? driverLat;
  final double? driverLng;
  final DateTime createdAt;

  AppOrder({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    this.discount = 0,
    this.promoCode,
    required this.total,
    required this.deliveryMode,
    required this.deliveryAddress,
    required this.paymentMethod,
    this.paymentStatus = 'NON_REQUIS',
    required this.status,
    required this.statusHistory,
    this.driverName,
    this.driverPhone,
    this.driverLat,
    this.driverLng,
    required this.createdAt,
  });

  bool get isActive => status != OrderStatus.livree && status != OrderStatus.annulee;

  factory AppOrder.fromJson(Map<String, dynamic> json) {
    return AppOrder(
      id: json['id'],
      userId: json['userId'] ?? '',
      items: List<Map<String, dynamic>>.from(json['items'] ?? []),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      promoCode: json['promoCode'],
      total: (json['total'] ?? 0).toDouble(),
      deliveryMode: DeliveryModeX.fromString(json['deliveryMode'] ?? 'DOMICILE'),
      deliveryAddress: json['deliveryAddress'] ?? '',
      paymentMethod: json['paymentMethod'] ?? 'especes',
      paymentStatus: json['paymentStatus'] ?? 'NON_REQUIS',
      status: OrderStatusX.fromString(json['status'] ?? 'EN_ATTENTE'),
      statusHistory: (json['statusHistory'] as List<dynamic>? ?? [])
          .map((e) => OrderStatusEvent.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      driverName: json['driverName'],
      driverPhone: json['driverPhone'],
      driverLat: json['driverLat']?.toDouble(),
      driverLng: json['driverLng']?.toDouble(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}
