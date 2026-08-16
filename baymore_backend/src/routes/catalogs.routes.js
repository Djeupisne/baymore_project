const express = require('express');
const prisma = require('../lib/prisma');
const { requireAuth, requireStaff } = require('../middleware/auth');
const { sendPushToUsers } = require('../services/onesignal');
const { emitCatalogNotification } = require('../lib/socket');

const router = express.Router();

// Récupérer tous les catalogues
router.get('/', async (req, res) => {
  const { active } = req.query;
  const where = {};
  if (active !== undefined) {
    where.isActive = active === 'true';
  }
  
  const catalogs = await prisma.catalog.findMany({ 
    where,
    orderBy: { createdAt: 'desc' }
  });
  
  res.json({ catalogs });
});

// Récupérer un catalogue par ID
router.get('/:id', async (req, res) => {
  const catalog = await prisma.catalog.findUnique({ 
    where: { id: req.params.id }
  });
  if (!catalog) return res.status(404).json({ error: 'Catalogue introuvable.' });
  res.json({ catalog });
});

// Créer un nouveau catalogue
router.post('/', requireAuth, requireStaff, async (req, res) => {
  const { name, description, image, productIds, isActive, startsAt, endsAt } = req.body;
  
  if (!name) {
    return res.status(400).json({ error: 'Le nom du catalogue est obligatoire.' });
  }
  
  const catalog = await prisma.catalog.create({
    data: {
      name,
      description: description || '',
      image: image || null,
      productIds: productIds || [],
      isActive: isActive ?? true,
      startsAt: startsAt ? new Date(startsAt) : null,
      endsAt: endsAt ? new Date(endsAt) : null,
    },
  });
  
  res.status(201).json({ catalog });
});

// Modifier un catalogue
router.put('/:id', requireAuth, requireStaff, async (req, res) => {
  const { name, description, image, productIds, isActive, startsAt, endsAt } = req.body;
  
  const before = await prisma.catalog.findUnique({ where: { id: req.params.id } });
  if (!before) return res.status(404).json({ error: 'Catalogue introuvable.' });
  
  const updateData = {};
  if (name !== undefined) updateData.name = name;
  if (description !== undefined) updateData.description = description;
  if (image !== undefined) updateData.image = image;
  if (productIds !== undefined) updateData.productIds = productIds;
  if (isActive !== undefined) updateData.isActive = isActive;
  if (startsAt !== undefined) updateData.startsAt = startsAt ? new Date(startsAt) : null;
  if (endsAt !== undefined) updateData.endsAt = endsAt ? new Date(endsAt) : null;
  
  const catalog = await prisma.catalog.update({
    where: { id: req.params.id },
    data: updateData,
  });
  
  // Si le catalogue vient d'être activé, envoyer une notification
  if (!before.isActive && isActive) {
    const allCustomers = await prisma.user.findMany({ where: { role: 'CUSTOMER' }, select: { id: true } });
    if (allCustomers.length > 0) {
      await sendPushToUsers(allCustomers.map((c) => c.id), {
        title: 'Baymore — Nouveau Catalogue',
        body: `Découvrez "${name}", notre nouvelle collection !`,
        data: { type: 'catalog', catalogId: catalog.id },
      });
      
      emitCatalogNotification({
        title: 'Baymore — Nouveau Catalogue',
        body: `Découvrez "${name}", notre nouvelle collection !`,
        catalogId: catalog.id,
      });
      
      for (const customer of allCustomers) {
        await prisma.notification.create({
          data: {
            userId: customer.id,
            title: 'Baymore — Nouveau Catalogue',
            body: `Découvrez "${name}", notre nouvelle collection !`,
            type: 'CATALOG',
            data: { catalogId: catalog.id },
          },
        });
      }
    }
  }
  
  res.json({ catalog });
});

// Supprimer un catalogue
router.delete('/:id', requireAuth, requireStaff, async (req, res) => {
  const catalog = await prisma.catalog.findUnique({ where: { id: req.params.id } });
  if (!catalog) return res.status(404).json({ error: 'Catalogue introuvable.' });
  
  await prisma.catalog.delete({ where: { id: req.params.id } });
  res.json({ deleted: true });
});

module.exports = router;
