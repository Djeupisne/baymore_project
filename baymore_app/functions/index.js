/**
 * Cloud Functions Baymore
 * ------------------------
 * 1. onOrderStatusChange  -> notification push au client à chaque changement de statut
 * 2. initiatePayment      -> ouvre une transaction Mobile Money (Flooz / T-Money) via CinetPay
 * 3. cinetpayNotify       -> webhook CinetPay : confirme le paiement et notifie le client
 *
 * CinetPay est l'agrégateur utilisé pour Flooz (Moov Togo) et T-Money (Togocom) —
 * intégration conforme à la documentation officielle : https://docs.cinetpay.com
 */
const { onDocumentUpdated, onDocumentCreated, onDocumentDeleted } = require('firebase-functions/v2/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onRequest } = require('firebase-functions/v2/https');
const { defineString } = require('firebase-functions/params');
const { defineSecret } = require('firebase-functions/params');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

// Paramètres à définir au déploiement (voir README > Configuration Cloud Functions) :
//   firebase functions:secrets:set CINETPAY_APIKEY
//   firebase functions:secrets:set CINETPAY_SITE_ID
const CINETPAY_APIKEY = defineString('CINETPAY_APIKEY');
const CINETPAY_SITE_ID = defineString('CINETPAY_SITE_ID');
const APP_BASE_URL = defineString('APP_BASE_URL', { default: 'https://baymore.app' });

const CINETPAY_INIT_URL = 'https://api-checkout.cinetpay.com/v2/payment';
const CINETPAY_CHECK_URL = 'https://api-checkout.cinetpay.com/v2/payment/check';

const STATUS_LABELS = {
  en_attente: 'Commande reçue',
  pris_en_charge: 'Votre commande est prise en charge',
  en_route: 'Votre livreur est en route',
  livre: 'Votre commande a été livrée',
  annule: 'Votre commande a été annulée',
};

/* ----------------------------------------------------------------------- */
/* 1. Notification push à chaque changement de statut de commande          */
/* ----------------------------------------------------------------------- */
exports.onOrderStatusChange = onDocumentUpdated('orders/{orderId}', async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (before.status === after.status) return null;

  // Points fidélité : 1 point par tranche de 1000 F CFA dépensée, ET
  // cashback de 2% crédité au portefeuille — les deux automatiquement dès
  // que la commande passe à "livrée".
  if (after.status === 'livre') {
    const points = Math.floor((after.total || 0) / 1000);
    const cashback = Math.round((after.total || 0) * 0.02);
    if (points > 0 || cashback > 0) {
      await db.collection('users').doc(after.userId).set(
        {
          loyaltyPoints: admin.firestore.FieldValue.increment(points),
          walletBalance: admin.firestore.FieldValue.increment(cashback),
        },
        { merge: true }
      );
    }
    if (cashback > 0) {
      await db.collection('users').doc(after.userId).collection('walletTransactions').add({
        amount: cashback,
        reason: `Cashback commande #${event.params.orderId.substring(0, 6).toUpperCase()}`,
        createdAt: admin.firestore.Timestamp.now(),
      });
    }
  }

  const userSnap = await db.collection('users').doc(after.userId).get();
  const fcmToken = userSnap.data()?.fcmToken;
  if (!fcmToken) return null;

  const title = 'Baymore';
  const body = STATUS_LABELS[after.status] || 'Mise à jour de votre commande';

  try {
    await messaging.send({
      token: fcmToken,
      notification: { title, body },
      data: { orderId: event.params.orderId, status: after.status, type: 'order_status' },
      android: { priority: 'high' },
      apns: { payload: { aps: { sound: 'default' } } },
    });
  } catch (err) {
    console.error('Échec envoi notification', err);
  }
  return null;
});

