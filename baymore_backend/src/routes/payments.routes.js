const express = require('express');
const prisma = require('../lib/prisma');
const { requireAuth } = require('../middleware/auth');
const cinetpay = require('../services/cinetpay');
const { emitOrderUpdate } = require('../lib/socket');

const router = express.Router();

router.post('/initiate', requireAuth, async (req, res) => {
  const { orderId } = req.body;
  const order = await prisma.order.findUnique({ where: { id: orderId } });
  if (!order) return res.status(404).json({ error: 'Commande introuvable.' });
  if (order.userId !== req.user.id) return res.status(403).json({ error: 'Accès refusé.' });

  const user = await prisma.user.findUnique({ where: { id: req.user.id } });
  const transactionId = `BAYMORE-${orderId}-${Date.now()}`;

  try {
    const { paymentUrl } = await cinetpay.initiatePayment({
      transactionId,
      amount: order.total,
      description: `Commande Baymore #${orderId.substring(0, 6).toUpperCase()}`,
      customer: {
        firstName: user.name.split(' ')[0],
        lastName: user.name.split(' ').slice(1).join(' ') || 'Baymore',
        phone: user.phone,
        email: user.email,
        address: order.deliveryAddress,
      },
    });

    await prisma.order.update({ where: { id: orderId }, data: { paymentTransactionId: transactionId } });
    res.json({ paymentUrl, transactionId });
  } catch (e) {
    console.error('Erreur initiation paiement CinetPay', e.message);
    res.status(500).json({ error: "Impossible d'initier le paiement pour le moment." });
  }
});

/** Webhook CinetPay — revérifie toujours le statut réel avant de faire confiance. */
router.post('/webhook', async (req, res) => {
  const transactionId = req.body?.cpm_trans_id;
  if (!transactionId) return res.status(400).send('cpm_trans_id manquant');

  try {
    const status = await cinetpay.checkPaymentStatus(transactionId);
    const order = await prisma.order.findFirst({ where: { paymentTransactionId: transactionId } });
    if (!order) return res.status(404).send('Commande introuvable pour cette transaction');

    if (status === 'ACCEPTED') {
      const updated = await prisma.order.update({ where: { id: order.id }, data: { paymentStatus: 'PAYE' } });
      emitOrderUpdate(updated.id, updated);
    } else if (status === 'REFUSED') {
      const updated = await prisma.order.update({ where: { id: order.id }, data: { paymentStatus: 'ECHOUE' } });
      emitOrderUpdate(updated.id, updated);
    }
    res.status(200).send('OK');
  } catch (e) {
    console.error('Erreur vérification paiement CinetPay', e.message);
    res.status(500).send('Erreur de vérification');
  }
});

module.exports = router;
