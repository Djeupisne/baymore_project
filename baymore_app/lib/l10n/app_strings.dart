import 'package:flutter/material.dart';
import '../providers/locale_provider.dart';
import 'package:provider/provider.dart';

/// Traductions de l'app. Pour ajouter une nouvelle chaîne : ajoute la clé
/// dans les deux cartes ci-dessous, puis utilise soit un getter nommé (pour
/// les chaînes réutilisées à plusieurs endroits), soit `strings.t('maCle')`
/// directement (pour les chaînes propres à un seul écran) — le texte
/// affiché suit alors automatiquement la langue choisie dans Paramètres,
/// sans redémarrage.
class AppStrings {
  final Map<String, String> _values;
  const AppStrings._(this._values);

  static AppStrings of(BuildContext context, {bool listen = true}) {
    final code = listen 
        ? context.watch<LocaleProvider>().locale.languageCode
        : context.read<LocaleProvider>().locale.languageCode;
    return AppStrings._(code == 'en' ? _en : _fr);
  }

  String _t(String key) => _values[key] ?? key;
  /// Accès direct par clé, pour les chaînes qui n'ont pas de getter dédié.
  String t(String key) => _t(key);
  /// Comme [t], mais remplace chaque `%s` du texte par les valeurs fournies,
  /// dans l'ordre — pour les chaînes avec un prix, un nom, un compte...
  String tf(String key, List<String> args) {
    var result = _t(key);
    for (final a in args) {
      result = result.replaceFirst('%s', a);
    }
    return result;
  }

  // Navigation
  String get navShop => _t('navShop');
  String get navFavorites => _t('navFavorites');
  String get navOrders => _t('navOrders');
  String get navMenu => _t('navMenu');

  // Accueil
  String get discover => _t('discover');
  String get categoryWomen => _t('categoryWomen');
  String get categoryMen => _t('categoryMen');
  String get categoryKids => _t('categoryKids');
  String get categoryBeauty => _t('categoryBeauty');

  // Profil
  String get loyaltyPoints => _t('loyaltyPoints');
  String get orders => _t('orders');
  String get accountBalance => _t('accountBalance');
  String get login => _t('login');
  String get logout => _t('logout');
  String get myAddresses => _t('myAddresses');
  String get myWallet => _t('myWallet');
  String get promoCodes => _t('promoCodes');
  String get settings => _t('settings');
  String get contactShop => _t('contactShop');

  // Paramètres
  String get language => _t('language');
  String get french => _t('french');
  String get english => _t('english');
  String get notifications => _t('notifications');
  String get enabled => _t('enabled');
  String get appVersion => _t('appVersion');
  String get dangerZone => _t('dangerZone');
  String get deleteAccount => _t('deleteAccount');

  // Statuts de commande
  String get statusPending => _t('statusPending');
  String get statusPendingDesc => _t('statusPendingDesc');
  String get statusPickedUp => _t('statusPickedUp');
  String get statusPickedUpDesc => _t('statusPickedUpDesc');
  String get statusEnRoute => _t('statusEnRoute');
  String get statusEnRouteDesc => _t('statusEnRouteDesc');
  String get statusDelivered => _t('statusDelivered');
  String get statusDeliveredDesc => _t('statusDeliveredDesc');
  String get statusCancelled => _t('statusCancelled');
  String get statusCancelledDesc => _t('statusCancelledDesc');

  // Commandes
  String get myOrders => _t('myOrders');
  String get tabActive => _t('tabActive');
  String get tabHistory => _t('tabHistory');
  String get loginToTrack => _t('loginToTrack');
  String get loginToTrackMsg => _t('loginToTrackMsg');
  String get noActiveOrders => _t('noActiveOrders');
  String get noHistory => _t('noHistory');
  String get noActiveOrdersMsg => _t('noActiveOrdersMsg');
  String get noHistoryMsg => _t('noHistoryMsg');