/* ----------------------------------------------------------------------- */
/* 2. Initialisation d'un paiement Mobile Money (Flooz / T-Money)          */
/* ----------------------------------------------------------------------- */
exports.initiatePayment = onCall({ secrets: [CINETPAY_APIKEY, CINETPAY_SITE_ID] }, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Connexion requise pour payer.');
  }
  const { orderId } = request.data;
  if (!orderId) throw new HttpsError('invalid-argument', 'orderId manquant.');

  const orderRef = db.collection('orders').doc(orderId);
  const orderSnap = await orderRef.get();
  if (!orderSnap.exists) throw new HttpsError('not-found', 'Commande introuvable.');
  const order = orderSnap.data();

  if (order.userId !== request.auth.uid) {
    throw new HttpsError('permission-denied', "Cette commande ne vous appartient pas.");
  }
  if (order.total < 100) {
    throw new HttpsError('failed-precondition', 'Montant de commande invalide.');
  }

  const userSnap = await db.collection('users').doc(order.userId).get();
  const user = userSnap.data() || {};

  // Le montant CinetPay doit être un multiple de 5 (contrainte de leur API).
  const amount = Math.ceil(order.total / 5) * 5;
  const transactionId = `BAYMORE-${orderId}-${Date.now()}`;

  const payload = {
    apikey: CINETPAY_APIKEY.value(),
    site_id: CINETPAY_SITE_ID.value(),
    transaction_id: transactionId,
    amount,
    currency: 'XOF',
    description: `Commande Baymore #${orderId.substring(0, 6).toUpperCase()}`,
    notify_url: `https://${process.env.GCLOUD_PROJECT}.cloudfunctions.net/cinetpayNotify`,
    return_url: `${APP_BASE_URL.value()}/paiement-retour`,
    channels: 'MOBILE_MONEY',
    metadata: orderId,
    customer_name: (user.name || 'Client').split(' ')[0],
    customer_surname: (user.name || 'Baymore').split(' ').slice(1).join(' ') || 'Baymore',
    customer_phone_number: user.phone || '',
    customer_email: user.email || 'client@baymore.app',
    customer_address: order.deliveryAddress || 'Lomé',
    customer_city: 'Lomé',
    customer_country: 'TG',
    customer_state: 'TG',
    customer_zip_code: '00000',
  };

  try {
    const { data } = await axios.post(CINETPAY_INIT_URL, payload, {
      headers: { 'Content-Type': 'application/json' },
    });
    if (data.code !== '201') {
      throw new HttpsError('internal', `CinetPay: ${data.description || data.message}`);
    }
    await orderRef.update({
      paymentStatus: 'en_attente',
      paymentProvider: 'cinetpay',
      paymentTransactionId: transactionId,
      paymentToken: data.data.payment_token,
    });
    return { paymentUrl: data.data.payment_url, transactionId };
  } catch (err) {
    console.error('Erreur initiation paiement CinetPay', err?.response?.data || err.message);
    throw new HttpsError('internal', "Impossible d'initier le paiement pour le moment.");
  }
});

/* ----------------------------------------------------------------------- */
/* 3. Webhook CinetPay : confirmation officielle du paiement               */
/* ----------------------------------------------------------------------- */
// IMPORTANT (sécurité) : CinetPay n'envoie JAMAIS le statut réel dans le
// webhook lui-même (pour éviter les attaques "man in the middle"). On doit
// systématiquement rappeler l'API de vérification pour obtenir le vrai statut.
exports.cinetpayNotify = onRequest({ secrets: [CINETPAY_APIKEY, CINETPAY_SITE_ID] }, async (req, res) => {
  const transactionId = req.body?.cpm_trans_id;
  if (!transactionId) {
    res.status(400).send('cpm_trans_id manquant');
    return;
  }

  try {
    const { data } = await axios.post(
      CINETPAY_CHECK_URL,
      {
        transaction_id: transactionId,
        site_id: CINETPAY_SITE_ID.value(),
        apikey: CINETPAY_APIKEY.value(),
      },
      { headers: { 'Content-Type': 'application/json' } }
    );

    const ordersQuery = await db
      .collection('orders')
      .where('paymentTransactionId', '==', transactionId)
      .limit(1)
      .get();

    if (ordersQuery.empty) {
      res.status(404).send('Commande introuvable pour cette transaction');
      return;
    }

    const orderDoc = ordersQuery.docs[0];
    const status = data?.data?.status; // 'ACCEPTED' | 'REFUSED' | 'WAITING_FOR_CUSTOMER'

    if (status === 'ACCEPTED') {
      await orderDoc.ref.update({ paymentStatus: 'paye' });
    } else if (status === 'REFUSED') {
      await orderDoc.ref.update({ paymentStatus: 'echoue' });
    }
    // Si WAITING_FOR_CUSTOMER : on ne change rien, CinetPay rappellera ce
    // webhook à la prochaine mise à jour de statut.

    res.status(200).send('OK');
  } catch (err) {
    console.error('Erreur vérification paiement CinetPay', err?.response?.data || err.message);
    res.status(500).send('Erreur de vérification');
  }
});

