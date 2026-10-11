const db = require('../config/db');

// Ensure studio_images table exists
const initTables = async () => {
  try {
    await db.query(`
      CREATE TABLE IF NOT EXISTS studio_images (
        id INT AUTO_INCREMENT PRIMARY KEY,
        studio_id INT NOT NULL,
        foto_url VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (studio_id) REFERENCES studios(id) ON DELETE CASCADE
      )
    `);
  } catch (err) {
    console.error('Error init studio_images table:', err);
  }
};
initTables();

exports.uploadImages = async (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({ success: false, message: 'Tidak ada file gambar yang diunggah', data: null });
    }
    const urls = req.files.map(f => `/uploads/${f.filename}`);
    res.json({
      success: true,
      message: 'Gambar berhasil diunggah',
      data: { urls }
    });
  } catch (error) {
    console.error('Error uploadImages:', error);
    res.status(500).json({ success: false, message: 'Server error: ' + error.message, data: null });
  }
};

exports.getStudioFilters = async (req, res) => {
  try {
    const [studios] = await db.query('SELECT DISTINCT lokasi FROM studios WHERE lokasi IS NOT NULL AND lokasi != ""');
    
    // Extract unique location names / areas
    const locationSet = new Set();
    for (const row of studios) {
      if (row.lokasi) {
        // e.g. "Kemang, Jakarta Selatan" -> split by comma to get individual regions
        const parts = row.lokasi.split(',').map(p => p.trim()).filter(p => p.length > 0);
        for (const p of parts) {
          locationSet.add(p);
        }
      }
    }

    const [facilities] = await db.query('SELECT DISTINCT nama_fasilitas FROM studio_facilities ORDER BY nama_fasilitas ASC');
    const facilityList = facilities.map(f => f.nama_fasilitas);

    res.json({
      success: true,
      message: 'Berhasil mengambil filter studio',
      data: {
        locations: Array.from(locationSet).sort(),
        facilities: facilityList
      }
    });
  } catch (error) {
    console.error('Error getStudioFilters:', error);
    res.status(500).json({ success: false, message: 'Server error: ' + error.message, data: null });
  }
};

exports.getAllStudios = async (req, res) => {
  try {
    const { search, kategori, harga_min, harga_max, sort, lokasi, fasilitas } = req.query;
    let query = 'SELECT * FROM studios WHERE 1=1';
    let params = [];

    if (search) {
      query += ' AND (nama_studio LIKE ? OR lokasi LIKE ?)';
      params.push(`%${search}%`, `%${search}%`);
    }
    if (lokasi) {
      query += ' AND lokasi LIKE ?';
      params.push(`%${lokasi}%`);
    }
    if (fasilitas) {
      query += ' AND id IN (SELECT studio_id FROM studio_facilities WHERE nama_fasilitas = ? OR nama_fasilitas LIKE ?)';
      params.push(fasilitas, `%${fasilitas}%`);
    }
    if (harga_min) {
      query += ' AND harga_per_jam >= ?';
      params.push(harga_min);
    }
    if (harga_max) {
      query += ' AND harga_per_jam <= ?';
      params.push(harga_max);
    }

    if (sort === 'Terdekat') {
      query += ' ORDER BY jarak_statis ASC';
    } else {
      query += ' ORDER BY id ASC';
    }

    const [studios] = await db.query(query, params);
    
    // get facilities and multiple images for each studio
    for (let studio of studios) {
      const [facilities] = await db.query('SELECT nama_fasilitas FROM studio_facilities WHERE studio_id = ?', [studio.id]);
      studio.fasilitas = facilities.map(f => f.nama_fasilitas);

      const [images] = await db.query('SELECT foto_url FROM studio_images WHERE studio_id = ? ORDER BY id ASC', [studio.id]);
      studio.foto_urls = images.map(img => img.foto_url);
      if (studio.foto_urls.length === 0 && studio.foto_url) {
        studio.foto_urls = [studio.foto_url];
      }
    }

    res.json({ success: true, message: 'Berhasil mengambil data studio', data: studios });
  } catch (error) {
    console.error('Error getAllStudios:', error);
    res.status(500).json({ success: false, message: 'Server error', data: null });
  }
};

