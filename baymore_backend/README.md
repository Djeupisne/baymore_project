# Baymore Backend — Node.js / Express / PostgreSQL, hébergé sur Render

Backend complet et autonome pour l'écosystème Baymore (app client +
back-office), sans dépendance à Firebase. Vous en gardez l'entière
maîtrise : base de données, authentification, logique métier, tout tourne
sur votre propre serveur.

## Stack technique
- **Express** — API REST
- **PostgreSQL + Prisma** — base de données et ORM
- **JWT** (access + refresh token) — authentification, avec mots de passe
  hashés (bcrypt)
- **Socket.io** — suivi de commande en temps réel et alertes staff
- **UploadThing** (SDK Node officiel) — hébergement des photos produits
- **CinetPay** — paiement Flooz / T-Money

## 1. Développement local

```bash
cd baymore_backend
npm install
cp .env.example .env
# Éditez .env : DATABASE_URL vers un Postgres local, secrets JWT, etc.
npx prisma migrate dev --name init
npm run dev
```

Le serveur démarre sur `http://localhost:4000`. Testez avec :
```bash
curl http://localhost:4000/health
```

## 2. Déploiement sur Render

### Option A — Blueprint automatique (recommandé)
1. Poussez ce dossier `baymore_backend/` dans un dépôt Git (GitHub/GitLab).
2. Sur [dashboard.render.com](https://dashboard.render.com) → **New** →
   **Blueprint** → sélectionnez votre dépôt. Render lit `render.yaml` et
   crée automatiquement la base PostgreSQL **et** le service web.
3. Une fois créé, allez dans le service `baymore-backend` → **Environment**
   et renseignez les variables marquées `sync: false` :
   `CLIENT_APP_URL`, `CINETPAY_APIKEY`, `CINETPAY_SITE_ID`,
   `UPLOADTHING_TOKEN`, `BACKEND_PUBLIC_URL` (l'URL Render de votre
   service, ex. `https://baymore-backend.onrender.com`).
4. Render build et déploie automatiquement (`prisma migrate deploy`
   s'exécute à chaque déploiement, donc vos futures migrations partent
   avec).

### Option B — Manuel
1. Créez une base PostgreSQL sur Render (**New** → **PostgreSQL**), copiez
   son "Internal Connection String".
2. Créez un Web Service (**New** → **Web Service**) pointant sur ce repo :
   - Build command : `npm install && npx prisma generate && npx prisma migrate deploy`
   - Start command : `npm start`
3. Renseignez toutes les variables listées dans `.env.example`.

## 3. Créer votre premier compte staff (accès back-office)

Une fois déployé, ouvrez un Shell Render (service → **Shell**) ou lancez en
local avec `DATABASE_URL` pointant vers la prod :

```bash
node scripts/createStaff.js "Emmanuel" emmanuel@baymore.app motdepasse123
```

## 4. Vue d'ensemble de l'API

Toutes les routes sont préfixées par `/api`. Authentification par en-tête
`Authorization: Bearer <accessToken>`.

| Domaine | Routes clés |
|---|---|
| Auth | `POST /auth/register`, `/auth/login`, `/auth/staff/login`, `/auth/refresh`, `GET/PATCH/DELETE /auth/me` |
| Produits | `GET /products`, `GET /products/:id`, `POST/PUT/DELETE /products/:id` (staff) |
| Avis | `GET/POST /products/:id/reviews`, `DELETE /products/reviews/:id` (staff) |
| Adresses | `GET/POST/PUT/DELETE /addresses` |
| Commandes | `POST /orders`, `GET /orders/mine`, `GET /orders/:id`, `PATCH /orders/:id/cancel`, `PATCH /orders/:id/status` (staff), `PATCH /orders/:id/driver` (staff), `PATCH /orders/:id/driver-position` (staff) |
| Paiement | `POST /payments/initiate`, `POST /payments/webhook` (CinetPay) |
| Codes promo | `POST /promo/validate`, `GET /promo/active`, CRUD `/promo` (staff) |
| Retours | `POST /returns`, `GET /returns/mine`, `GET /returns/order/:orderId`, CRUD `/returns` (staff) |
| Alertes stock | `GET/POST/DELETE /stock-alerts/:productId` |
| Clients (staff) | `GET /customers`, `GET /customers/:id/orders` |
| Portefeuille | `GET /wallet` |
| Favoris | `GET/POST/DELETE /favorites/:productId` |
| Images | `POST /uploads/image` (staff, `multipart/form-data`, champ `file`) |

## 5. Temps réel (Socket.io)

Connexion : `io("https://votre-backend.onrender.com")`

| Événement émis par le client | Effet |
|---|---|
| `order:watch` (orderId) | Rejoint la room de cette commande |
| `order:unwatch` (orderId) | Quitte la room |
| `staff:join` | Rejoint la room "staff" (back-office) |

| Événement reçu | Quand |
|---|---|
| `order:update` | Statut, position livreur ou paiement mis à jour |
| `order:new` | (staff uniquement) Nouvelle commande créée |

## 6. Notifications push — OneSignal

1. Créez un compte sur https://onesignal.com et une app (choisissez
   Android + iOS lors de la configuration).
2. Dans **Settings > Keys & IDs**, récupérez l'**App ID** et la **REST API
   Key**.
3. Renseignez `ONESIGNAL_APP_ID` et `ONESIGNAL_API_KEY` dans les variables
   d'environnement Render (ou `.env` en local).
4. Côté app Flutter, `OneSignal.login(userId)` associe l'appareil au
   compte Baymore — le backend cible ensuite directement cet identifiant
   pour envoyer les notifications, sans rien stocker de plus côté serveur.

Notifications envoyées automatiquement : nouvelle commande (staff),
changement de statut de commande (client), mise à jour d'une demande de
retour (client), retour en stock d'un article suivi (client).

## 7. Prochaine étape

Les deux apps Flutter (`baymore_app` et `baymore_backoffice`) utilisent
encore les packages Firebase et doivent être adaptées pour consommer cette
API à la place. C'est la suite immédiate du travail.