  // Actions communes
  String get actionCancel => _t('actionCancel');
  String get actionSave => _t('actionSave');
  String get actionApply => _t('actionApply');
  String get actionRemove => _t('actionRemove');
  String get actionEdit => _t('actionEdit');
  String get actionDelete => _t('actionDelete');
  String get actionAdd => _t('actionAdd');
  String get actionPublish => _t('actionPublish');
  String get actionRetry => _t('actionRetry');
  String get subtotal => _t('subtotal');
  String get delivery => _t('delivery');
  String get free => _t('free');
  String get total => _t('total');
  String get loginRequired => _t('loginRequired');

  // Détails commande / paramètres / accueil (batch 2)
  String get t2LomeTogo => _t('lomeTogo');
  String get t2NewCollection => _t('newCollection');
  String get t2RecommendedForYou => _t('recommendedForYou');
  String get t2CatalogPreparing => _t('catalogPreparing');

  // ===== NOUVEAUX GETTERS AJOUTÉS POUR RÉSOUDRE LES ERREURS =====

  // Fiche produit
  String get size => _t('size');
  String get color => _t('color');
  String get description => _t('description');
  String get outOfStock => _t('outOfStock');

  // Portefeuille
  String get history => _t('history');

  // ===== FIN DES NOUVEAUX GETTERS =====

