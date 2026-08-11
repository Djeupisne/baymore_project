const express = require('express');
const prisma = require('../lib/prisma');
const { requireAuth, requireStaff } = require('../middleware/auth');

const router = express.Router();
router.use(requireAuth, requireStaff);

router.get('/', async (req, res) => {
  const { search } = req.query;
  const where = { role: 'CUSTOMER' };
  if (search) {
    where.OR = [
      { name: { contains: search, mode: 'insensitive' } },
      { email: { contains: search, mode: 'insensitive' } },
      { phone: { contains: search } },
    ];
  }
  const customers = await prisma.user.findMany({
    where,
    select: { id: true, name: true, email: true, phone: true, loyaltyPoints: true, walletBalance: true, createdAt: true },
  });
  res.json({ customers });
});

router.get('/:id/orders', async (req, res) => {
  const orders = await prisma.order.findMany({ where: { userId: req.params.id }, orderBy: { createdAt: 'desc' } });
  res.json({ orders });
});

module.exports = router;
