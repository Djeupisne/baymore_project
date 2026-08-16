import 'package:flutter/widgets.dart';
import '../l10n/app_strings.dart';

enum ReturnStatus { enAttente, approuve, refuse, rembourse }

extension ReturnStatusX on ReturnStatus {
  static ReturnStatus fromString(String v) {
    switch (v) {
      case 'APPROUVE': return ReturnStatus.approuve;
      case 'REFUSE': return ReturnStatus.refuse;
      case 'REMBOURSE': return ReturnStatus.rembourse;
      default: return ReturnStatus.enAttente;
    }
  }
  String get label {
    switch (this) {
      case ReturnStatus.enAttente: return "En attente d'examen";
      case ReturnStatus.approuve: return 'Retour approuvé';
      case ReturnStatus.refuse: return 'Retour refusé';
      case ReturnStatus.rembourse: return 'Remboursé';
    }
  }

  /// Libellé traduit selon la langue choisie — à préférer à [label] partout
  /// où un BuildContext est disponible.
  String labelFor(BuildContext context) {
    final s = AppStrings.of(context);
    switch (this) {
      case ReturnStatus.enAttente: return s.t('returnStatusPending');
      case ReturnStatus.approuve: return s.t('returnStatusApproved');
      case ReturnStatus.refuse: return s.t('returnStatusRefused');
      case ReturnStatus.rembourse: return s.t('returnStatusRefunded');
    }
  }
}

class ReturnRequest {
  final String id;
  final String orderId;
  final String userId;
  final String userName;
  final String reason;
  final ReturnStatus status;
  final String? staffNote;
  final DateTime createdAt;

  ReturnRequest({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.userName,
    required this.reason,
    required this.status,
    this.staffNote,
    required this.createdAt,
  });

  factory ReturnRequest.fromJson(Map<String, dynamic> json) {
    return ReturnRequest(
      id: json['id'],
      orderId: json['orderId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Client',
      reason: json['reason'] ?? '',
      status: ReturnStatusX.fromString(json['status'] ?? 'EN_ATTENTE'),
      staffNote: json['staffNote'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}
