enum OrderStatus { enAttente, priseEnCharge, enRoute, livree, annulee }

extension OrderStatusX on OrderStatus {
  static OrderStatus fromString(String value) {
    switch (value) {
      case 'PRIS_EN_CHARGE': return OrderStatus.priseEnCharge;
      case 'EN_ROUTE': return OrderStatus.enRoute;
      case 'LIVRE': return OrderStatus.livree;
      case 'ANNULE': return OrderStatus.annulee;
      default: return OrderStatus.enAttente;
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.enAttente: return 'Reçue';
      case OrderStatus.priseEnCharge: return 'Prise en charge';
      case OrderStatus.enRoute: return 'En route';
      case OrderStatus.livree: return 'Livrée';
      case OrderStatus.annulee: return 'Annulée';
    }
  }

  /// Statut suivant dans le flux (null si déjà terminal).
  OrderStatus? get next {
    switch (this) {
      case OrderStatus.enAttente: return OrderStatus.priseEnCharge;
      case OrderStatus.priseEnCharge: return OrderStatus.enRoute;
      case OrderStatus.enRoute: return OrderStatus.livree;
      default: return null;
    }
  }
}
