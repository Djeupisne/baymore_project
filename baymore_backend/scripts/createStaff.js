/**
 * Crée (ou met à jour) un compte staff pour accéder au back-office.
 * Usage : node scripts/createStaff.js "Nom" email@baymore.app motdepasse
 */
require('dotenv').config();
const bcrypt = require('bcryptjs');
const { PrismaClient } = require('@prisma/client');
const { v4: uuid } = require('uuid');

const prisma = new PrismaClient();

async function main() {
  const [name, email, password] = process.argv.slice(2);
  if (!name || !email || !password) {
    console.error('Usage : node scripts/createStaff.js "Nom" email@baymore.app motdepasse');
    process.exit(1);
  }

  const passwordHash = await bcrypt.hash(password, 10);
  const user = await prisma.user.upsert({
    where: { email },
    create: {
      name,
      email,
      passwordHash,
      role: 'STAFF',
      referralCode: uuid().replace(/-/g, '').substring(0, 6).toUpperCase(),
    },
    update: { role: 'STAFF', passwordHash, name },
  });

  console.log(` Compte staff prêt : ${user.email} (id: ${user.id})`);
  process.exit(0);
}

main().catch((e) => { console.error(e); process.exit(1); });