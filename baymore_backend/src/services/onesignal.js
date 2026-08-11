const axios = require('axios');
const env = require('../config/env');

const API_URL = 'https://api.onesignal.com/notifications';

/**
 * Envoie une notification push à un ou plusieurs utilisateurs, identifiés
 * par leur "External ID" OneSignal (voir OneSignal.login(uid) côté Flutter
 * — on utilise l'id Baymore de l'utilisateur comme External ID, donc pas
 * de champ supplémentaire à stocker côté serveur).
 *
 * Si l'envoi échoue (clé manquante, mauvaise config...), on logue
 * simplement l'erreur sans jamais faire échouer l'action métier associée
 * (faire avancer une commande ne doit pas planter si la notif échoue).
 */
async function sendPushToUsers(externalIds, { title, body, data = {} }) {
  if (!env.onesignal.appId || !env.onesignal.apiKey) {
    console.warn('OneSignal non configuré (ONESIGNAL_APP_ID / ONESIGNAL_API_KEY manquants) — notification ignorée.');
    return;
  }
  const ids = Array.isArray(externalIds) ? externalIds : [externalIds];
  if (ids.length === 0) return;

  try {
    await axios.post(
      API_URL,
      {
        app_id: env.onesignal.appId,
        target_channel: 'push',
        include_aliases: { external_id: ids },
        headings: { en: title },
        contents: { en: body },
        data,
      },
      {
        headers: {
          Authorization: `Key ${env.onesignal.apiKey}`,
          'Content-Type': 'application/json',
        },
      }
    );
  } catch (err) {
    console.error('Échec envoi notification OneSignal', err?.response?.data || err.message);
  }
}

module.exports = { sendPushToUsers };
