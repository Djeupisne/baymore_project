const jwt = require('jsonwebtoken');
const env = require('../config/env');

function signAccessToken(user) {
  return jwt.sign({ uid: user.id, role: user.role }, env.jwtAccessSecret, { expiresIn: '2h' });
}

function signRefreshToken(user) {
  return jwt.sign({ uid: user.id }, env.jwtRefreshSecret, { expiresIn: '30d' });
}

function verifyAccessToken(token) {
  return jwt.verify(token, env.jwtAccessSecret);
}

function verifyRefreshToken(token) {
  return jwt.verify(token, env.jwtRefreshSecret);
}

module.exports = { signAccessToken, signRefreshToken, verifyAccessToken, verifyRefreshToken };
