const express = require('express');
const http = require('http');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const { Server } = require('socket.io');

const env = require('./config/env');
const { initSocket } = require('./lib/socket');

const authRoutes = require('./routes/auth.routes');
const productsRoutes = require('./routes/products.routes');
const addressesRoutes = require('./routes/addresses.routes');
const ordersRoutes = require('./routes/orders.routes');
const paymentsRoutes = require('./routes/payments.routes');
const promoRoutes = require('./routes/promo.routes');
const notificationsRoutes = require('./routes/notifications.routes');
const returnsRoutes = require('./routes/returns.routes');
const stockAlertsRoutes = require('./routes/stockAlerts.routes');
const customersRoutes = require('./routes/customers.routes');
const uploadsRoutes = require('./routes/uploads.routes');
const walletRoutes = require('./routes/wallet.routes');
const favoritesRoutes = require('./routes/favorites.routes');
const loyaltyRoutes = require('./routes/loyalty.routes');

const app = express();
const server = http.createServer(app);

const io = new Server(server, {
  cors: { origin: '*' }, // resserrez à votre domaine une fois en production si besoin
});
initSocket(io);

// Configuration CORS explicite pour gérer les requêtes cross-origin
const corsOptions = {
  origin: true, // Accepte toutes les origines (à restreindre en production)
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
  optionsSuccessStatus: 200,
};
app.use(cors(corsOptions));
app.use(helmet());
app.use(morgan(env.nodeEnv === 'production' ? 'combined' : 'dev'));

// Le webhook CinetPay envoie du x-www-form-urlencoded — on l'accepte aussi.
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Limite le taux de requêtes global pour se prémunir des abus, sans gêner
// un usage normal de l'app (300 requêtes / 5 min / IP).
app.use(rateLimit({ windowMs: 5 * 60 * 1000, max: 300 }));

app.get('/', (req, res) => res.json({ status: 'ok', service: 'baymore-backend' }));
app.get('/health', (req, res) => res.json({ status: 'ok', time: new Date().toISOString() }));

app.use('/api/auth', authRoutes);
app.use('/api/products', productsRoutes);
app.use('/api/addresses', addressesRoutes);
app.use('/api/orders', ordersRoutes);
app.use('/api/payments', paymentsRoutes);
app.use('/api/promo', promoRoutes);
app.use('/api/notifications', notificationsRoutes);
app.use('/api/returns', returnsRoutes);
app.use('/api/stock-alerts', stockAlertsRoutes);
app.use('/api/customers', customersRoutes);
app.use('/api/uploads', uploadsRoutes);
app.use('/api/wallet', walletRoutes);
app.use('/api/favorites', favoritesRoutes);
app.use('/api/loyalty', loyaltyRoutes);

// Gestionnaire d'erreurs global — évite qu'une exception non prévue ne
// fasse planter le serveur silencieusement.
app.use((err, req, res, next) => {
  console.error(err);
  res.status(err.status || 500).json({ error: err.message || 'Erreur serveur.' });
});

app.use((req, res) => res.status(404).json({ error: 'Route introuvable.' }));

server.listen(env.port, () => {
  console.log(`Baymore backend démarré sur le port ${env.port} (${env.nodeEnv})`);
});
