const express = require('express');
const bcrypt = require('bcryptjs');
const prisma = require('../lib/prisma');
const { signAccessToken, signRefreshToken, verifyRefreshToken } = require('../utils/jwt');
const { generateReferralCode } = require('../utils/referral');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();
const REFERRAL_BONUS_POINTS = 50;

function publicUser(user) {
  const { passwordHash, ...rest } = user;
  return rest;
}

router.post('/register', async (req, res) => {
  const { name, email, phone, password, referralCode } = req.body;
  if (!name || !email || !password || password.length < 6) {
    return res.status(400).json({ error: 'Nom, e-mail et mot de passe (6 caractères min.) requis.' });
  }

  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) return res.status(409).json({ error: 'Un compte existe déjà avec cet e-mail.' });

  const passwordHash = await bcrypt.hash(password, 10);
  let referredBy = null;
  let referrer = null;

  if (referralCode) {
    referrer = await prisma.user.findUnique({ where: { referralCode: referralCode.trim().toUpperCase() } });
    if (referrer) referredBy = referrer.id;
  }

  const user = await prisma.user.create({
    data: {
      name,
      email,
      phone: phone || '',
      passwordHash,
      referralCode: generateReferralCode(),
      referredBy,
      loyaltyPoints: referrer ? REFERRAL_BONUS_POINTS : 0,
    },
  });

  if (referrer) {
    await prisma.user.update({
      where: { id: referrer.id },
      data: { loyaltyPoints: { increment: REFERRAL_BONUS_POINTS } },
    });
  }

  const accessToken = signAccessToken(user);
  const refreshToken = signRefreshToken(user);
  res.status(201).json({ user: publicUser(user), accessToken, refreshToken });
});

router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  const user = await prisma.user.findUnique({ where: { email } });
  if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
    return res.status(401).json({ error: 'E-mail ou mot de passe incorrect.' });
  }
  const accessToken = signAccessToken(user);
  const refreshToken = signRefreshToken(user);
  res.json({ user: publicUser(user), accessToken, refreshToken });
});

/** Connexion réservée au back-office : refuse tout compte non STAFF. */
router.post('/staff/login', async (req, res) => {
  const { email, password } = req.body;
  const user = await prisma.user.findUnique({ where: { email } });
  if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
    return res.status(401).json({ error: 'E-mail ou mot de passe incorrect.' });
  }
  if (user.role !== 'STAFF') {
    return res.status(403).json({ error: "Ce compte n'est pas autorisé sur le back-office." });
  }
  const accessToken = signAccessToken(user);
  const refreshToken = signRefreshToken(user);
  res.json({ user: publicUser(user), accessToken, refreshToken });
});

router.post('/refresh', async (req, res) => {
  const { refreshToken } = req.body;
  if (!refreshToken) return res.status(400).json({ error: 'Token manquant.' });
  try {
    const payload = verifyRefreshToken(refreshToken);
    const user = await prisma.user.findUnique({ where: { id: payload.uid } });
    if (!user) return res.status(401).json({ error: 'Compte introuvable.' });
    res.json({ accessToken: signAccessToken(user) });
  } catch (e) {
    res.status(401).json({ error: 'Session expirée, reconnectez-vous.' });
  }
});

router.get('/me', requireAuth, async (req, res) => {
  const user = await prisma.user.findUnique({ where: { id: req.user.id } });
  if (!user) return res.status(404).json({ error: 'Compte introuvable.' });
  res.json({ user: publicUser(user) });
});

router.patch('/me', requireAuth, async (req, res) => {
  const { name, phone } = req.body;
  const data = {};
  if (name !== undefined) data.name = name;
  if (phone !== undefined) data.phone = phone;
  const user = await prisma.user.update({ where: { id: req.user.id }, data });
  res.json({ user: publicUser(user) });
});

/** Suppression de compte — obligatoire pour la conformité Play Store. */
router.delete('/me', requireAuth, async (req, res) => {
  await prisma.user.delete({ where: { id: req.user.id } });
  res.json({ deleted: true });
});

module.exports = router;