  static const Map<String, String> _fr = {
    'navShop': 'Boutique',
    'navFavorites': 'Favoris',
    'navOrders': 'Commandes',
    'navMenu': 'Menu',
    'discover': 'Découvrir',
    'categoryWomen': 'FEMME',
    'categoryMen': 'HOMME',
    'categoryKids': 'ENFANT',
    'categoryBeauty': 'BEAUTÉ',
    'loyaltyPoints': 'Points fidélité',
    'orders': 'Commandes',
    'accountBalance': 'Solde compte',
    'login': 'Se connecter',
    'logout': 'Se déconnecter',
    'myAddresses': 'Mes adresses',
    'myWallet': 'Mon portefeuille',
    'promoCodes': 'Codes promo',
    'settings': 'Paramètres',
    'contactShop': 'Contacter la boutique (WhatsApp)',
    'language': 'Langue',
    'french': 'Français',
    'english': 'Anglais',
    'notifications': 'Notifications',
    'enabled': 'Activées',
    'appVersion': "Version de l'application",
    'dangerZone': 'Zone de danger',
    'deleteAccount': 'Supprimer mon compte',
    'statusPending': 'Commande reçue',
    'statusPendingDesc': "Votre commande a été enregistrée et attend d'être préparée.",
    'statusPickedUp': 'Prise en charge',
    'statusPickedUpDesc': 'Votre commande est en cours de préparation en boutique.',
    'statusEnRoute': 'En route',
    'statusEnRouteDesc': 'Le livreur a récupéré votre colis et est en route.',
    'statusDelivered': 'Livrée',
    'statusDeliveredDesc': 'Votre commande a été livrée. Merci pour votre confiance !',
    'statusCancelled': 'Annulée',
    'statusCancelledDesc': 'Cette commande a été annulée.',
    'myOrders': 'Mes commandes',
    'tabActive': 'En cours',
    'tabHistory': 'Historique',
    'loginToTrack': 'Connectez-vous',
    'loginToTrackMsg': 'Créez un compte pour suivre vos commandes.',
    'noActiveOrders': 'Aucune commande en cours',
    'noHistory': 'Aucun historique',
    'noActiveOrdersMsg': 'Vos achats en préparation ou en livraison apparaîtront ici.',
    'noHistoryMsg': 'Vos commandes livrées apparaîtront ici.',
    'actionCancel': 'Annuler',
    'actionSave': 'Enregistrer',
    'actionApply': 'Appliquer',
    'actionRemove': 'Retirer',
    'actionEdit': 'Modifier',
    'actionDelete': 'Supprimer',
    'actionAdd': 'Ajouter',
    'actionPublish': 'Publier',
    'actionRetry': 'Réessayer',
    'subtotal': 'Sous-total',
    'delivery': 'Livraison',
    'free': 'Gratuit',
    'total': 'Total',
    'loginRequired': 'Connectez-vous',
    // Authentification
    'authWelcomeBack': 'Bon retour',
    'authWelcomeBackMsg': 'Connectez-vous pour retrouver vos commandes et vos favoris.',
    'authCreateAccount': 'Créer un compte',
    'authNoAccount': 'Pas encore de compte ? Créer un compte',
    'authLoginError': 'Identifiants incorrects. Vérifiez votre e-mail et mot de passe.',
    'authRegisterError': "Impossible de créer le compte. Cet e-mail est peut-être déjà utilisé.",
    'authFullName': 'Nom complet',
    'authNameRequired': 'Nom requis',
    'authEmail': 'E-mail',
    'authEmailInvalid': 'E-mail invalide',
    'authPhone': 'Téléphone (ex. 90 00 00 00)',
    'authPhoneInvalid': 'Numéro invalide',
    'authPassword': 'Mot de passe',
    'authPasswordMin': '6 caractères minimum',
    'authReferralCode': 'Code de parrainage (optionnel)',
    'authCreateMyAccount': 'Créer mon compte',
    'loginPrompt': 'Connectez-vous à votre compte',
    'loginPromptMsg': 'Accédez à vos commandes, vos points fidélité et votre portefeuille.',
    // Panier
    'cartTitle': 'Mon panier',
    'cartEmptyTitle': 'Votre panier est vide',
    'cartEmptyMsg': 'Parcourez la boutique et ajoutez vos articles préférés.',
    'cartContinueShopping': 'Continuer mes achats',
    'deliveryFeeNote': "Frais de livraison calculés à l'étape suivante",
    'placeOrder': 'Passer la commande',
    // Fiche produit
    'productNotFound': 'Article introuvable',
    'size': 'Taille',
    'color': 'Couleur',
    'description': 'Description',
    'noDescription': 'Aucune description disponible pour cet article.',
    'inStock': 'En stock (%s disponibles)',
    'outOfStock': 'Rupture de stock',
    'addedToCart': '%s ajouté au panier',
    'viewCart': 'VOIR',
    'addToCartWithPrice': 'Ajouter au panier — %s',
    'customerReviews': 'Avis clients',
    'leaveReview': 'Laisser un avis',
    'noReviewsYet': 'Aucun avis pour le moment — soyez le premier à donner votre avis.',
    'yourReview': 'Votre avis',
    'yourCommentOptional': 'Votre commentaire (optionnel)',
    'loginToReview': 'Connectez-vous pour laisser un avis.',
    'notifyMeRestock': 'Me prévenir du retour en stock',
    'youWillBeNotified': 'Vous serez prévenu(e)',
    'loginToBeNotified': "Connectez-vous pour être averti du retour en stock.",
    'notifiedWhenBack': 'Vous serez notifié dès que cet article sera de nouveau disponible.',
    // Commande / checkout
    'checkoutTitle': 'Finaliser la commande',
    'deliveryModeTitle': 'Mode de livraison',
    'deliveryHome': 'Livraison à domicile',
    'deliveryHomeSubtitle': 'Un livreur vous apporte la commande — %s',
    'deliveryPickup': 'Retrait en boutique',
    'deliveryPickupSubtitle': 'Récupérez votre commande à la boutique — Gratuit',
    'deliveryAddressTitle': 'Adresse de livraison',
    'addressHint': 'Quartier, rue, repère (ex. non loin de la pharmacie...)',
    'paymentModeTitle': 'Mode de paiement',
    'paymentCash': 'Paiement à la livraison',
    'paymentCashSubtitle': 'Espèces remises au livreur ou en boutique',
    'paymentFlooz': 'Flooz (Mobile Money)',
    'paymentFloozSubtitle': 'Paiement Moov Money',
    'paymentTmoney': 'T-Money (Mobile Money)',
    'paymentTmoneySubtitle': 'Paiement Togocom',
    'promoCode': 'Code promo',
    'promoHint': 'Ex. BIENVENUE10',
    'promoApplied': 'Code appliqué !',
    'promoInvalid': 'Code invalide ou expiré.',
    'summaryTitle': 'Récapitulatif',
    'discountWithCode': 'Remise (%s)',
    'confirmWithTotal': 'Confirmer — %s',
    'addressMissing': 'Veuillez indiquer ou choisir votre adresse de livraison.',
    'loginToOrder': 'Veuillez vous connecter pour commander.',
    'orderError': 'Une erreur est survenue. Veuillez réessayer.',
    'useNewAddress': 'Utiliser une nouvelle adresse',
    // Paiement en attente
    'paymentInProgress': 'Paiement en cours',
    'paymentFailed': 'Le paiement a échoué',
    'paymentFailedMsg': 'Vérifiez votre solde Mobile Money et réessayez, ou choisissez le paiement à la livraison.',
    'retryPayment': 'Réessayer le paiement',
    'awaitingConfirmation': 'En attente de confirmation',
    'awaitingConfirmationMsg': "Validez le paiement dans la fenêtre Flooz / T-Money qui vient de s'ouvrir. Cette page se met à jour automatiquement dès confirmation.",
    // Favoris
    'favoritesTitle': 'Favoris',
    'noFavoritesTitle': 'Aucun favori pour l\'instant',
    'noFavoritesMsg': 'Touchez le cœur sur un article pour le retrouver ici plus tard.',
    'favoritesWillAppear': 'Vos articles favoris apparaîtront ici.',
    // Recherche / catégorie
    'searchHint': 'Rechercher un article, une marque...',
    'searchPromptTitle': 'Que cherchez-vous ?',
    'searchPromptMsg': 'Tapez le nom d\'un article, ex. "sac", "derbies", "coffret"...',
    'noResultsFor': 'Aucun résultat pour "%s"',
    'noResultsFiltered': 'Aucun résultat avec ces filtres',
    'tryOtherKeyword': 'Essayez un autre mot-clé ou parcourez les catégories.',
    'tryWiderFilters': "Essayez d'élargir vos filtres.",
    'itemsCount': '%s article(s)',
    'resultsCount': '%s résultat(s)',
    'filters': 'Filtres',
    'noItemsYet': 'Aucun article ici pour le moment',
    'noItemsYetMsg': 'De nouveaux articles arrivent bientôt dans cette catégorie.',
    'noItemsFiltered': 'Aucun article avec ces filtres',
    // Filtres
    'filterTitle': 'Filtrer',
    'filterReset': 'Réinitialiser',
    'filterPrice': 'Prix : %s — %s',
    'filterApply': 'Appliquer les filtres',
    // Notifications
    'notificationsTitle': 'Notifications',
    'clearAll': 'Tout effacer',
    'noNotifications': 'Aucune notification',
    'noNotificationsMsg': 'Vos alertes de commande, promotions et retours en stock apparaîtront ici.',
    // Adresses
    'noAddresses': 'Aucune adresse enregistrée',
    'noAddressesMsg': 'Ajoutez votre adresse pour commander plus rapidement la prochaine fois.',
    'defaultAddress': 'Par défaut',
    'newAddress': 'Nouvelle adresse',
    'editAddress': "Modifier l'adresse",
    'addressName': 'Nom (ex. Maison, Bureau)',
    'fullAddress': 'Adresse complète, quartier, repère',
    'setAsDefault': 'Adresse par défaut',
    // Portefeuille
    'availableBalance': 'Solde disponible',
    'cashbackNote': '2% de cashback crédité automatiquement à chaque commande livrée',
    'history': 'Historique',
    'noTransactions': 'Aucune transaction pour le moment',
    'noTransactionsMsg': 'Votre cashback apparaîtra ici après votre première commande livrée.',
    'cashback': 'Cashback',
    // Fidélité
    'yourBalance': 'Votre solde',
    'pointsSuffix': '%s points',
    'howToEarnPoints': 'Comment gagner des points ?',
    'earnPointsSpend': '1 point tous les 1 000 F CFA dépensés',
    'earnPointsSpendMsg': 'Crédité automatiquement dès que votre commande est livrée.',
    'earnPointsReferral': '50 points par parrainage',
    'earnPointsReferralMsg': "Vous et votre filleul recevez chacun 50 points quand il utilise votre code à l'inscription.",
    'loyaltyWalletNote': "Vos points fidélité sont distincts de votre solde portefeuille (cashback) — retrouvez-le dans Profil > Mon portefeuille.",
    // Conversion points
    'convertPointsTitle': 'Convertir vos points',
    'convertPointsSubtitle': 'Transformez vos points fidélité en argent FCFA directement dans votre portefeuille.',
    'convertPointsBtn': 'Convertir %s points en FCFA',
    'converting': 'Conversion en cours...',
    'conversionRate': '1 point = 1 FCFA',
    // Codes promo
    'promoCodesTitle': 'Bons de réduction',
    'noPromoCodes': 'Aucun code actif pour le moment',
    'noPromoCodesMsg': 'Revenez bientôt — de nouvelles offres arrivent régulièrement.',
    'fromAmount': "Dès %s d'achat",
    // Modifier le profil
    'editProfileTitle': 'Modifier le profil',
    'lomeTogo': 'Lomé, Togo',
    'newCollection': 'NOUVELLE COLLECTION',
    'recommendedForYou': 'Recommandé pour vous',
    'catalogPreparing': 'Le catalogue est en cours de préparation. Revenez bientôt !',
    'orderNumber': 'Commande #%s',
    'reorder': 'Recommander',
    'orderTrackingTitle': 'Suivi de la commande',
    'orderNotFound': 'Commande introuvable',
    'driverPosition': 'Position du livreur',
    'yourDriver': 'Votre livreur',
    'yourPosition': 'Votre position',
    'deliveryModeLabel': 'Mode de livraison',
    'addressLabel': 'Adresse',
    'paymentLabel': 'Paiement',
    'discountLabel': 'Remise%s',
    'totalLabel': 'Total',
    'returnStatusPending': "En attente d'examen",
    'returnStatusApproved': 'Retour approuvé',
    'returnStatusRefused': 'Retour refusé',
    'returnStatusRefunded': 'Remboursé',
    'orderSteps': 'Étapes de la commande',
    'orderDetails': 'Détails de la commande',
    'shareReceipt': 'Partager le reçu',
    'contactAboutOrder': 'Une question sur cette commande ? Contactez-nous',
    'cancelOrderTitle': 'Annuler la commande ?',
    'cancelOrderMsg': 'Cette action est définitive. Vous pourrez toujours recommander ces articles plus tard.',
    'back': 'Retour',
    'yesCancel': 'Oui, annuler',
    'returnRequestStatus': 'Demande de retour : %s',
    'requestReturn': 'Demander un retour ou remboursement',
    'returnDialogTitle': 'Retour ou remboursement',
    'returnDialogMsg': 'Expliquez brièvement la raison de votre demande.',
    'sendRequest': 'Envoyer la demande',
    'deleteAccountTitle': 'Supprimer votre compte ?',
    'deleteAccountBody': 'Cette action est définitive : votre profil, vos adresses et vos favoris seront supprimés. Vos commandes passées restent conservées pour la comptabilité de la boutique.',
    'deleteAccountPermanently': 'Supprimer définitivement',
    'deleteAccountError': 'Impossible de supprimer le compte pour le moment. Réessayez plus tard.',
    // Contact & Support
    'contactSupport': 'Contact et support',
    'phone': 'Téléphone',
    'email': 'E-mail',
    'chatOnWhatsApp': 'Discuter sur WhatsApp',
    'address': 'Adresse',
    'supportHours': 'Lundi - Samedi : 8h00 - 20h00\nDimanche : 14h00 - 18h00',
  };

