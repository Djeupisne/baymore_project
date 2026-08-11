const express = require('express');
const prisma = require('../lib/prisma');
const { requireAuth, requireStaff } = require('../middleware/auth');
const { sendPushToUsers } = require('../services/onesignal');

const router = express.Router();

router.post('/', requireAuth, async (req, res) => {
  const { orderId, reason } = req.body;
  const order = await prisma.order.findUnique({ where: { id: orderId } });
  if (!order || order.userId !== req.user.id) return res.status(404).json({ error: 'Commande introuvable.' });

  const user = await prisma.user.findUnique({ where: { id: req.user.id } });
  const request = await prisma.returnRequest.create({
    data: { orderId, userId: req.user.id, userName: user.name, reason, status: 'EN_ATTENTE' },
  });
  res.status(201).json({ request });
});

router.get('/mine', requireAuth, async (req, res) => {
  const requests = await prisma.returnRequest.findMany({ where: { userId: req.user.id }, orderBy: { createdAt: 'desc' } });
  res.json({ requests });
});

router.get('/order/:orderId', requireAuth, async (req, res) => {
  const request = await prisma.returnRequest.findFirst({ where: { orderId: req.params.orderId } });
  res.json({ request: request || null });
});

// ---- Réservé au staff ----

router.get('/', requireAuth, requireStaff, async (req, res) => {
  const requests = await prisma.returnRequest.findMany({ orderBy: { createdAt: 'desc' } });
  res.json({ requests });
});

router.patch('/:id', requireAuth, requireStaff, async (req, res) => {
  const { status, staffNote } = req.body;
  const request = await prisma.returnRequest.update({ where: { id: req.params.id }, data: { status, staffNote } });

  const labels = { APPROUVE: 'Votre demande de retour a été approuvée', REFUSE: 'Votre demande de retour a été refusée', REMBOURSE: 'Votre remboursement a été effectué' };
  if (labels[status]) {
    sendPushToUsers([request.userId], { title: 'Baymore', body: labels[status], data: { requestId: request.id, type: 'return_status' } });
  }

  res.json({ request });
});

module.exports = router;
