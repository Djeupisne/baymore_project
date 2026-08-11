# Baymore Back-office

Application réservée à l'équipe boutique et aux livreurs : tableau de
bord, suivi et mise à jour des commandes (Reçue → Prise en charge → En
route → Livrée) avec position GPS en direct, gestion du catalogue, des
codes promo, des retours/remboursements, des avis clients et des clients.

Se connecte à **votre backend** (`baymore_backend/`) — aucune dépendance à
Firebase.

## Mise en route

1. Déployez d'abord `baymore_backend/` sur Render (voir son README).
2. Éditez `lib/config/api_config.dart` avec l'URL de votre backend et
   votre App ID OneSignal (le **même** projet OneSignal que `baymore_app`,
   pour que les notifications ciblent correctement chaque compte staff).
3. Générez les dossiers natifs et lancez :
   ```bash
   cd baymore_backoffice
   flutter create . --org com.baymore --project-name baymore_backoffice
   flutter pub get
   flutter run
   ```

Recommandé : déployez en **web** (`flutter build web`) pour que votre
équipe y accède via un simple lien, sans installation.

## Créer un compte staff

Depuis `baymore_backend/`, une fois déployé :
```bash
node scripts/createStaff.js "Nom de la personne" email@baymore.app motdepasse
```

## Position GPS en direct

Sur une commande "En route", le bouton **"Je livre : partager ma position
en direct"** envoie la position du livreur toutes les 30 mètres au
backend, qui la relaie en direct au client via Socket.io.

**Permissions à ajouter après `flutter create` :**

Android (`android/app/src/main/AndroidManifest.xml`, avant `<application>`) :
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

iOS (`ios/Runner/Info.plist`) :
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Baymore a besoin de votre position pour partager votre trajet de livraison avec le client.</string>
```

## Fonctionnalités
- **Aperçu** : CA du jour, tendance 7 jours, top ventes, commandes à traiter.
- **Commandes** : liste temps réel (Socket.io), fait avancer chaque
  commande, assigne un livreur, partage la position GPS.
- **Clients** : recherche, fiche détaillée avec historique de commandes,
  appel/WhatsApp en un clic.
- **Plus** : Catalogue (upload photo produit direct depuis le téléphone),
  Codes promo, Retours & remboursements, Avis clients (modération).
