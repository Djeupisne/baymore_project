const express = require('express');
const prisma = require('../lib/prisma');
const { requireAuth, requireStaff } = require('../middleware/auth');
const { sendPushToUsers } = require('../services/onesignal');

const router = express.Router();

/**
 * Envoyer une notification push pour un nouveau catalogue
 * Réservé au staff/administrateur
 */
router.post('/catalog', requireAuth, requireStaff, async (req, res) => {
  const { catalogId, title, body } = req.body;
  
  if (!catalogId || !title || !body) {
    return res.status(400).json({ error: 'Les champs catalogId, title et body sont obligatoires.' });
  }
  
  // Récupérer tous les clients
  const allCustomers = await prisma.user.findMany({ where: { role: 'CUSTOMER' }, select: { id: true } });
  
  if (allCustomers.length > 0) {
    // Envoyer la notification push OneSignal
    await sendPushToUsers(allCustomers.map((c) => c.id), {
      title,
      body,
      data: { type: 'catalog', catalogId },
    });

    // Enregistrer la notification dans l'historique pour chaque client
    for (const customer of allCustomers) {
      await prisma.notification.create({
        data: {
          userId: customer.id,
          title,
          body,
          type: 'CATALOG',
          data: { catalogId },
        },
      });
    }
  }
  
  res.json({ success: true, sentTo: allCustomers.length });
});

/**
 * Envoyer une notification push pour un nouveau code promo
 * Réservé au staff/administrateur
 */
router.post('/promo', requireAuth, requireStaff, async (req, res) => {
  const { promoId, promoCode, title, body, type } = req.body;
  
  if (!promoId || !promoCode || !title || !body) {
    return res.status(400).json({ error: 'Les champs promoId, promoCode, title et body sont obligatoires.' });
  }
  
  // Récupérer tous les clients
  const allCustomers = await prisma.user.findMany({ where: { role: 'CUSTOMER' }, select: { id: true } });
  
  if (allCustomers.length > 0) {
    // Envoyer la notification push OneSignal
    await sendPushToUsers(allCustomers.map((c) => c.id), {
      title,
      body,
      data: { type: type || 'promotion', promoId, promoCode },
    });

    // Enregistrer la notification dans l'historique pour chaque client
    for (const customer of allCustomers) {
      await prisma.notification.create({
        data: {
          userId: customer.id,
          title,
          body,
          type: type === 'promo_disabled' ? 'PROMO_DISABLED' : 'PROMOTION',
          data: { promoId, promoCode },
        },
      });
    }
  }
  
  res.json({ success: true, sentTo: allCustomers.length });
});

/**
 * Envoyer une notification push pour un code promo désactivé
 * Réservé au staff/administrateur
 */
router.post('/promo-disabled', requireAuth, requireStaff, async (req, res) => {
  const { promoId, promoCode, title, body } = req.body;
  
  if (!promoId || !promoCode || !title || !body) {
    return res.status(400).json({ error: 'Les champs promoId, promoCode, title et body sont obligatoires.' });
  }
  
  // Récupérer tous les clients
  const allCustomers = await prisma.user.findMany({ where: { role: 'CUSTOMER' }, select: { id: true } });
  
  if (allCustomers.length > 0) {
    // Envoyer la notification push OneSignal
    await sendPushToUsers(allCustomers.map((c) => c.id), {
      title,
      body,
      data: { type: 'promo_disabled', promoId, promoCode },
    });

    // Enregistrer la notification dans l'historique pour chaque client
    for (const customer of allCustomers) {
      await prisma.notification.create({
        data: {
          userId: customer.id,
          title,
          body,
          type: 'PROMO_DISABLED',
          data: { promoId, promoCode },
        },
      });
    }
  }
  
  res.json({ success: true, sentTo: allCustomers.length });
});

module.exports = router;
