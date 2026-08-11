const { PrismaClient } = require('@prisma/client');

// Instance unique partagée par toute l'app (bonne pratique Prisma en
// environnement serverless/à connexions limitées comme Render).
const prisma = new PrismaClient();

module.exports = prisma;
