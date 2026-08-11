const { verifyAccessToken } = require('../utils/jwt');
const prisma = require('../lib/prisma');

/** Exige un token valide (client OU staff). Attache req.user = {id, role}. */
async function requireAuth(req, res, next) {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Authentification requise.' });
  }
  try {
    const payload = verifyAccessToken(header.slice(7));
    req.user = { id: payload.uid, role: payload.role };
    next();
  } catch (e) {
    return res.status(401).json({ error: 'Session expirée, reconnectez-vous.' });
  }
}

/** Comme requireAuth, mais n'échoue pas si absent (req.user reste undefined). */
async function optionalAuth(req, res, next) {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) return next();
  try {
    const payload = verifyAccessToken(header.slice(7));
    req.user = { id: payload.uid, role: payload.role };
  } catch (e) {
    // token invalide : on continue simplement sans utilisateur authentifié
  }
  next();
}

/** À utiliser après requireAuth : exige le rôle STAFF. */
function requireStaff(req, res, next) {
  if (req.user?.role !== 'STAFF') {
    return res.status(403).json({ error: "Réservé à l'équipe Baymore." });
  }
  next();
}

module.exports = { requireAuth, optionalAuth, requireStaff, prisma };
