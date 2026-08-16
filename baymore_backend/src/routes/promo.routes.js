const express = require('express');
const prisma = require('../lib/prisma');
const { requireAuth, requireStaff } = require('../middleware/auth');
const { sendPushToUsers } = require('../services/onesignal');
const { emitPromoNotification, emitPromoDisabledNotification } = require('../lib/socket');

const router = express.Router();

/** Validation côté serveur — le calcul de remise n'est jamais fait côté client. */
router.post('/validate', requireAuth, async (req, res) => {
  const { code, subtotal } = req.body;
  const promo = await prisma.promoCode.findUnique({ where: { code: (code || '').trim().toUpperCase() } });

  if (!promo) return res.json({ valid: false, discount: 0, message: "Ce code promo n'existe pas." });
  if (!promo.active) return res.json({ valid: false, discount: 0, message: "Ce code promo n'est plus actif." });
  if (promo.expiresAt && promo.expiresAt < new Date()) {
    return res.json({ valid: false, discount: 0, message: 'Ce code promo a expiré.' });
  }
  if (promo.minOrder && subtotal < promo.minOrder) {
    return res.json({ valid: false, discount: 0, message: `Montant minimum requis : ${promo.minOrder} F CFA.` });
  }

  let discount = 0;
  if (promo.type === 'PERCENT') {
    discount = (subtotal * promo.value) / 100;
    if (promo.maxDiscount) discount = Math.min(discount, promo.maxDiscount);
  } else {
    discount = promo.value;
  }
  discount = Math.min(discount, subtotal);

  res.json({
    valid: true,
    discount: Math.round(discount),
    message: promo.type === 'PERCENT' ? `-${promo.value}% appliqué` : `-${promo.value} F CFA appliqué`,
  });
});

/** Liste publique (safe) des codes actifs, pour l'écran "Bons de réduction". */
router.get('/active', requireAuth, async (req, res) => {
  const codes = await prisma.promoCode.findMany({
    where: { active: true, OR: [{ expiresAt: null }, { expiresAt: { gt: new Date() } }] },
  });
  res.json({ codes });
});

// ---- Réservé au staff ----

router.post('/', requireAuth, requireStaff, async (req, res) => {
  const { code, type, value, maxDiscount, minOrder, active, expiresAt, description } = req.body;
  
  if (!code || !type || value === undefined) {
    return res.status(400).json({ error: 'Les champs code, type et value sont obligatoires.' });
  }
  
  const normalizedCode = code.trim().toUpperCase();
  const normalizedType = type.toUpperCase();
  
  // Vérifier si le code existe déjà
  const existing = await prisma.promoCode.findUnique({ where: { code: normalizedCode } });
  if (existing) {
    return res.status(409).json({ error: `Le code promo "${normalizedCode}" existe déjà.` });
  }
  
  const promo = await prisma.promoCode.create({
    data: {
      code: normalizedCode,
      type: normalizedType,
      value,
      maxDiscount: maxDiscount ?? null,
      minOrder: minOrder ?? null,
      active: active ?? true,
      expiresAt: expiresAt ? new Date(expiresAt) : null,
      description: description ?? null,
    },
  });

  // Notification push quand une nouvelle promotion est créée
  const allCustomers = await prisma.user.findMany({ where: { role: 'CUSTOMER' }, select: { id: true } });
  const promoLabel = type === 'PERCENT' ? `-${value}%` : `-${value} F CFA`;
  await sendPushToUsers(allCustomers.map((c) => c.id), {
    title: 'Baymore — Nouvelle Promotion',
    body: `Profitez de ${promoLabel} avec le code ${normalizedCode} !${description ? ' ' + description : ''}`,
    data: { type: 'promotion', code: normalizedCode, promoId: promo.id },
  });

  // Émettre l'événement Socket.io pour les clients connectés
  emitPromoNotification({
    type: 'promotion',
    title: 'Baymore — Nouvelle Promotion',
    body: `Profitez de ${promoLabel} avec le code ${normalizedCode} !${description ? ' ' + description : ''}`,
    promoId: promo.id,
    promoCode: normalizedCode,
  });

  // Enregistrer la notification dans l'historique pour chaque client
  for (const customer of allCustomers) {
    await prisma.notification.create({
      data: {
        userId: customer.id,
        title: 'Baymore — Nouvelle Promotion',
        body: `Profitez de ${promoLabel} avec le code ${normalizedCode} !${description ? ' ' + description : ''}`,
        type: 'PROMOTION',
        data: { code: normalizedCode, promoId: promo.id },
      },
    });
  }

  res.json({ promo });
});

router.get('/', requireAuth, requireStaff, async (req, res) => {
  const { page = '1', limit = '20' } = req.query;
  const pageNum = parseInt(page, 10);
  const limitNum = parseInt(limit, 10);
  const skip = (pageNum - 1) * limitNum;
  
  const [codes, total] = await Promise.all([
    prisma.promoCode.findMany({ 
      orderBy: { createdAt: 'desc' },
      skip,
      take: limitNum
    }),
    prisma.promoCode.count({})
  ]);
  
  res.json({ 
    codes,
    pagination: {
      page: pageNum,
      limit: limitNum,
      total,
      totalPages: Math.ceil(total / limitNum)
    }
  });
});

