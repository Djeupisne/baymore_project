const express = require('express');
const prisma = require('../lib/prisma');
const { requireAuth, requireStaff } = require('../middleware/auth');
const { emitOrderUpdate, emitNewOrderToStaff } = require('../lib/socket');
const { sendPushToUsers } = require('../services/onesignal');

const router = express.Router();

const NEXT_STATUS = {
  EN_ATTENTE: 'PRIS_EN_CHARGE',
  PRIS_EN_CHARGE: 'EN_ROUTE',
  EN_ROUTE: 'LIVRE',
};

const STATUS_LABELS = {
  PRIS_EN_CHARGE: 'Votre commande est prise en charge',
  EN_ROUTE: 'Votre livreur est en route',
  LIVRE: 'Votre commande a été livrée',
  ANNULE: 'Votre commande a été annulée',
};

/** Crée la commande du client connecté. */
router.post('/', requireAuth, async (req, res) => {
  const { items, subtotal, deliveryFee, discount, promoCode, total, deliveryMode, deliveryAddress, paymentMethod } = req.body;
  if (!items?.length) return res.status(400).json({ error: 'Panier vide.' });

  const order = await prisma.order.create({
    data: {
      userId: req.user.id,
      items,
      subtotal, deliveryFee, discount: discount || 0, promoCode,
      total, deliveryMode, deliveryAddress, paymentMethod,
      paymentStatus: paymentMethod === 'especes' ? 'NON_REQUIS' : 'EN_ATTENTE',
      status: 'EN_ATTENTE',
      statusHistory: [{ status: 'EN_ATTENTE', timestamp: new Date().toISOString() }],
    },
  });

  emitNewOrderToStaff(order);

  const staffMembers = await prisma.user.findMany({ where: { role: 'STAFF' }, select: { id: true } });
  sendPushToUsers(staffMembers.map((s) => s.id), {
    title: 'Baymore — Nouvelle commande',
    body: `Commande #${order.id.substring(0, 6).toUpperCase()} — ${order.total} F CFA`,
    data: { orderId: order.id, type: 'new_order' },
  });

  res.status(201).json({ order });
});

/** Commandes du client connecté (actives ou historique). */
router.get('/mine', requireAuth, async (req, res) => {
  const { scope } = req.query; // 'active' | 'history'
  const activeStatuses = ['EN_ATTENTE', 'PRIS_EN_CHARGE', 'EN_ROUTE'];
  const where = {
    userId: req.user.id,
    status: scope === 'history' ? { in: ['LIVRE', 'ANNULE'] } : { in: activeStatuses },
  };
  const orders = await prisma.order.findMany({ where, orderBy: { createdAt: 'desc' } });
  res.json({ orders });
});

/** Détail d'une commande (propriétaire ou staff). */
router.get('/:id', requireAuth, async (req, res) => {
  const order = await prisma.order.findUnique({ where: { id: req.params.id } });
  if (!order) return res.status(404).json({ error: 'Commande introuvable.' });
  if (order.userId !== req.user.id && req.user.role !== 'STAFF') {
    return res.status(403).json({ error: 'Accès refusé.' });
  }
  res.json({ order });
});

/** Le client annule sa propre commande, uniquement si elle est encore "reçue". */
router.patch('/:id/cancel', requireAuth, async (req, res) => {
  const order = await prisma.order.findUnique({ where: { id: req.params.id } });
  if (!order) return res.status(404).json({ error: 'Commande introuvable.' });
  if (order.userId !== req.user.id) return res.status(403).json({ error: 'Accès refusé.' });
  if (order.status !== 'EN_ATTENTE') {
    return res.status(400).json({ error: 'Cette commande ne peut plus être annulée.' });
  }
  const updated = await advanceStatus(order, 'ANNULE');
  res.json({ order: updated });
});

// ---- Réservé au staff ----

router.get('/', requireAuth, requireStaff, async (req, res) => {
  const orders = await prisma.order.findMany({ orderBy: { createdAt: 'desc' } });
  res.json({ orders });
});

router.patch('/:id/status', requireAuth, requireStaff, async (req, res) => {
  const order = await prisma.order.findUnique({ where: { id: req.params.id } });
  if (!order) return res.status(404).json({ error: 'Commande introuvable.' });

  const { status } = req.body; // avance au statut suivant si non précisé
  const nextStatus = status || NEXT_STATUS[order.status];
  if (!nextStatus) return res.status(400).json({ error: 'Aucune étape suivante possible.' });

  const updated = await advanceStatus(order, nextStatus);

  const label = STATUS_LABELS[nextStatus];
  if (label) {
    sendPushToUsers([order.userId], { title: 'Baymore', body: label, data: { orderId: order.id, type: 'order_status' } });
  }

  // Cashback (2%) + points fidélité (1 pt / 1000 F) à la livraison.
  if (nextStatus === 'LIVRE') {
    const points = Math.floor(order.total / 1000);
    const cashback = Math.round(order.total * 0.02);
    if (points > 0 || cashback > 0) {
      await prisma.user.update({
        where: { id: order.userId },
        data: { loyaltyPoints: { increment: points }, walletBalance: { increment: cashback } },
      });
    }
    if (cashback > 0) {
      await prisma.walletTransaction.create({
        data: { userId: order.userId, amount: cashback, reason: `Cashback commande #${order.id.substring(0, 6).toUpperCase()}` },
      });
    }
  }

  res.json({ order: updated });
});

router.patch('/:id/driver', requireAuth, requireStaff, async (req, res) => {
  const { driverName, driverPhone } = req.body;
  const order = await prisma.order.update({ where: { id: req.params.id }, data: { driverName, driverPhone } });
  emitOrderUpdate(order.id, order);
  res.json({ order });
});

/** Position GPS du livreur, envoyée en direct pendant la livraison. */
router.patch('/:id/driver-position', requireAuth, requireStaff, async (req, res) => {
  const { lat, lng } = req.body;
  const order = await prisma.order.update({ where: { id: req.params.id }, data: { driverLat: lat, driverLng: lng } });
  emitOrderUpdate(order.id, order);
  res.json({ order });
});

async function advanceStatus(order, newStatus) {
  const history = Array.isArray(order.statusHistory) ? order.statusHistory : [];
  const updated = await prisma.order.update({
    where: { id: order.id },
    data: {
      status: newStatus,
      statusHistory: [...history, { status: newStatus, timestamp: new Date().toISOString() }],
    },
  });
  emitOrderUpdate(updated.id, updated);
  return updated;
}

module.exports = router;
