require('dotenv').config();
const db = require('../config/db');

async function migrate() {
  try {
    console.log('Running promo migration...');

    // 1. Check promos columns
    const [promoCols] = await db.query(
      `SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'promos'`,
      [process.env.DB_NAME]
    );
    const existingPromoCols = promoCols.map(c => c.COLUMN_NAME);

    if (!existingPromoCols.includes('nama_acara')) {
      await db.query(`ALTER TABLE promos ADD COLUMN nama_acara VARCHAR(255) NULL`);
      console.log('Added nama_acara to promos');
    }
    if (!existingPromoCols.includes('tanggal_mulai')) {
      await db.query(`ALTER TABLE promos ADD COLUMN tanggal_mulai DATE NULL`);
      console.log('Added tanggal_mulai to promos');
    }
    if (!existingPromoCols.includes('tanggal_berakhir')) {
      await db.query(`ALTER TABLE promos ADD COLUMN tanggal_berakhir DATE NULL`);
      console.log('Added tanggal_berakhir to promos');
    }

    // 2. Check bookings columns
    const [bookingCols] = await db.query(
      `SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'bookings'`,
      [process.env.DB_NAME]
    );
    const existingBookingCols = bookingCols.map(c => c.COLUMN_NAME);

    if (!existingBookingCols.includes('promo_kode')) {
      await db.query(`ALTER TABLE bookings ADD COLUMN promo_kode VARCHAR(50) NULL`);
      console.log('Added promo_kode to bookings');
    }
    if (!existingBookingCols.includes('diskon_nominal')) {
      await db.query(`ALTER TABLE bookings ADD COLUMN diskon_nominal DECIMAL(10,2) DEFAULT 0`);
      console.log('Added diskon_nominal to bookings');
    }

    // 3. Add sample Natalan promo if not exists
    const [existingPromo] = await db.query(`SELECT * FROM promos WHERE kode = 'NATAL2026'`);
    if (existingPromo.length === 0) {
      await db.query(`
        INSERT INTO promos (kode, nama_acara, diskon_persen, tanggal_mulai, tanggal_berakhir, aktif)
        VALUES ('NATAL2026', 'Diskon Spesial Natal & Akhir Tahun', 25, '2026-12-01', '2026-12-31', TRUE)
      `);
      console.log('Inserted sample NATAL2026 promo');
    }

    console.log('Migration completed successfully!');
    process.exit(0);
  } catch (err) {
    console.error('Migration failed:', err);
    process.exit(1);
  }
}

migrate();