exports.getStudioById = async (req, res) => {
  try {

    const [studios] = await db.query('SELECT * FROM studios WHERE id = ?', [req.params.id]);
    if (studios.length === 0) return res.status(404).json({ success: false, message: 'Studio tidak ditemukan', data: null });
    
    let studio = studios[0];
    const [facilities] = await db.query('SELECT nama_fasilitas FROM studio_facilities WHERE studio_id = ?', [studio.id]);
    studio.fasilitas = facilities.map(f => f.nama_fasilitas);

    const [images] = await db.query('SELECT foto_url FROM studio_images WHERE studio_id = ? ORDER BY id ASC', [studio.id]);
    studio.foto_urls = images.map(img => img.foto_url);
    if (studio.foto_urls.length === 0 && studio.foto_url) {
      studio.foto_urls = [studio.foto_url];
    }
    
    res.json({ success: true, message: 'Berhasil mengambil detail studio', data: studio });
  } catch (error) {
    console.error('Error getStudioById:', error);
    res.status(500).json({ success: false, message: 'Server error', data: null });
  }
};

exports.getStudioSchedules = async (req, res) => {
  try {
    const { tanggal } = req.query; // YYYY-MM-DD
    if (!tanggal) return res.status(400).json({ success: false, message: 'Tanggal diperlukan', data: null });

    const [schedules] = await db.query(
      'SELECT id, jam_mulai, status FROM schedules WHERE studio_id = ? AND tanggal = ? ORDER BY jam_mulai ASC',
      [req.params.id, tanggal]
    );
    res.json({ success: true, message: 'Berhasil mengambil jadwal', data: schedules });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error', data: null });
  }
};

