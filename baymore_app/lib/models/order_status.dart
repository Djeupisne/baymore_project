/// Les 4 étapes du suivi de commande : reçue -> prise en charge -> en route -> livrée.
/// Les valeurs correspondent exactement à l'enum Postgres/Prisma côté backend.
enum OrderStatus { enAttente, priseEnCharge, enRoute, livree, annulee }

extension OrderStatusX on OrderStatus {
  static OrderStatus fromString(String value) {
    switch (value) {
      case 'PRIS_EN_CHARGE':
        return OrderStatus.priseEnCharge;
      case 'EN_ROUTE':
        return OrderStatus.enRoute;
      case 'LIVRE':
        return OrderStatus.livree;
      case 'ANNULE':
        return OrderStatus.annulee;
      default:
        return OrderStatus.enAttente;
    }
  }

  String get asString {
    switch (this) {
      case OrderStatus.priseEnCharge:
        return 'PRIS_EN_CHARGE';
      case OrderStatus.enRoute:
        return 'EN_ROUTE';
      case OrderStatus.livree:
        return 'LIVRE';
      case OrderStatus.annulee:
        return 'ANNULE';
      case OrderStatus.enAttente:
        return 'EN_ATTENTE';
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.enAttente:
        return 'Commande reçue';
      case OrderStatus.priseEnCharge:
        return 'Prise en charge';
      case OrderStatus.enRoute:
        return 'En route';
      case OrderStatus.livree:
        return 'Livrée';
      case OrderStatus.annulee:
        return 'Annulée';
    }
  }

  String get description {
    switch (this) {
      case OrderStatus.enAttente:
        return "Votre commande a été enregistrée et attend d'être préparée.";
      case OrderStatus.priseEnCharge:
        return 'Votre commande est en cours de préparation en boutique.';
      case OrderStatus.enRoute:
        return 'Le livreur a récupéré votre colis et est en route.';
      case OrderStatus.livree:
        return 'Votre commande a été livrée. Merci pour votre confiance !';
      case OrderStatus.annulee:
        return 'Cette commande a été annulée.';
    }
  }

  int get stepIndex {
    switch (this) {
      case OrderStatus.enAttente:
        return 0;
      case OrderStatus.priseEnCharge:
        return 1;
      case OrderStatus.enRoute:
        return 2;
      case OrderStatus.livree:
        return 3;
      case OrderStatus.annulee:
        return -1;
    }
  }
}
