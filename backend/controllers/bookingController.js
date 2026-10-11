const db = require('../config/db');

exports.createBooking = async (req, res) => {
  const connection = await db.getConnection();
  await connection.beginTransaction();

  try {
    const { studio_id, tanggal_booking, jam_mulai, durasi, metode_pembayaran, promo_kode } = req.body;
    const user_id = req.user.id; // from JWT

    if (!studio_id || !tanggal_booking || !jam_mulai || !durasi || !metode_pembayaran) {
      await connection.rollback();
      return res.status(400).json({ success: false, message: 'Data tidak lengkap', data: null });
    }

    const jamMulaiInt = parseInt(jam_mulai.split(':')[0]);
    const jamSelesaiInt = jamMulaiInt + durasi;
    const jam_selesai = `${jamSelesaiInt.toString().padStart(2, '0')}:00:00`;

    // 1. Cek harga studio
    const [studios] = await connection.query('SELECT harga_per_jam FROM studios WHERE id = ?', [studio_id]);
    if (studios.length === 0) {
      await connection.rollback();
      return res.status(404).json({ success: false, message: 'Studio tidak ditemukan', data: null });
    }
    const harga_per_jam = parseFloat(studios[0].harga_per_jam);

    // 2. Cek ketersediaan slot dengan SELECT ... FOR UPDATE untuk mencegah double booking
    const slotTimes = [];
    for (let i = 0; i < durasi; i++) {
      slotTimes.push(`${(jamMulaiInt + i).toString().padStart(2, '0')}:00:00`);
    }

    // Prepare placeholders for IN clause
    const placeholders = slotTimes.map(() => '?').join(',');
    const query = `
      SELECT id, jam_mulai, status 
      FROM schedules 
      WHERE studio_id = ? AND tanggal = ? AND jam_mulai IN (${placeholders})
      FOR UPDATE
    `;
    
    const [slots] = await connection.query(query, [studio_id, tanggal_booking, ...slotTimes]);
    
    for (let slot of slots) {
      if (slot.status !== 'Tersedia') {
        await connection.rollback();
        return res.status(400).json({ success: false, message: 'Maaf, salah satu slot jadwal sudah dipesan', data: null });
      }
    }

    // Identify missing slots and insert them, update existing ones
    const existingTimes = slots.map(s => s.jam_mulai.substring(0, 8)); // e.g., "10:00:00"
    for (let time of slotTimes) {
      if (!existingTimes.includes(time)) {
        await connection.query(
          `INSERT INTO schedules (studio_id, tanggal, jam_mulai, status) VALUES (?, ?, ?, 'Sudah dipesan')`,
          [studio_id, tanggal_booking, time]
        );
      } else {
        await connection.query(
          `UPDATE schedules SET status = 'Sudah dipesan' WHERE studio_id = ? AND tanggal = ? AND jam_mulai = ?`,
          [studio_id, tanggal_booking, time]
        );
      }
    }

    // 3. Kalkulasi harga di server
    let harga_studio = harga_per_jam * durasi;
    let biaya_layanan = 5000;
    let diskon = 0;
    let appliedPromoKode = null;

    if (promo_kode && promo_kode.trim()) {
      const cleanKode = promo_kode.trim().toUpperCase();
      const todayStr = new Date().toISOString().split('T')[0];

      const [promos] = await connection.query('SELECT * FROM promos WHERE UPPER(kode) = ?', [cleanKode]);
      if (promos.length === 0) {
        await connection.rollback();
        return res.status(400).json({ success: false, message: 'Kode kupon promo tidak ditemukan', data: null });
      }

      const promo = promos[0];

      if (!promo.aktif) {
        await connection.rollback();
        return res.status(400).json({ success: false, message: 'Kupon promo ini sedang tidak aktif', data: null });
      }

      // Validasi tanggal berlaku
      if (promo.tanggal_mulai) {
        const startStr = promo.tanggal_mulai.toString().substring(0, 10);
        if (todayStr < startStr) {
          await connection.rollback();
          return res.status(400).json({ 
            success: false, 
            message: `Kupon promo belum dapat digunakan. Periode baru dimulai pada tanggal ${startStr}.`, 
            data: null 
          });
        }
      }

      if (promo.tanggal_berakhir) {
        const endStr = promo.tanggal_berakhir.toString().substring(0, 10);
        if (todayStr > endStr) {
          await connection.rollback();
          return res.status(400).json({ 
            success: false, 
            message: `Kupon promo sudah kedaluwarsa. Periode berakhir pada tanggal ${endStr}.`, 
            data: null 
          });
        }
      }

      // Validasi 1x pemakaian per user
      const [usedBefore] = await connection.query(
        'SELECT id FROM bookings WHERE user_id = ? AND UPPER(promo_kode) = ? AND status_pembayaran != "Dibatalkan"',
        [user_id, cleanKode]
      );

      if (usedBefore.length > 0) {
        await connection.rollback();
        return res.status(400).json({ 
          success: false, 
          message: `Anda sudah pernah menggunakan kupon "${cleanKode}" sebelumnya. Setiap pengguna hanya dapat menggunakan kupon ini 1 kali.`, 
          data: null 
        });
      }

      diskon = (harga_studio * promo.diskon_persen) / 100;
      appliedPromoKode = promo.kode;
    }

    let total_harga = Math.max(0, harga_studio + biaya_layanan - diskon);

    // 4. Create booking
    const [result] = await connection.query(
      `INSERT INTO bookings (user_id, studio_id, tanggal_booking, jam_mulai, jam_selesai, durasi, metode_pembayaran, total_harga, status_pembayaran, promo_kode, diskon_nominal) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'Menunggu Konfirmasi', ?, ?)`,
      [user_id, studio_id, tanggal_booking, jam_mulai, jam_selesai, durasi, metode_pembayaran, total_harga, appliedPromoKode, diskon]
    );

    // 5. Schedules already updated in Step 2

    await connection.commit();
    res.status(201).json({ 
      success: true, 
      message: 'Booking berhasil', 
      data: { booking_id: result.insertId, total_harga } 
    });
  } catch (error) {
    await connection.rollback();
    res.status(500).json({ success: false, message: 'Server error', data: null });
  } finally {
    connection.release();
  }
};

