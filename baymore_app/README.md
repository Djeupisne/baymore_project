# Baymore — Application mobile (Flutter)

Application e-commerce complète pour la boutique **Baymore** (accessoires
femme, homme, enfant : habits, sacs, chaussures, cosmétiques), avec
commande en ligne, choix du mode de livraison, **suivi de commande en
temps réel**, avis clients, codes promo, parrainage, portefeuille cashback
et bien plus.

Cette app se connecte à **votre propre backend** (`baymore_backend/` —
Node.js/Express/PostgreSQL, hébergé sur Render). Aucune dépendance à
Firebase.

---

## 1. Architecture

| Besoin | Solution |
|---|---|
| Backend, base de données, logique métier | `baymore_backend/` (à déployer en premier — voir son README) |
| Authentification | JWT, géré par le backend |
| Suivi de commande en temps réel | Socket.io |
| Photos produits | UploadThing (via le backend) |
| Paiement Flooz / T-Money | CinetPay (via le backend) |
| Notifications push | OneSignal |

```
lib/
  config/       -> api_config.dart : adresses de votre backend + OneSignal App ID
  models/       -> Product, Order, AppUser, CartItem, AppAddress, Review, ReturnRequest
  services/     -> ApiClient (HTTP + JWT), SocketService, AuthService, ProductService,
                    OrderService, etc. — un service par domaine, qui appelle l'API REST
  providers/    -> AuthProvider, CartProvider, FavoritesProvider (état global)
  screens/      -> tous les écrans (auth, accueil, produit, panier, checkout,
                    suivi de commande, commandes, favoris, profil)
  widgets/      -> composants réutilisables
  theme/        -> couleurs et typographie de la charte Baymore
```

---

## 2. Mise en route

### 2.1 Déployez d'abord le backend
Suivez `baymore_backend/README.md` pour déployer sur Render. Notez l'URL
de votre service une fois en ligne (ex. `https://baymore-backend.onrender.com`).

### 2.2 Configurez l'app pour pointer vers votre backend
Éditez `lib/config/api_config.dart` :
```dart
static const String baseUrl = 'https://votre-backend.onrender.com/api';
static const String socketUrl = 'https://votre-backend.onrender.com';
static const String oneSignalAppId = 'votre-app-id-onesignal';
```

### 2.3 Générez les dossiers natifs et lancez
```bash
cd baymore_app
flutter create . --org com.baymore --project-name baymore
flutter pub get
flutter run
```

---

## 3. Notifications push — OneSignal

1. Créez un compte sur https://onesignal.com et une app (Android + iOS).
2. Récupérez l'**App ID** (Settings > Keys & IDs) et collez-le dans
   `api_config.dart`.
3. Renseignez aussi `ONESIGNAL_APP_ID` et `ONESIGNAL_API_KEY` côté backend
   (voir `baymore_backend/README.md` section 6).
4. Suivez la doc officielle OneSignal pour finaliser la config native
   (Android : rien de plus à faire ; iOS : capability "Push Notifications"
   + clé APNs à importer dans le dashboard OneSignal).

L'app appelle automatiquement `OneSignal.login(userId)` à la connexion —
le backend peut ensuite cibler directement ce client pour toute
notification (changement de statut de commande, retour en stock, etc.).

---

## 4. Suivi de commande en temps réel

`OrderService.watchOrder(orderId)` récupère l'état initial via l'API puis
écoute les mises à jour poussées par le serveur via **Socket.io**
(`order:update`). Dès qu'un membre du staff fait avancer une commande
depuis le back-office, le client la voit progresser instantanément, sans
rafraîchir.

---

## 5. Checklist avant publication sur le Play Store

1. **Icône & nom d'app** : placez votre icône finale (carrée, min.
   1024×1024px) dans `assets/icons/app_icon.png`, puis :
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```
2. **Nom du package** : vérifiez `applicationId` dans
   `android/app/build.gradle` (ex. `com.baymore.app`).
3. **Signature de l'application** :
   ```bash
   keytool -genkey -v -keystore ~/baymore-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias baymore
   ```
   Renseignez ensuite `android/key.properties`.
4. **Build de production** :
   ```bash
   flutter build appbundle --release
   ```
5. **Fiche Play Store** : captures d'écran, description, politique de
   confidentialité (le modèle fourni dans l'app — Profil > Politique de
   confidentialité — est un bon point de départ à personnaliser),
   catégorie "Shopping".
6. **Compte développeur Google Play** : frais unique de 25 $ si pas déjà
   fait.
7. **Permissions natives à ajouter** après `flutter create .` :
   - Android (`AndroidManifest.xml`) : `ACCESS_FINE_LOCATION` /
     `ACCESS_COARSE_LOCATION` (carte de suivi livreur, optionnel côté
     client — utilisé surtout côté back-office).
   - Une clé Google Maps API si vous affichez la carte du livreur.

---

## 6. Fonctionnalités incluses

Recherche avec filtres (taille, couleur, prix), carnet d'adresses, codes
promo, avis clients avec note moyenne recalculée automatiquement,
recommander une commande passée en un clic, contact WhatsApp rapide,
points fidélité + portefeuille cashback (2% par commande livrée),
parrainage (50 points offerts aux deux comptes), alertes de retour en
stock, annulation de commande côté client, demandes de retour/
remboursement, suppression de compte (conformité Play Store), panier
persistant entre les sessions.

## 7. Prochaines évolutions possibles
- Back-office web (le projet `baymore_backoffice/` fonctionne déjà en
  mobile ; `flutter build web` pour le déployer aussi en version web).
- Utilisation du solde portefeuille comme moyen de paiement au checkout.
- Recherche par image, suggestions personnalisées.