/* ----------------------------------------------------------------------- */
/* 4. Recalcul de la note moyenne d'un produit à chaque nouvel avis        */
/* ----------------------------------------------------------------------- */
exports.onReviewCreate = onDocumentCreated('reviews/{reviewId}', async (event) => {
  const review = event.data.data();
  const productId = review.productId;
  if (!productId) return null;

  const reviewsSnap = await db.collection('reviews').where('productId', '==', productId).get();
  const ratings = reviewsSnap.docs.map((d) => d.data().rating || 0);
  const count = ratings.length;
  const average = count > 0 ? ratings.reduce((a, b) => a + b, 0) / count : 0;

  await db.collection('products').doc(productId).update({
    rating: Math.round(average * 10) / 10,
    ratingCount: count,
  });
  return null;
});

/* ----------------------------------------------------------------------- */
/* 5. Validation d'un code promo (calcul de remise fait uniquement côté    */
/*    serveur pour éviter toute manipulation du montant côté client)       */
/* ----------------------------------------------------------------------- */
exports.validatePromoCode = onCall(async (request) => {
  const { code, subtotal } = request.data;
  if (!code || typeof subtotal !== 'number') {
    throw new HttpsError('invalid-argument', 'Code ou montant manquant.');
  }

  const promoRef = db.collection('promoCodes').doc(code.trim().toUpperCase());
  const promoSnap = await promoRef.get();
  if (!promoSnap.exists) {
    return { valid: false, discount: 0, message: 'Ce code promo n\'existe pas.' };
  }
  const promo = promoSnap.data();

  if (promo.active === false) {
    return { valid: false, discount: 0, message: 'Ce code promo n\'est plus actif.' };
  }
  if (promo.expiresAt && promo.expiresAt.toDate() < new Date()) {
    return { valid: false, discount: 0, message: 'Ce code promo a expiré.' };
  }
  if (promo.minOrder && subtotal < promo.minOrder) {
    return { valid: false, discount: 0, message: `Montant minimum requis : ${promo.minOrder} F CFA.` };
  }

  let discount = 0;
  if (promo.type === 'percent') {
    discount = (subtotal * promo.value) / 100;
    if (promo.maxDiscount) discount = Math.min(discount, promo.maxDiscount);
  } else if (promo.type === 'fixed') {
    discount = promo.value;
  }
  discount = Math.min(discount, subtotal);

  return {
    valid: true,
    discount,
    message: promo.type === 'percent' ? `-${promo.value}% appliqué` : `-${promo.value} F CFA appliqué`,
  };
});

/* ----------------------------------------------------------------------- */
/* 6. Programme de parrainage : crédite le parrain ET le filleul           */
/* ----------------------------------------------------------------------- */
const REFERRAL_BONUS_POINTS = 50;

exports.applyReferralCode = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Connexion requise.');
  const { code } = request.data;
  if (!code) throw new HttpsError('invalid-argument', 'Code manquant.');

  const newUserId = request.auth.uid;
  const referrerQuery = await db
    .collection('users')
    .where('referralCode', '==', code.trim().toUpperCase())
    .limit(1)
    .get();

  if (referrerQuery.empty) {
    return { applied: false, message: 'Code de parrainage introuvable.' };
  }
  const referrerDoc = referrerQuery.docs[0];
  if (referrerDoc.id === newUserId) {
    return { applied: false, message: 'Vous ne pouvez pas utiliser votre propre code.' };
  }

  const newUserRef = db.collection('users').doc(newUserId);
  const newUserSnap = await newUserRef.get();
  if (newUserSnap.data()?.referredBy) {
    return { applied: false, message: 'Un code de parrainage a déjà été utilisé sur ce compte.' };
  }

  await newUserRef.set(
    {
      referredBy: referrerDoc.id,
      loyaltyPoints: admin.firestore.FieldValue.increment(REFERRAL_BONUS_POINTS),
    },
    { merge: true }
  );
  await referrerDoc.ref.set(
    { loyaltyPoints: admin.firestore.FieldValue.increment(REFERRAL_BONUS_POINTS) },
    { merge: true }
  );

  return { applied: true, message: `+${REFERRAL_BONUS_POINTS} points crédités !` };
});

