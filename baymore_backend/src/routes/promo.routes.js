const express = require('express');
const prisma = require('../lib/prisma');
const { requireAuth, requireStaff } = require('../middleware/auth');
const { sendPushToUsers } = require('../services/onesignal');

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

router.get('/', requireAuth, requireStaff, async (req, res) => {
  const codes = await prisma.promoCode.findMany({ orderBy: { createdAt: 'desc' } });
  res.json({ codes });
});

router.put('/:code', requireAuth, requireStaff, async (req, res) => {
  const code = req.params.code.trim().toUpperCase();
  const { type, value, maxDiscount, minOrder, active, expiresAt, description } = req.body;
  
  const before = await prisma.promoCode.findUnique({ where: { code } });
  const promo = await prisma.promoCode.upsert({
    where: { code },
    create: { code, type, value, maxDiscount, minOrder, active: active ?? true, expiresAt: expiresAt ? new Date(expiresAt) : null, description },
    update: { type, value, maxDiscount, minOrder, active, expiresAt: expiresAt ? new Date(expiresAt) : null, description },
  });

  // Notification push quand une nouvelle promotion est créée ou activée
  if (!before || (!before.active && promo.active)) {
    const allCustomers = await prisma.user.findMany({ where: { role: 'CLIENT' }, select: { id: true } });
    const promoLabel = type === 'PERCENT' ? `-${value}%` : `-${value} F CFA`;
    await sendPushToUsers(allCustomers.map((c) => c.id), {
      title: 'Baymore — Nouvelle Promotion',
      body: `Profitez de ${promoLabel} avec le code ${code} !${description ? ' ' + description : ''}`,
      data: { type: 'promotion', code, promoId: promo.id },
    });
  }

  res.json({ promo });
});

router.patch('/:code/active', requireAuth, requireStaff, async (req, res) => {
  const before = await prisma.promoCode.findUnique({ where: { code: req.params.code } });
  const promo = await prisma.promoCode.update({
    where: { code: req.params.code },
    data: { active: req.body.active },
  });

  // Notification quand une promo est réactivée
  if (!before?.active && promo.active) {
    const allCustomers = await prisma.user.findMany({ where: { role: 'CLIENT' }, select: { id: true } });
    await sendPushToUsers(allCustomers.map((c) => c.id), {
      title: 'Baymore — Promotion disponible',
      body: `Le code ${promo.code} est de nouveau actif !`,
      data: { type: 'promotion', code: promo.code, promoId: promo.id },
    });
  }

  res.json({ promo });
});

router.delete('/:code', requireAuth, requireStaff, async (req, res) => {
  await prisma.promoCode.delete({ where: { code: req.params.code } });
  res.json({ deleted: true });
});

module.exports = router;