exports.createStudio = async (req, res) => {
  try {
    const { nama_studio, lokasi, jarak_statis, deskripsi, harga_per_jam, rating, foto_url, foto_urls, jam_buka, jam_tutup, fasilitas } = req.body;

    if (!nama_studio || !lokasi || !harga_per_jam || !jam_buka || !jam_tutup) {
      return res.status(400).json({ 
        success: false, 
        message: 'Nama studio, lokasi, harga per jam, jam buka, dan jam tutup wajib diisi', 
        data: null 
      });
    }

    const jarak = jarak_statis ? parseFloat(jarak_statis) : 2.5;
    const rate = rating ? parseFloat(rating) : 5.0;
    const desc = deskripsi || '';

    // Determine primary foto_url and image list
    let imagesList = [];
    if (foto_urls) {
      if (Array.isArray(foto_urls)) {
        imagesList = foto_urls.map(u => u.toString().trim()).filter(u => u.length > 0);
      } else if (typeof foto_urls === 'string') {
        imagesList = foto_urls.split(',').map(u => u.trim()).filter(u => u.length > 0);
      }
    }
    if (foto_url && !imagesList.includes(foto_url.trim())) {
      imagesList.unshift(foto_url.trim());
    }

    const primaryFoto = imagesList.length > 0 ? imagesList[0] : (foto_url || '');

    const [result] = await db.query(
      `INSERT INTO studios (nama_studio, lokasi, jarak_statis, deskripsi, harga_per_jam, rating, foto_url, jam_buka, jam_tutup) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [nama_studio, lokasi, jarak, desc, harga_per_jam, rate, primaryFoto, jam_buka, jam_tutup]
    );

    const studioId = result.insertId;

    // Insert facilities
    let facilitiesList = [];
    if (fasilitas) {
      if (Array.isArray(fasilitas)) {
        facilitiesList = fasilitas.map(f => f.toString().trim()).filter(f => f.length > 0);
      } else if (typeof fasilitas === 'string') {
        facilitiesList = fasilitas.split(',').map(f => f.trim()).filter(f => f.length > 0);
      }

      for (const fas of facilitiesList) {
        await db.query('INSERT INTO studio_facilities (studio_id, nama_fasilitas) VALUES (?, ?)', [studioId, fas]);
      }
    }

    // Insert multiple images into studio_images
    for (const imgUrl of imagesList) {
      await db.query('INSERT INTO studio_images (studio_id, foto_url) VALUES (?, ?)', [studioId, imgUrl]);
    }

    const [inserted] = await db.query('SELECT * FROM studios WHERE id = ?', [studioId]);
    const studio = inserted[0];
    studio.fasilitas = facilitiesList;
    studio.foto_urls = imagesList;

    res.status(201).json({
      success: true,
      message: 'Studio berhasil ditambahkan',
      data: studio
    });
  } catch (error) {
    console.error('Error createStudio:', error);
    res.status(500).json({ success: false, message: 'Server error: ' + error.message, data: null });
  }
};

exports.deleteStudio = async (req, res) => {
  try {
    const { id } = req.params;

    const [existing] = await db.query('SELECT * FROM studios WHERE id = ?', [id]);
    if (existing.length === 0) {
      return res.status(404).json({ success: false, message: 'Studio tidak ditemukan', data: null });
    }

    // Safely delete associated data
    await db.query('DELETE FROM studio_images WHERE studio_id = ?', [id]);
    await db.query('DELETE FROM studio_facilities WHERE studio_id = ?', [id]);
    await db.query('DELETE FROM schedules WHERE studio_id = ?', [id]);
    await db.query('DELETE FROM bookings WHERE studio_id = ?', [id]);
    await db.query('DELETE FROM studios WHERE id = ?', [id]);

    res.json({ success: true, message: 'Studio berhasil dihapus', data: null });
  } catch (error) {
    console.error('Error deleteStudio:', error);
    res.status(500).json({ success: false, message: 'Server error: ' + error.message, data: null });
  }
};

exports.updateStudio = async (req, res) => {
  try {
    const { id } = req.params;
    const { nama_studio, lokasi, jarak_statis, deskripsi, harga_per_jam, rating, foto_url, foto_urls, jam_buka, jam_tutup, fasilitas } = req.body;

    const [existing] = await db.query('SELECT * FROM studios WHERE id = ?', [id]);
    if (existing.length === 0) {
      return res.status(404).json({ success: false, message: 'Studio tidak ditemukan', data: null });
    }

    const current = existing[0];
    const newNama = nama_studio !== undefined ? nama_studio : current.nama_studio;
    const newLokasi = lokasi !== undefined ? lokasi : current.lokasi;
    const newJarak = jarak_statis !== undefined ? parseFloat(jarak_statis) : current.jarak_statis;
    const newDeskripsi = deskripsi !== undefined ? deskripsi : current.deskripsi;
    const newHarga = harga_per_jam !== undefined ? harga_per_jam : current.harga_per_jam;
    const newRating = rating !== undefined ? parseFloat(rating) : current.rating;
    const newJamBuka = jam_buka !== undefined ? jam_buka : current.jam_buka;
    const newJamTutup = jam_tutup !== undefined ? jam_tutup : current.jam_tutup;

    // Process multiple images if provided
    let imagesList = null;
    if (foto_urls !== undefined) {
      if (Array.isArray(foto_urls)) {
        imagesList = foto_urls.map(u => u.toString().trim()).filter(u => u.length > 0);
      } else if (typeof foto_urls === 'string') {
        imagesList = foto_urls.split(',').map(u => u.trim()).filter(u => u.length > 0);
      }
    }

    let newPrimaryFoto = current.foto_url;
    if (imagesList !== null) {
      newPrimaryFoto = imagesList.length > 0 ? imagesList[0] : '';
    } else if (foto_url !== undefined) {
      newPrimaryFoto = foto_url;
    }

    await db.query(
      `UPDATE studios 
       SET nama_studio = ?, lokasi = ?, jarak_statis = ?, deskripsi = ?, harga_per_jam = ?, rating = ?, foto_url = ?, jam_buka = ?, jam_tutup = ?
       WHERE id = ?`,
      [newNama, newLokasi, newJarak, newDeskripsi, newHarga, newRating, newPrimaryFoto, newJamBuka, newJamTutup, id]
    );

    // If fasilitas array is passed, update studio_facilities
    if (fasilitas !== undefined) {
      let facilitiesList = [];
      if (Array.isArray(fasilitas)) {
        facilitiesList = fasilitas.map(f => f.toString().trim()).filter(f => f.length > 0);
      } else if (typeof fasilitas === 'string') {
        facilitiesList = fasilitas.split(',').map(f => f.trim()).filter(f => f.length > 0);
      }

      await db.query('DELETE FROM studio_facilities WHERE studio_id = ?', [id]);
      for (const fas of facilitiesList) {
        await db.query('INSERT INTO studio_facilities (studio_id, nama_fasilitas) VALUES (?, ?)', [id, fas]);
      }
    }

    // If foto_urls is passed, update studio_images
    if (imagesList !== null) {
      await db.query('DELETE FROM studio_images WHERE studio_id = ?', [id]);
      for (const imgUrl of imagesList) {
        await db.query('INSERT INTO studio_images (studio_id, foto_url) VALUES (?, ?)', [id, imgUrl]);
      }
    }

    const [updated] = await db.query('SELECT * FROM studios WHERE id = ?', [id]);
    const studio = updated[0];
    const [facilities] = await db.query('SELECT nama_fasilitas FROM studio_facilities WHERE studio_id = ?', [id]);
    studio.fasilitas = facilities.map(f => f.nama_fasilitas);

    const [images] = await db.query('SELECT foto_url FROM studio_images WHERE studio_id = ? ORDER BY id ASC', [id]);
    studio.foto_urls = images.map(img => img.foto_url);
    if (studio.foto_urls.length === 0 && studio.foto_url) {
      studio.foto_urls = [studio.foto_url];
    }

    res.json({
      success: true,
      message: 'Studio berhasil diperbarui',
      data: studio
    });
  } catch (error) {
    console.error('Error updateStudio:', error);
    res.status(500).json({ success: false, message: 'Server error: ' + error.message, data: null });
  }
};
