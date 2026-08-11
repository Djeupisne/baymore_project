const { UTApi, UTFile } = require('uploadthing/server');
const env = require('../config/env');

const utapi = new UTApi({ token: env.uploadthingToken });

/** Envoie un buffer d'image vers UploadThing et renvoie son URL publique. */
async function uploadImageBuffer(buffer, fileName, mimeType) {
  const file = new UTFile([buffer], fileName, { type: mimeType || 'image/jpeg' });
  const response = await utapi.uploadFiles(file);
  if (response.error) {
    throw new Error(response.error.message || "Échec de l'envoi vers UploadThing.");
  }
  return response.data.url;
}

module.exports = { uploadImageBuffer };
