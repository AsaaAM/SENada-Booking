const db = require('../config/db');

// Validasi kupon promo untuk checkout booking
exports.validatePromo = async (req, res) => {
  try {
    const { kode } = req.body;
    const userId = req.user?.id;

    if (!kode || !kode.trim()) {
      return res.status(400).json({ success: false, message: 'Kode kupon promo harus diisi', data: null });
    }

    const cleanKode = kode.trim().toUpperCase();

    // 1. Cek keberadaan kupon
    const [promos] = await db.query('SELECT * FROM promos WHERE UPPER(kode) = ?', [cleanKode]);
    if (promos.length === 0) {
      return res.status(404).json({ success: false, message: 'Kode kupon promo tidak ditemukan', data: null });
    }

    const promo = promos[0];

    // 2. Cek status aktif
    if (!promo.aktif) {
      return res.status(400).json({ success: false, message: 'Kupon promo ini sedang tidak aktif', data: null });
    }

    // 3. Cek rentang tanggal berlaku (real-time)
    const todayStr = new Date().toISOString().split('T')[0];
    
    if (promo.tanggal_mulai) {
      const startStr = promo.tanggal_mulai.toString().substring(0, 10);
      if (todayStr < startStr) {
        return res.status(400).json({ 
          success: false, 
          message: `Kupon promo belum dapat digunakan. Periode acara baru dimulai pada tanggal ${startStr}.`, 
          data: null 
        });
      }
    }

    if (promo.tanggal_berakhir) {
      const endStr = promo.tanggal_berakhir.toString().substring(0, 10);
      if (todayStr > endStr) {
        return res.status(400).json({ 
          success: false, 
          message: `Kupon promo sudah kedaluwarsa. Periode promo telah berakhir pada tanggal ${endStr}.`, 
          data: null 
        });
      }
    }

    // 4. Cek aturan pemakaian: Setiap user hanya bisa pakai 1x saja per kupon
    if (userId) {
      const [usedBefore] = await db.query(
        'SELECT id FROM bookings WHERE user_id = ? AND UPPER(promo_kode) = ? AND status_pembayaran != "Dibatalkan"',
        [userId, cleanKode]
      );

      if (usedBefore.length > 0) {
        return res.status(400).json({ 
          success: false, 
          message: `Anda sudah pernah menggunakan kupon "${cleanKode}" sebelumnya. Setiap pengguna hanya dapat menggunakan kupon ini 1 kali.`, 
          data: null 
        });
      }
    }

    res.json({ 
      success: true, 
      message: `Kupon "${cleanKode}" berhasil digunakan! Diskon ${promo.diskon_persen}%`, 
      data: { 
        id: promo.id,
        kode: promo.kode,
        nama_acara: promo.nama_acara || 'Promo Spesial',
        diskon_persen: promo.diskon_persen,
        tanggal_mulai: promo.tanggal_mulai ? promo.tanggal_mulai.toString().substring(0, 10) : null,
        tanggal_berakhir: promo.tanggal_berakhir ? promo.tanggal_berakhir.toString().substring(0, 10) : null,
      } 
    });
  } catch (error) {
    console.error('Error validatePromo:', error);
    res.status(500).json({ success: false, message: 'Server error: ' + error.message, data: null });
  }
};

// Ambil semua daftar promo (Admin & Publik)
exports.getAllPromos = async (req, res) => {
  try {
    const [promos] = await db.query('SELECT * FROM promos ORDER BY id DESC');
    const todayStr = new Date().toISOString().split('T')[0];

    const result = promos.map(p => {
      let statusKupon = 'Aktif';
      const startStr = p.tanggal_mulai ? p.tanggal_mulai.toString().substring(0, 10) : null;
      const endStr = p.tanggal_berakhir ? p.tanggal_berakhir.toString().substring(0, 10) : null;

      if (!p.aktif) {
        statusKupon = 'Nonaktif';
      } else if (endStr && todayStr > endStr) {
        statusKupon = 'Kedaluwarsa';
      } else if (startStr && todayStr < startStr) {
        statusKupon = 'Mendatang';
      }

      return {
        ...p,
        tanggal_mulai: startStr,
        tanggal_berakhir: endStr,
        status_kupon: statusKupon,
      };
    });

    res.json({ success: true, message: 'Berhasil mengambil daftar promo', data: result });
  } catch (error) {
    console.error('Error getAllPromos:', error);
    res.status(500).json({ success: false, message: 'Server error: ' + error.message, data: null });
  }
};