/* ----------------------------------------------------------------------- */
/* 7. Alerte de retour en stock                                            */
/* ----------------------------------------------------------------------- */
exports.onProductRestocked = onDocumentUpdated('products/{productId}', async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  const wasOut = (before.stock || 0) <= 0;
  const isNowIn = (after.stock || 0) > 0;
  if (!(wasOut && isNowIn)) return null;

  const alertsSnap = await db.collection('stockAlerts').where('productId', '==', event.params.productId).get();
  if (alertsSnap.empty) return null;

  for (const alertDoc of alertsSnap.docs) {
    const userId = alertDoc.data().userId;
    const userSnap = await db.collection('users').doc(userId).get();
    const fcmToken = userSnap.data()?.fcmToken;
    if (fcmToken) {
      try {
        await messaging.send({
          token: fcmToken,
          notification: {
            title: 'Baymore',
            body: `"${after.name}" est de nouveau disponible !`,
          },
          data: { productId: event.params.productId, type: 'restock' },
        });
      } catch (err) {
        console.error('Échec notification retour en stock', err);
      }
    }
    await alertDoc.ref.delete();
  }
  return null;
});

/* ----------------------------------------------------------------------- */
/* 8. Notification au staff dès qu'une nouvelle commande arrive            */
/* ----------------------------------------------------------------------- */
exports.onOrderCreated = onDocumentCreated('orders/{orderId}', async (event) => {
  const order = event.data.data();
  const staffSnap = await db.collection('staff').get();
  const tokens = staffSnap.docs.map((d) => d.data().fcmToken).filter(Boolean);
  if (tokens.length === 0) return null;

  const body = `Nouvelle commande #${event.params.orderId.substring(0, 6).toUpperCase()} — ${order.total} F CFA`;
  await Promise.all(tokens.map((token) =>
    messaging.send({
      token,
      notification: { title: 'Baymore — Nouvelle commande', body },
      data: { orderId: event.params.orderId, type: 'new_order' },
      android: { priority: 'high' },
    }).catch((err) => console.error('Échec notification staff', err))
  ));
  return null;
});

/* ----------------------------------------------------------------------- */
/* 9. Notification au client sur mise à jour de sa demande de retour       */
/* ----------------------------------------------------------------------- */
const RETURN_STATUS_LABELS = {
  approuve: 'Votre demande de retour a été approuvée',
  refuse: 'Votre demande de retour a été refusée',
  rembourse: 'Votre remboursement a été effectué',
};

exports.onReturnRequestUpdated = onDocumentUpdated('returnRequests/{requestId}', async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (before.status === after.status) return null;

  const label = RETURN_STATUS_LABELS[after.status];
  if (!label) return null;

  const userSnap = await db.collection('users').doc(after.userId).get();
  const fcmToken = userSnap.data()?.fcmToken;
  if (!fcmToken) return null;

  try {
    await messaging.send({
      token: fcmToken,
      notification: { title: 'Baymore', body: label },
      data: { type: 'return_status', requestId: event.params.requestId },
    });
  } catch (err) {
    console.error('Échec notification retour', err);
  }
  return null;
});

