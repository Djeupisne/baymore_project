const express = require('express');
const prisma = require('../lib/prisma');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();
router.use(requireAuth);

// Convertir les points de fidélité en argent (1 point = 1 FCFA)
router.post('/convert', async (req, res) => {
  try {
    const { points } = req.body;
    const userId = req.user.id;

    if (!points || points <= 0) {
      return res.status(400).json({ error: 'Nombre de points invalide' });
    }

    // Vérifier les points actuels de l'utilisateur
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { loyaltyPoints: true, walletBalance: true }
    });

    if (!user) {
      return res.status(404).json({ error: 'Utilisateur non trouvé' });
    }

    if (user.loyaltyPoints < points) {
      return res.status(400).json({ 
        error: `Solde de points insuffisant. Vous avez ${user.loyaltyPoints} points.` 
      });
    }

    // Conversion: 1 point = 1 FCFA
    const amountToAdd = points;

    // Mettre à jour les points et le portefeuille
    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: {
        loyaltyPoints: user.loyaltyPoints - points,
        walletBalance: user.walletBalance + amountToAdd
      },
      select: {
        id: true,
        loyaltyPoints: true,
        walletBalance: true
      }
    });

    // Créer un historique de transaction
    await prisma.walletTransaction.create({
      data: {
        userId: userId,
        amount: amountToAdd,
        type: 'CREDIT',
        description: `Conversion de ${points} points de fidélité en FCFA`
      }
    });

    res.json({
      message: `${points} points convertis avec succès en ${amountToAdd} FCFA`,
      user: updatedUser
    });

  } catch (error) {
    console.error('Erreur conversion fidélité:', error);
    res.status(500).json({ error: 'Échec de la conversion' });
  }
});

// Récupérer le solde de points de l'utilisateur
router.get('/balance', async (req, res) => {
  try {
    const userId = req.user.id;

    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { 
        id: true,
        loyaltyPoints: true,
        walletBalance: true 
      }
    });

    if (!user) {
      return res.status(404).json({ error: 'Utilisateur non trouvé' });
    }

    res.json({
      loyaltyPoints: user.loyaltyPoints,
      walletBalance: user.walletBalance,
      conversionRate: '1 point = 1 FCFA'
    });

  } catch (error) {
    console.error('Erreur récupération solde fidélité:', error);
    res.status(500).json({ error: 'Échec de la récupération du solde' });
  }
});

module.exports = router;
