const express = require('express');
const prisma = require('../lib/prisma');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();
router.use(requireAuth);

router.get('/', async (req, res) => {
  const user = await prisma.user.findUnique({ where: { id: req.user.id }, select: { favoriteProductIds: true } });
  res.json({ favoriteIds: user.favoriteProductIds });
});

router.post('/:productId', async (req, res) => {
  const user = await prisma.user.findUnique({ where: { id: req.user.id } });
  if (!user.favoriteProductIds.includes(req.params.productId)) {
    await prisma.user.update({
      where: { id: req.user.id },
      data: { favoriteProductIds: { push: req.params.productId } },
    });
  }
  res.json({ favorited: true });
});

router.delete('/:productId', async (req, res) => {
  const user = await prisma.user.findUnique({ where: { id: req.user.id } });
  await prisma.user.update({
    where: { id: req.user.id },
    data: { favoriteProductIds: user.favoriteProductIds.filter((id) => id !== req.params.productId) },
  });
  res.json({ favorited: false });
});

module.exports = router;