const formatDateStr = (dateVal) => {
  if (!dateVal) return '';
  if (typeof dateVal === 'string') return dateVal.substring(0, 10);
  if (dateVal instanceof Date) {
    const year = dateVal.getFullYear();
    const month = String(dateVal.getMonth() + 1).padStart(2, '0');
    const day = String(dateVal.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }
  return String(dateVal).substring(0, 10);
};

const normalizeTime = (timeStr) => {
  if (!timeStr) return '00:00:00';
  const parts = timeStr.toString().trim().split(':');
  const h = (parts[0] || '00').padStart(2, '0');
  const m = (parts[1] || '00').padStart(2, '0');
  const s = (parts[2] || '00').padStart(2, '0');
  return `${h}:${m}:${s}`;
};

exports.getUserBookings = async (req, res) => {
  try {
    const { userId } = req.params;
    
    // Auth check: Only owner or admin
    if (req.user.id != userId && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Akses ditolak', data: null });
    }

    const [bookings] = await db.query(
      `SELECT b.*, s.nama_studio, s.foto_url, s.lokasi 
       FROM bookings b 
       JOIN studios s ON b.studio_id = s.id 
       WHERE b.user_id = ? 
       ORDER BY b.tanggal_booking DESC, b.jam_mulai DESC`,
      [userId]
    );

    // Kategorisasi Mendatang/Berlangsung/Selesai/Dibatalkan secara realtime
    const now = new Date();
    const result = bookings.map(b => {
      let kategori = 'Berlangsung';
      
      const dateStr = formatDateStr(b.tanggal_booking);
      const startJamNorm = normalizeTime(b.jam_mulai);

      const startDateTime = new Date(`${dateStr}T${startJamNorm}`);
      
      let endDateTime;
      if (b.jam_selesai) {
        const endJamNorm = normalizeTime(b.jam_selesai);
        endDateTime = new Date(`${dateStr}T${endJamNorm}`);
      } else {
        const jamMulaiInt = parseInt(b.jam_mulai.split(':')[0], 10);
        const jamSelesaiInt = jamMulaiInt + (b.durasi || 1);
        endDateTime = new Date(`${dateStr}T${jamSelesaiInt.toString().padStart(2, '0')}:00:00`);
      }

      if (b.status_pembayaran === 'Dibatalkan') {
        kategori = 'Dibatalkan';
      } else if (now > endDateTime) {
        kategori = 'Selesai';
      } else if (b.status_pembayaran === 'Lunas') {
        kategori = 'Berlangsung';
      } else {
        kategori = 'Menunggu Konfirmasi';
      }

      // Check if can be cancelled: must be at least 2 hours before start time
      const diffMs = startDateTime.getTime() - now.getTime();
      const diffHours = diffMs / (1000 * 60 * 60);
      const canCancel = (kategori !== 'Selesai' && kategori !== 'Dibatalkan') && (diffHours >= 2);

      return { 
        ...b, 
        kategori,
        bisa_dibatalkan: canCancel,
        sisa_jam_menuju_mulai: diffHours,
        tanggal_booking_str: dateStr
      };
    });

    res.json({ success: true, message: 'Berhasil mengambil riwayat booking', data: result });
  } catch (error) {
    console.error('Error getUserBookings:', error);
    res.status(500).json({ success: false, message: 'Server error', data: null });
  }
};

exports.cancelBooking = async (req, res) => {
  const connection = await db.getConnection();
  try {
    await connection.beginTransaction();
    const { id } = req.params;

    const [bookings] = await connection.query('SELECT * FROM bookings WHERE id = ?', [id]);
    if (bookings.length === 0) {
      await connection.rollback();
      return res.status(404).json({ success: false, message: 'Pesanan tidak ditemukan', data: null });
    }

    const booking = bookings[0];

    // Auth check: only owner or admin can cancel
    if (req.user.id !== booking.user_id && req.user.role !== 'admin') {
      await connection.rollback();
      return res.status(403).json({ success: false, message: 'Akses ditolak', data: null });
    }

    if (booking.status_pembayaran === 'Dibatalkan') {
      await connection.rollback();
      return res.status(400).json({ success: false, message: 'Pesanan sudah dibatalkan sebelumnya', data: null });
    }

    // Check 2 hours rule: Cancellation is not allowed if less than 2 hours before start
    if (req.user.role !== 'admin') {
      const now = new Date();
      const dateStr = formatDateStr(booking.tanggal_booking);
      const startJamNorm = normalizeTime(booking.jam_mulai);
      
      const startDateTime = new Date(`${dateStr}T${startJamNorm}`);
      const diffMs = startDateTime.getTime() - now.getTime();
      const diffHours = diffMs / (1000 * 60 * 60);

      if (diffHours < 2) {
        await connection.rollback();
        return res.status(400).json({ 
          success: false, 
          message: 'Pesanan tidak dapat dibatalkan karena waktu mulai kurang dari 2 jam (atau jadwal sudah lewat). Pembatalan hanya diperbolehkan minimal 2 jam sebelum mulai.', 
          data: null 
        });
      }
    }

    // 1. Update booking status to Dibatalkan
    await connection.query('UPDATE bookings SET status_pembayaran = "Dibatalkan" WHERE id = ?', [id]);

    // 2. Release schedules slots back to 'Tersedia'
    const jamMulaiInt = parseInt(booking.jam_mulai.split(':')[0], 10);
    const slotTimes = [];
    for (let i = 0; i < booking.durasi; i++) {
      slotTimes.push(`${(jamMulaiInt + i).toString().padStart(2, '0')}:00:00`);
    }
    const placeholders = slotTimes.map(() => '?').join(',');

    const dateStr = formatDateStr(booking.tanggal_booking);

    if (slotTimes.length > 0) {
      await connection.query(
        `UPDATE schedules SET status = 'Tersedia' WHERE studio_id = ? AND tanggal = ? AND jam_mulai IN (${placeholders})`,
        [booking.studio_id, dateStr, ...slotTimes]
      );
    }

    await connection.commit();
    res.json({ 
      success: true, 
      message: 'Pesanan berhasil dibatalkan dan jadwal studio telah dikembalikan ke status Tersedia', 
      data: null 
    });
  } catch (error) {
    await connection.rollback();
    console.error('Error cancelBooking:', error);
    res.status(500).json({ success: false, message: 'Server error: ' + error.message, data: null });
  } finally {
    connection.release();
  }
};

