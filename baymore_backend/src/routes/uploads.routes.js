const express = require('express');
const multer = require('multer');
const { requireAuth, requireStaff } = require('../middleware/auth');
const { uploadImageBuffer } = require('../services/uploadthing');

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 8 * 1024 * 1024 } });

router.post('/image', requireAuth, requireStaff, upload.single('file'), async (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'Fichier manquant.' });
  try {
    const url = await uploadImageBuffer(req.file.buffer, req.file.originalname, req.file.mimetype);
    res.json({ url });
  } catch (e) {
    console.error('Erreur upload image', e.message);
    res.status(500).json({ error: "Impossible d'envoyer l'image pour le moment." });
  }
});

module.exports = router;
