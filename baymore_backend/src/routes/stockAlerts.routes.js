const express = require('express');
const prisma = require('../lib/prisma');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();
router.use(requireAuth);

router.get('/:productId', async (req, res) => {
  const alert = await prisma.stockAlert.findUnique({
    where: { productId_userId: { productId: req.params.productId, userId: req.user.id } },
  });
  res.json({ subscribed: !!alert });
});

router.post('/:productId', async (req, res) => {
  await prisma.stockAlert.upsert({
    where: { productId_userId: { productId: req.params.productId, userId: req.user.id } },
    create: { productId: req.params.productId, userId: req.user.id },
    update: {},
  });
  res.json({ subscribed: true });
});

router.delete('/:productId', async (req, res) => {
  await prisma.stockAlert.deleteMany({ where: { productId: req.params.productId, userId: req.user.id } });
  res.json({ subscribed: false });
});

module.exports = router;
