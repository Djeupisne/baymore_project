const { v4: uuid } = require('uuid');

/** Code de parrainage court et lisible, ex. "F3A9C2". */
function generateReferralCode() {
  return uuid().replace(/-/g, '').substring(0, 6).toUpperCase();
}

module.exports = { generateReferralCode };