  static const Map<String, String> _en = {
    'navShop': 'Shop',
    'navFavorites': 'Favorites',
    'navOrders': 'Orders',
    'navMenu': 'Menu',
    'discover': 'Discover',
    'categoryWomen': 'WOMEN',
    'categoryMen': 'MEN',
    'categoryKids': 'KIDS',
    'categoryBeauty': 'BEAUTY',
    'loyaltyPoints': 'Loyalty points',
    'orders': 'Orders',
    'accountBalance': 'Account balance',
    'login': 'Log in',
    'logout': 'Log out',
    'myAddresses': 'My addresses',
    'myWallet': 'My wallet',
    'promoCodes': 'Promo codes',
    'settings': 'Settings',
    'contactShop': 'Contact the shop (WhatsApp)',
    'language': 'Language',
    'french': 'French',
    'english': 'English',
    'notifications': 'Notifications',
    'enabled': 'Enabled',
    'appVersion': 'App version',
    'dangerZone': 'Danger zone',
    'deleteAccount': 'Delete my account',
    'statusPending': 'Order received',
    'statusPendingDesc': 'Your order has been registered and is awaiting preparation.',
    'statusPickedUp': 'Preparing',
    'statusPickedUpDesc': 'Your order is being prepared in store.',
    'statusEnRoute': 'On the way',
    'statusEnRouteDesc': 'The driver has picked up your package and is on the way.',
    'statusDelivered': 'Delivered',
    'statusDeliveredDesc': 'Your order has been delivered. Thank you for your trust!',
    'statusCancelled': 'Cancelled',
    'statusCancelledDesc': 'This order has been cancelled.',
    'myOrders': 'My orders',
    'tabActive': 'Active',
    'tabHistory': 'History',
    'loginToTrack': 'Log in',
    'loginToTrackMsg': 'Create an account to track your orders.',
    'noActiveOrders': 'No active orders',
    'noHistory': 'No history yet',
    'noActiveOrdersMsg': 'Your purchases being prepared or delivered will appear here.',
    'noHistoryMsg': 'Your delivered orders will appear here.',
    'actionCancel': 'Cancel',
    'actionSave': 'Save',
    'actionApply': 'Apply',
    'actionRemove': 'Remove',
    'actionEdit': 'Edit',
    'actionDelete': 'Delete',
    'actionAdd': 'Add',
    'actionPublish': 'Publish',
    'actionRetry': 'Retry',
    'subtotal': 'Subtotal',
    'delivery': 'Delivery',
    'free': 'Free',
    'total': 'Total',
    'loginRequired': 'Log in',
    // Auth
    'authWelcomeBack': 'Welcome back',
    'authWelcomeBackMsg': 'Log in to find your orders and favorites again.',
    'authCreateAccount': 'Create an account',
    'authNoAccount': "Don't have an account? Create one",
    'authLoginError': 'Incorrect credentials. Check your email and password.',
    'authRegisterError': 'Could not create the account. This email may already be in use.',
    'authFullName': 'Full name',
    'authNameRequired': 'Name required',
    'authEmail': 'Email',
    'authEmailInvalid': 'Invalid email',
    'authPhone': 'Phone (e.g. 90 00 00 00)',
    'authPhoneInvalid': 'Invalid number',
    'authPassword': 'Password',
    'authPasswordMin': 'Minimum 6 characters',
    'authReferralCode': 'Referral code (optional)',
    'authCreateMyAccount': 'Create my account',
    'loginPrompt': 'Log in to your account',
    'loginPromptMsg': 'Access your orders, loyalty points and wallet.',
    // Cart
    'cartTitle': 'My cart',
    'cartEmptyTitle': 'Your cart is empty',
    'cartEmptyMsg': 'Browse the shop and add your favorite items.',
    'cartContinueShopping': 'Continue shopping',
    'deliveryFeeNote': 'Delivery fees calculated at the next step',
    'placeOrder': 'Place order',
    // Product detail
    'productNotFound': 'Item not found',
    'size': 'Size',
    'color': 'Color',
    'description': 'Description',
    'noDescription': 'No description available for this item.',
    'inStock': 'In stock (%s available)',
    'outOfStock': 'Out of stock',
    'addedToCart': '%s added to cart',
    'viewCart': 'VIEW',
    'addToCartWithPrice': 'Add to cart — %s',
    'customerReviews': 'Customer reviews',
    'leaveReview': 'Leave a review',
    'noReviewsYet': 'No reviews yet — be the first to leave one.',
    'yourReview': 'Your review',
    'yourCommentOptional': 'Your comment (optional)',
    'loginToReview': 'Log in to leave a review.',
    'notifyMeRestock': 'Notify me when back in stock',
    'youWillBeNotified': "You'll be notified",
    'loginToBeNotified': 'Log in to be notified when back in stock.',
    'notifiedWhenBack': "You'll be notified as soon as this item is available again.",
    // Checkout
    'checkoutTitle': 'Complete your order',
    'deliveryModeTitle': 'Delivery method',
    'deliveryHome': 'Home delivery',
    'deliveryHomeSubtitle': 'A driver brings your order — %s',
    'deliveryPickup': 'Store pickup',
    'deliveryPickupSubtitle': 'Pick up your order at the store — Free',
    'deliveryAddressTitle': 'Delivery address',
    'addressHint': 'Neighborhood, street, landmark (e.g. near the pharmacy...)',
    'paymentModeTitle': 'Payment method',
    'paymentCash': 'Cash on delivery',
    'paymentCashSubtitle': 'Cash given to the driver or in-store',
    'paymentFlooz': 'Flooz (Mobile Money)',
    'paymentFloozSubtitle': 'Moov Money payment',
    'paymentTmoney': 'T-Money (Mobile Money)',
    'paymentTmoneySubtitle': 'Togocom payment',
    'promoCode': 'Promo code',
    'promoHint': 'E.g. WELCOME10',
    'promoApplied': 'Code applied!',
    'promoInvalid': 'Invalid or expired code.',
    'summaryTitle': 'Summary',
    'discountWithCode': 'Discount (%s)',
    'confirmWithTotal': 'Confirm — %s',
    'addressMissing': 'Please enter or choose your delivery address.',
    'loginToOrder': 'Please log in to place an order.',
    'orderError': 'Something went wrong. Please try again.',
    'useNewAddress': 'Use a new address',
    // Payment pending
    'paymentInProgress': 'Payment in progress',
    'paymentFailed': 'Payment failed',
    'paymentFailedMsg': 'Check your Mobile Money balance and try again, or choose cash on delivery.',
    'retryPayment': 'Retry payment',
    'awaitingConfirmation': 'Awaiting confirmation',
    'awaitingConfirmationMsg': 'Confirm the payment in the Flooz / T-Money window that just opened. This page updates automatically once confirmed.',
    // Favorites
    'favoritesTitle': 'Favorites',
    'noFavoritesTitle': 'No favorites yet',
    'noFavoritesMsg': 'Tap the heart on an item to find it here later.',
    'favoritesWillAppear': 'Your favorite items will appear here.',
    // Search / category
    'searchHint': 'Search an item, a brand...',
    'searchPromptTitle': 'What are you looking for?',
    'searchPromptMsg': 'Type an item name, e.g. "bag", "loafers", "gift set"...',
    'noResultsFor': 'No results for "%s"',
    'noResultsFiltered': 'No results with these filters',
    'tryOtherKeyword': 'Try another keyword or browse the categories.',
    'tryWiderFilters': 'Try widening your filters.',
    'itemsCount': '%s item(s)',
    'resultsCount': '%s result(s)',
    'filters': 'Filters',
    'noItemsYet': 'No items here yet',
    'noItemsYetMsg': 'New items are coming soon to this category.',
    'noItemsFiltered': 'No items with these filters',
    // Filters
    'filterTitle': 'Filter',
    'filterReset': 'Reset',
    'filterPrice': 'Price: %s — %s',
    'filterApply': 'Apply filters',
    // Notifications
    'notificationsTitle': 'Notifications',
    'clearAll': 'Clear all',
    'noNotifications': 'No notifications',
    'noNotificationsMsg': 'Your order alerts, promotions and restock notices will appear here.',
    // Addresses
    'noAddresses': 'No saved addresses',
    'noAddressesMsg': 'Add your address to check out faster next time.',
    'defaultAddress': 'Default',
    'newAddress': 'New address',
    'editAddress': 'Edit address',
    'addressName': 'Name (e.g. Home, Office)',
    'fullAddress': 'Full address, neighborhood, landmark',
    'setAsDefault': 'Default address',
    // Wallet
    'availableBalance': 'Available balance',
    'cashbackNote': '2% cashback automatically credited on every delivered order',
    'history': 'History',
    'noTransactions': 'No transactions yet',
    'noTransactionsMsg': 'Your cashback will appear here after your first delivered order.',
    'cashback': 'Cashback',
    // Loyalty
    'yourBalance': 'Your balance',
    'pointsSuffix': '%s points',
    'howToEarnPoints': 'How to earn points?',
    'earnPointsSpend': '1 point for every 1,000 F CFA spent',
    'earnPointsSpendMsg': 'Automatically credited once your order is delivered.',
    'earnPointsReferral': '50 points per referral',
    'earnPointsReferralMsg': 'You and your referral each get 50 points when they use your code at sign-up.',
    'loyaltyWalletNote': 'Your loyalty points are separate from your wallet balance (cashback) — find it in Profile > My wallet.',
    // Conversion points
    'convertPointsTitle': 'Convert your points',
    'convertPointsSubtitle': 'Transform your loyalty points into FCFA cash directly in your wallet.',
    'convertPointsBtn': 'Convert %s points to FCFA',
    'converting': 'Converting...',
    'conversionRate': '1 point = 1 FCFA',
    // Promo codes
    'promoCodesTitle': 'Promo codes',
    'noPromoCodes': 'No active codes right now',
    'noPromoCodesMsg': "Check back soon — new offers arrive regularly.",
    'fromAmount': 'From %s spent',
    // Edit profile
    'editProfileTitle': 'Edit profile',
    'lomeTogo': 'Lomé, Togo',
    'newCollection': 'NEW COLLECTION',
    'recommendedForYou': 'Recommended for you',
    'catalogPreparing': 'The catalog is being prepared. Check back soon!',
    'orderNumber': 'Order #%s',
    'reorder': 'Reorder',
    'orderTrackingTitle': 'Order tracking',
    'orderNotFound': 'Order not found',
    'driverPosition': "Driver's position",
    'yourDriver': 'Your driver',
    'yourPosition': 'Your position',
    'deliveryModeLabel': 'Delivery method',
    'addressLabel': 'Address',
    'paymentLabel': 'Payment',
    'discountLabel': 'Discount%s',
    'totalLabel': 'Total',
    'returnStatusPending': 'Under review',
    'returnStatusApproved': 'Return approved',
    'returnStatusRefused': 'Return refused',
    'returnStatusRefunded': 'Refunded',
    'orderSteps': 'Order steps',
    'orderDetails': 'Order details',
    'shareReceipt': 'Share receipt',
    'contactAboutOrder': 'A question about this order? Contact us',
    'cancelOrderTitle': 'Cancel this order?',
    'cancelOrderMsg': 'This action is final. You can always reorder these items later.',
    'back': 'Back',
    'yesCancel': 'Yes, cancel',
    'returnRequestStatus': 'Return request: %s',
    'requestReturn': 'Request a return or refund',
    'returnDialogTitle': 'Return or refund',
    'returnDialogMsg': 'Briefly explain the reason for your request.',
    'sendRequest': 'Send request',
    'deleteAccountTitle': 'Delete your account?',
    'deleteAccountBody': 'This action is final: your profile, addresses and favorites will be deleted. Your past orders remain kept for the shop\'s accounting records.',
    'deleteAccountPermanently': 'Delete permanently',
    'deleteAccountError': 'Could not delete the account right now. Please try again later.',
    // Contact & Support
    'contactSupport': 'Contact and support',
    'phone': 'Phone',
    'email': 'Email',
    'chatOnWhatsApp': 'Chat on WhatsApp',
    'address': 'Address',
    'supportHours': 'Monday - Saturday: 8:00 AM - 8:00 PM\\nSunday: 2:00 PM - 6:00 PM',
  };
}