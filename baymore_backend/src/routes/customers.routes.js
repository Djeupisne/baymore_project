const express = require('express');
const prisma = require('../lib/prisma');
const { requireAuth, requireStaff } = require('../middleware/auth');

const router = express.Router();
router.use(requireAuth, requireStaff);

router.get('/', async (req, res) => {
  const { search, page = '1', limit = '20' } = req.query;
  const pageNum = parseInt(page, 10);
  const limitNum = parseInt(limit, 10);
  const skip = (pageNum - 1) * limitNum;
  
  const where = { role: 'CUSTOMER' };
  if (search) {
    where.OR = [
      { name: { contains: search, mode: 'insensitive' } },
      { email: { contains: search, mode: 'insensitive' } },
      { phone: { contains: search } },
    ];
  }
  
  const [customers, total] = await Promise.all([
    prisma.user.findMany({
      where,
      select: { id: true, name: true, email: true, phone: true, loyaltyPoints: true, walletBalance: true, createdAt: true },
      skip,
      take: limitNum,
      orderBy: { createdAt: 'desc' }
    }),
    prisma.user.count({ where })
  ]);
  
  res.json({ 
    customers, 
    pagination: {
      page: pageNum,
      limit: limitNum,
      total,
      totalPages: Math.ceil(total / limitNum)
    }
  });
});

router.get('/:id/orders', async (req, res) => {
  const orders = await prisma.order.findMany({ where: { userId: req.params.id }, orderBy: { createdAt: 'desc' } });
  res.json({ orders });
});

module.exports = router;
