# Projet Baymore — vue d'ensemble

Trois composants, sans aucune dépendance à Firebase :

- **`baymore_backend/`** — Node.js/Express + PostgreSQL (Prisma) +
  Socket.io, hébergé sur Render. C'est le cœur du système : base de
  données, authentification, paiement (CinetPay), notifications
  (OneSignal), images (UploadThing). **À déployer en premier.**
- **`baymore_app/`** — l'application cliente (Play Store).
- **`baymore_backoffice/`** — l'application de gestion pour la boutique
  et les livreurs (mobile ou web).

## Ordre de mise en route

1. **Backend** : suivez `baymore_backend/README.md` — déployez sur
   Render (base PostgreSQL + service web créés automatiquement via le
   Blueprint `render.yaml`), configurez CinetPay, UploadThing et
   OneSignal.
2. **Créez votre premier compte staff** :
   ```bash
   node scripts/createStaff.js "Votre nom" vous@baymore.app motdepasse
   ```
3. **App cliente** : éditez `baymore_app/lib/config/api_config.dart`
   avec l'URL de votre backend et votre App ID OneSignal, puis lancez-la.
4. **Back-office** : même étape dans
   `baymore_backoffice/lib/config/api_config.dart`.
5. Ajoutez vos premiers produits depuis le back-office (Catalogue >
   Ajouter un article) — les photos s'uploadent directement vers
   UploadThing depuis l'app.

Chaque dossier a son propre README détaillé pour aller plus loin.