/* ----------------------------------------------------------------------- */
/* 10. Recalcul de la note produit après suppression d'un avis (modération)*/
/* ----------------------------------------------------------------------- */
exports.onReviewDelete = onDocumentDeleted('reviews/{reviewId}', async (event) => {
  const review = event.data.data();
  const productId = review.productId;
  if (!productId) return null;

  const reviewsSnap = await db.collection('reviews').where('productId', '==', productId).get();
  const ratings = reviewsSnap.docs.map((d) => d.data().rating || 0);
  const count = ratings.length;
  const average = count > 0 ? ratings.reduce((a, b) => a + b, 0) / count : 0;

  await db.collection('products').doc(productId).update({
    rating: Math.round(average * 10) / 10,
    ratingCount: count,
  });
  return null;
});

/* ----------------------------------------------------------------------- */
/* 11. Suppression de compte (obligatoire pour la conformité Play Store)   */
/* ----------------------------------------------------------------------- */
exports.deleteAccount = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Connexion requise.');
  const uid = request.auth.uid;

  const addressesSnap = await db.collection('users').doc(uid).collection('addresses').get();
  await Promise.all(addressesSnap.docs.map((d) => d.ref.delete()));

  const alertsSnap = await db.collection('stockAlerts').where('userId', '==', uid).get();
  await Promise.all(alertsSnap.docs.map((d) => d.ref.delete()));

  await db.collection('users').doc(uid).delete();
  await admin.auth().deleteUser(uid);

  return { deleted: true };
});

/* ----------------------------------------------------------------------- */
/* 12. Liste des codes promo actifs, sans exposer les détails sensibles    */
/*     (utilisée par l'écran client "Bons de réduction")                   */
/* ----------------------------------------------------------------------- */
exports.listActivePromoCodes = onCall(async () => {
  const snap = await db.collection('promoCodes').where('active', '==', true).get();
  const now = new Date();
  const codes = snap.docs
    .map((d) => ({ code: d.id, ...d.data() }))
    .filter((c) => !c.expiresAt || c.expiresAt.toDate() > now)
    .map((c) => ({
      code: c.code,
      type: c.type,
      value: c.value,
      minOrder: c.minOrder || null,
      description: c.description || '',
    }));
  return { codes };
});

/* ----------------------------------------------------------------------- */
/* 13. Hébergement des images (produits, etc.) via UploadThing             */
/* ----------------------------------------------------------------------- */
// UploadThing ne propose pas de SDK Flutter/Dart officiel — seulement un
// SDK JavaScript. Le contournement standard (et celui recommandé par leur
// équipe pour les environnements non-JS) est de passer par un petit
// serveur : le back-office envoie l'image en base64 à cette Cloud
// Function, qui la transmet à UploadThing via leur SDK Node officiel et
// renvoie l'URL publique du fichier hébergé.
const UPLOADTHING_TOKEN = defineSecret('UPLOADTHING_TOKEN');
const MAX_IMAGE_BYTES = 8 * 1024 * 1024; // 8 Mo — garde-fou avant l'envoi

exports.uploadImage = onCall({ secrets: [UPLOADTHING_TOKEN] }, async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Connexion requise.');

  const staffDoc = await db.collection('staff').doc(request.auth.uid).get();
  if (!staffDoc.exists) {
    throw new HttpsError('permission-denied', 'Réservé à l\'équipe Baymore.');
  }

  const { base64, fileName, mimeType } = request.data;
  if (!base64 || !fileName) {
    throw new HttpsError('invalid-argument', 'Fichier manquant.');
  }

  const buffer = Buffer.from(base64, 'base64');
  if (buffer.length > MAX_IMAGE_BYTES) {
    throw new HttpsError('invalid-argument', 'Image trop volumineuse (8 Mo maximum).');
  }

  try {
    const { UTApi, UTFile } = require('uploadthing/server');
    const utapi = new UTApi({ token: UPLOADTHING_TOKEN.value() });
    const file = new UTFile([buffer], fileName, { type: mimeType || 'image/jpeg' });
    const response = await utapi.uploadFiles(file);

    if (response.error) {
      throw new HttpsError('internal', response.error.message || 'Échec de l\'envoi vers UploadThing.');
    }
    return { url: response.data.url };
  } catch (err) {
    console.error('Erreur upload UploadThing', err);
    throw new HttpsError('internal', "Impossible d'envoyer l'image pour le moment.");
  }
});
