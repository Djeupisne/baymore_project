const express = require('express');
const prisma = require('../lib/prisma');
const { requireAuth, requireStaff, optionalAuth } = require('../middleware/auth');
const { sendPushToUsers } = require('../services/onesignal');

const router = express.Router();

router.get('/', async (req, res) => {
  const { category, search } = req.query;
  const where = {};
  if (category) where.category = category;
  if (search) where.name = { contains: search, mode: 'insensitive' };
  const products = await prisma.product.findMany({ where, orderBy: { name: 'asc' } });
  res.json({ products });
});

router.get('/:id', async (req, res) => {
  const product = await prisma.product.findUnique({ where: { id: req.params.id } });
  if (!product) return res.status(404).json({ error: 'Article introuvable.' });
  res.json({ product });
});

router.post('/', requireAuth, requireStaff, async (req, res) => {
  const { name, category, subCategory, price, oldPrice, images, description, sizes, colors, stock, isNew, isPromo } = req.body;
  const product = await prisma.product.create({
    data: {
      name, category, subCategory, price, oldPrice,
      images: images || [], description: description || '',
      sizes: sizes || [], colors: colors || [], stock: stock || 0,
      isNew: !!isNew, isPromo: !!isPromo,
    },
  });

  // Notification push pour les nouveautés et promotions
  if (product.isNew || product.isPromo) {
    const allCustomers = await prisma.user.findMany({ where: { role: 'CLIENT' }, select: { id: true } });
    const title = product.isNew ? 'Baymore — Nouveauté' : 'Baymore — Promotion';
    const body = product.isNew
      ? `Découvrez "${name}" dans notre nouvelle collection !`
      : `Profitez de -${((price - (oldPrice || price)) / (oldPrice || price) * 100).toFixed(0)}% sur "${name}" !`;
    await sendPushToUsers(allCustomers.map((c) => c.id), {
      title,
      body,
      data: { type: product.isNew ? 'new_product' : 'promotion', productId: product.id, isPromo: product.isPromo },
    });
  }

  res.status(201).json({ product });
});

router.put('/:id', requireAuth, requireStaff, async (req, res) => {
  const { name, category, subCategory, price, oldPrice, images, description, sizes, colors, stock, isNew, isPromo } = req.body;
  const before = await prisma.product.findUnique({ where: { id: req.params.id } });
  const product = await prisma.product.update({
    where: { id: req.params.id },
    data: { name, category, subCategory, price, oldPrice, images, description, sizes, colors, stock, isNew, isPromo },
  });

  // Alerte de retour en stock : si le stock passe de 0 (ou moins) à
  // strictement positif, on notifie tous les clients abonnés puis on
  // nettoie leurs alertes.
  if ((before?.stock ?? 0) <= 0 && (stock ?? 0) > 0) {
    const alerts = await prisma.stockAlert.findMany({ where: { productId: product.id } });
    if (alerts.length > 0) {
      await sendPushToUsers(alerts.map((a) => a.userId), {
        title: 'Baymore',
        body: `"${product.name}" est de nouveau disponible !`,
        data: { productId: product.id, type: 'restock' },
      });
      await prisma.stockAlert.deleteMany({ where: { productId: product.id } });
    }
  }

  // Notification pour nouveauté/promotion si le statut change
  if ((!before?.isNew && isNew) || (!before?.isPromo && isPromo)) {
    const allCustomers = await prisma.user.findMany({ where: { role: 'CLIENT' }, select: { id: true } });
    const title = isNew ? 'Baymore — Nouveauté' : 'Baymore — Promotion';
    const body = isNew
      ? `Découvrez "${name}" dans notre nouvelle collection !`
      : `Profitez de -${oldPrice ? Math.round((1 - price / oldPrice) * 100) : 0}% sur "${name}" !`;
    await sendPushToUsers(allCustomers.map((c) => c.id), {
      title,
      body,
      data: { type: isNew ? 'new_product' : 'promotion', productId: product.id, isPromo },
    });
  }

  res.json({ product });
});

router.delete('/:id', requireAuth, requireStaff, async (req, res) => {
  await prisma.product.delete({ where: { id: req.params.id } });
  res.json({ deleted: true });
});

// ---- Avis clients ----

router.get('/:id/reviews', async (req, res) => {
  const reviews = await prisma.review.findMany({
    where: { productId: req.params.id },
    orderBy: { createdAt: 'desc' },
  });
  res.json({ reviews });
});

router.post('/:id/reviews', requireAuth, async (req, res) => {
  const { rating, comment } = req.body;
  const user = await prisma.user.findUnique({ where: { id: req.user.id } });
  const review = await prisma.review.create({
    data: {
      productId: req.params.id,
      userId: req.user.id,
      userName: user.name,
      rating,
      comment: comment || '',
    },
  });
  await recomputeRating(req.params.id);
  res.status(201).json({ review });
});

router.delete('/reviews/:reviewId', requireAuth, requireStaff, async (req, res) => {
  const review = await prisma.review.delete({ where: { id: req.params.reviewId } });
  await recomputeRating(review.productId);
  res.json({ deleted: true });
});

async function recomputeRating(productId) {
  const reviews = await prisma.review.findMany({ where: { productId } });
  const count = reviews.length;
  const average = count > 0 ? reviews.reduce((s, r) => s + r.rating, 0) / count : 0;
  await prisma.product.update({
    where: { id: productId },
    data: { rating: Math.round(average * 10) / 10, ratingCount: count },
  });
}

module.exports = router;