router.put('/:code', requireAuth, requireStaff, async (req, res) => {
  const code = req.params.code.trim().toUpperCase();
  const { type, value, maxDiscount, minOrder, active, expiresAt, description } = req.body;
  
  const before = await prisma.promoCode.findUnique({ where: { code } });
  const normalizedType = type ? type.toUpperCase() : undefined;
  const promo = await prisma.promoCode.upsert({
    where: { code },
    create: { code, type: normalizedType, value, maxDiscount, minOrder, active: active ?? true, expiresAt: expiresAt ? new Date(expiresAt) : null, description },
    update: { type: normalizedType, value, maxDiscount, minOrder, active, expiresAt: expiresAt ? new Date(expiresAt) : null, description },
  });

  // Notification push quand une nouvelle promotion est créée ou activée
  if (!before || (!before.active && promo.active)) {
    const allCustomers = await prisma.user.findMany({ where: { role: 'CUSTOMER' }, select: { id: true } });
    const promoLabel = type === 'PERCENT' ? `-${value}%` : `-${value} F CFA`;
    await sendPushToUsers(allCustomers.map((c) => c.id), {
      title: 'Baymore — Nouvelle Promotion',
      body: `Profitez de ${promoLabel} avec le code ${code} !${description ? ' ' + description : ''}`,
      data: { type: 'promotion', code, promoId: promo.id },
    });

    // Émettre l'événement Socket.io pour les clients connectés
    emitPromoNotification({
      type: 'promotion',
      title: 'Baymore — Nouvelle Promotion',
      body: `Profitez de ${promoLabel} avec le code ${code} !${description ? ' ' + description : ''}`,
      promoId: promo.id,
      promoCode: code,
    });

    // Enregistrer la notification dans l'historique pour chaque client
    for (const customer of allCustomers) {
      await prisma.notification.create({
        data: {
          userId: customer.id,
          title: 'Baymore — Nouvelle Promotion',
          body: `Profitez de ${promoLabel} avec le code ${code} !${description ? ' ' + description : ''}`,
          type: 'PROMOTION',
          data: { code, promoId: promo.id },
        },
      });
    }
  }

  res.json({ promo });
});

router.patch('/:code/active', requireAuth, requireStaff, async (req, res) => {
  const before = await prisma.promoCode.findUnique({ where: { code: req.params.code } });
  const promo = await prisma.promoCode.update({
    where: { code: req.params.code },
    data: { active: req.body.active },
  });

  const allCustomers = await prisma.user.findMany({ where: { role: 'CUSTOMER' }, select: { id: true } });

  // Notification quand une promo est réactivée
  if (!before?.active && promo.active) {
    await sendPushToUsers(allCustomers.map((c) => c.id), {
      title: 'Baymore — Promotion disponible',
      body: `Le code ${promo.code} est de nouveau actif !`,
      data: { type: 'promotion', code: promo.code, promoId: promo.id },
    });

    // Émettre l'événement Socket.io pour les clients connectés
    emitPromoNotification({
      type: 'promotion',
      title: 'Baymore — Promotion disponible',
      body: `Le code ${promo.code} est de nouveau actif !`,
      promoId: promo.id,
      promoCode: promo.code,
    });

    // Enregistrer la notification dans l'historique pour chaque client
    for (const customer of allCustomers) {
      await prisma.notification.create({
        data: {
          userId: customer.id,
          title: 'Baymore — Promotion disponible',
          body: `Le code ${promo.code} est de nouveau actif !`,
          type: 'PROMOTION',
          data: { code: promo.code, promoId: promo.id },
        },
      });
    }
  }

  // Notification quand une promo est désactivée
  if (before?.active && !promo.active) {
    await sendPushToUsers(allCustomers.map((c) => c.id), {
      title: 'Baymore — Code promo désactivé',
      body: `Le code ${promo.code} n'est plus valable.`,
      data: { type: 'promo_disabled', code: promo.code, promoId: promo.id },
    });

    // Émettre l'événement Socket.io pour les clients connectés
    emitPromoDisabledNotification({
      type: 'promo_disabled',
      title: 'Baymore — Code promo désactivé',
      body: `Le code ${promo.code} n'est plus valable.`,
      promoId: promo.id,
      promoCode: promo.code,
    });

    // Enregistrer la notification dans l'historique pour chaque client
    for (const customer of allCustomers) {
      await prisma.notification.create({
        data: {
          userId: customer.id,
          title: 'Baymore — Code promo désactivé',
          body: `Le code ${promo.code} n'est plus valable.`,
          type: 'PROMO_DISABLED',
          data: { code: promo.code, promoId: promo.id },
        },
      });
    }
  }

  res.json({ promo });
});

router.delete('/:code', requireAuth, requireStaff, async (req, res) => {
  await prisma.promoCode.delete({ where: { code: req.params.code } });
  res.json({ deleted: true });
});

module.exports = router;
