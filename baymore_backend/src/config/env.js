require('dotenv').config();

function required(name) {
  const value = process.env[name];
  if (!value && process.env.NODE_ENV === 'production') {
    console.warn(`⚠️  Variable d'environnement manquante : ${name}`);
  }
  return value;
}

module.exports = {
  port: process.env.PORT || 4000,
  nodeEnv: process.env.NODE_ENV || 'development',
  clientAppUrl: process.env.CLIENT_APP_URL || '*',
  jwtAccessSecret: required('JWT_ACCESS_SECRET'),
  jwtRefreshSecret: required('JWT_REFRESH_SECRET'),
  cinetpay: {
    apiKey: process.env.CINETPAY_APIKEY,
    siteId: process.env.CINETPAY_SITE_ID,
  },
  backendPublicUrl: process.env.BACKEND_PUBLIC_URL || 'http://localhost:4000',
  uploadthingToken: process.env.UPLOADTHING_TOKEN,
  onesignal: {
    appId: process.env.ONESIGNAL_APP_ID,
    apiKey: process.env.ONESIGNAL_API_KEY,
  },
};
