const axios = require('axios');
const env = require('../config/env');

const INIT_URL = 'https://api-checkout.cinetpay.com/v2/payment';
const CHECK_URL = 'https://api-checkout.cinetpay.com/v2/payment/check';

/**
 * Initialise une transaction Mobile Money (Flooz / T-Money) et renvoie
 * l'URL de paiement hébergée par CinetPay. Le montant doit être un
 * multiple de 5 (contrainte de leur API).
 */
async function initiatePayment({ transactionId, amount, description, customer, returnPath = '/paiement-retour' }) {
  const roundedAmount = Math.ceil(amount / 5) * 5;
  const payload = {
    apikey: env.cinetpay.apiKey,
    site_id: env.cinetpay.siteId,
    transaction_id: transactionId,
    amount: roundedAmount,
    currency: 'XOF',
    description,
    notify_url: `${env.backendPublicUrl}/api/payments/webhook`,
    return_url: `${env.clientAppUrl}${returnPath}`,
    channels: 'MOBILE_MONEY',
    customer_name: customer.firstName,
    customer_surname: customer.lastName,
    customer_phone_number: customer.phone,
    customer_email: customer.email,
    customer_address: customer.address || 'Lomé',
    customer_city: 'Lomé',
    customer_country: 'TG',
    customer_state: 'TG',
    customer_zip_code: '00000',
  };

  const { data } = await axios.post(INIT_URL, payload, { headers: { 'Content-Type': 'application/json' } });
  if (data.code !== '201') {
    throw new Error(`CinetPay: ${data.description || data.message}`);
  }
  return { paymentUrl: data.data.payment_url, paymentToken: data.data.payment_token };
}

/**
 * IMPORTANT (sécurité) : CinetPay n'envoie jamais le statut réel dans le
 * webhook lui-même — on doit systématiquement rappeler cette API pour
 * obtenir le vrai statut avant de considérer une commande comme payée.
 */
async function checkPaymentStatus(transactionId) {
  const { data } = await axios.post(
    CHECK_URL,
    { transaction_id: transactionId, site_id: env.cinetpay.siteId, apikey: env.cinetpay.apiKey },
    { headers: { 'Content-Type': 'application/json' } }
  );
  return data?.data?.status; // 'ACCEPTED' | 'REFUSED' | 'WAITING_FOR_CUSTOMER'
}

module.exports = { initiatePayment, checkPaymentStatus };