// Admin: Tambah kupon promo baru
exports.createPromo = async (req, res) => {
  try {
    const { kode, nama_acara, diskon_persen, tanggal_mulai, tanggal_berakhir, aktif } = req.body;

    if (!kode || !diskon_persen) {
      return res.status(400).json({ success: false, message: 'Kode kupon dan persentase diskon wajib diisi', data: null });
    }

    const cleanKode = kode.trim().toUpperCase();

    // Cek duplikasi kode
    const [existing] = await db.query('SELECT id FROM promos WHERE UPPER(kode) = ?', [cleanKode]);
    if (existing.length > 0) {
      return res.status(400).json({ success: false, message: `Kode kupon "${cleanKode}" sudah terdaftar`, data: null });
    }

    const [result] = await db.query(
      `INSERT INTO promos (kode, nama_acara, diskon_persen, tanggal_mulai, tanggal_berakhir, aktif) 
       VALUES (?, ?, ?, ?, ?, ?)`,
      [
        cleanKode,
        nama_acara ? nama_acara.trim() : null,
        parseInt(diskon_persen, 10),
        tanggal_mulai || null,
        tanggal_berakhir || null,
        aktif === false ? false : true,
      ]
    );

    res.status(201).json({
      success: true,
      message: 'Kupon promo berhasil ditambahkan!',
      data: { id: result.insertId, kode: cleanKode }
    });
  } catch (error) {
    console.error('Error createPromo:', error);
    res.status(500).json({ success: false, message: 'Server error: ' + error.message, data: null });
  }
};

// Admin: Update kupon promo
exports.updatePromo = async (req, res) => {
  try {
    const { id } = req.params;
    const { kode, nama_acara, diskon_persen, tanggal_mulai, tanggal_berakhir, aktif } = req.body;

    const [existing] = await db.query('SELECT * FROM promos WHERE id = ?', [id]);
    if (existing.length === 0) {
      return res.status(404).json({ success: false, message: 'Kupon promo tidak ditemukan', data: null });
    }

    const cleanKode = kode ? kode.trim().toUpperCase() : existing[0].kode;

    // Cek duplikasi jika ganti kode
    if (cleanKode !== existing[0].kode) {
      const [duplicate] = await db.query('SELECT id FROM promos WHERE UPPER(kode) = ? AND id != ?', [cleanKode, id]);
      if (duplicate.length > 0) {
        return res.status(400).json({ success: false, message: `Kode kupon "${cleanKode}" sudah terdaftar`, data: null });
      }
    }

    await db.query(
      `UPDATE promos 
       SET kode = ?, nama_acara = ?, diskon_persen = ?, tanggal_mulai = ?, tanggal_berakhir = ?, aktif = ? 
       WHERE id = ?`,
      [
        cleanKode,
        nama_acara !== undefined ? (nama_acara ? nama_acara.trim() : null) : existing[0].nama_acara,
        diskon_persen !== undefined ? parseInt(diskon_persen, 10) : existing[0].diskon_persen,
        tanggal_mulai !== undefined ? (tanggal_mulai || null) : existing[0].tanggal_mulai,
        tanggal_berakhir !== undefined ? (tanggal_berakhir || null) : existing[0].tanggal_berakhir,
        aktif !== undefined ? (aktif === true || aktif === '1' || aktif === 1) : existing[0].aktif,
        id,
      ]
    );

    res.json({ success: true, message: 'Kupon promo berhasil diperbarui!', data: null });
  } catch (error) {
    console.error('Error updatePromo:', error);
    res.status(500).json({ success: false, message: 'Server error: ' + error.message, data: null });
  }
};

// Admin: Hapus kupon promo
exports.deletePromo = async (req, res) => {
  try {
    const { id } = req.params;
    const [result] = await db.query('DELETE FROM promos WHERE id = ?', [id]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Kupon promo tidak ditemukan', data: null });
    }

    res.json({ success: true, message: 'Kupon promo berhasil dihapus!', data: null });
  } catch (error) {
    console.error('Error deletePromo:', error);
    res.status(500).json({ success: false, message: 'Server error: ' + error.message, data: null });
  }
};
