require('dotenv').config();
const bcrypt = require('bcryptjs');
const db = require('../config/db');

async function runSeed() {
  try {
    console.log('Seeding users...');
    const hashedAdminPassword = await bcrypt.hash('password123', 10);
    const hashedUserPassword = await bcrypt.hash('password123', 10);

    await db.query(`
      INSERT INTO users (nama_lengkap, email, password_hash, no_hp, poin_nada, role) VALUES 
      ('Admin SENada', 'admin@senada.com', ?, '081234567890', 0, 'admin'),
      ('Dimitri Athallah', 'thedimitris@email.com', ?, '081234567891', 560, 'user')
      ON DUPLICATE KEY UPDATE email=email;
    `, [hashedAdminPassword, hashedUserPassword]);

    console.log('Seed users success!');
    process.exit(0);
  } catch (error) {
    console.error('Seed failed:', error);
    process.exit(1);
  }
}

runSeed();
