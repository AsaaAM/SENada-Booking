const db = require('../config/db');

// BOOKINGS MANAGEMENT
exports.getAllBookings = async (req, res) => {
  try {
    const [bookings] = await db.query(
      `SELECT b.*, u.nama_lengkap, s.nama_studio 
       FROM bookings b 
       JOIN users u ON b.user_id = u.id 
       JOIN studios s ON b.studio_id = s.id 
       ORDER BY b.created_at DESC`
    );
    res.json({ success: true, message: 'Berhasil mengambil semua booking', data: bookings });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error', data: null });
  }
};

exports.approveBooking = async (req, res) => {
  try {
    const { id } = req.params;
    await db.query('UPDATE bookings SET status_pembayaran = ? WHERE id = ?', ['Lunas', id]);
    res.json({ success: true, message: 'Booking disetujui (Lunas)', data: null });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error', data: null });
  }
};

exports.rejectBooking = async (req, res) => {
  try {
    const { id } = req.params;
    
    const [bookings] = await db.query('SELECT * FROM bookings WHERE id = ?', [id]);
    if (bookings.length === 0) return res.status(404).json({ success: false, message: 'Booking tidak ditemukan', data: null });
    
    const booking = bookings[0];

    // reject booking
    await db.query('UPDATE bookings SET status_pembayaran = ? WHERE id = ?', ['Dibatalkan', id]);

    // release schedules
    const jamMulaiInt = parseInt(booking.jam_mulai.split(':')[0]);
    const slotTimes = [];
    for (let i = 0; i < booking.durasi; i++) {
      slotTimes.push(`${(jamMulaiInt + i).toString().padStart(2, '0')}:00:00`);
    }
    const placeholders = slotTimes.map(() => '?').join(',');

    if (slotTimes.length > 0) {
      await db.query(
        `UPDATE schedules SET status = 'Tersedia' WHERE studio_id = ? AND tanggal = ? AND jam_mulai IN (${placeholders}) AND status = 'Sudah dipesan'`,
        [booking.studio_id, booking.tanggal_booking, ...slotTimes]
      );
    }

    res.json({ success: true, message: 'Booking ditolak, jadwal dikembalikan ke Tersedia', data: null });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error', data: null });
  }
};

// SLOTS MANAGEMENT
exports.addSchedule = async (req, res) => {
  try {
    const { studio_id, tanggal, jam_mulai, status } = req.body;
    if (!studio_id || !tanggal || !jam_mulai) return res.status(400).json({ success: false, message: 'Data tidak lengkap', data: null });

    const [result] = await db.query(
      'INSERT INTO schedules (studio_id, tanggal, jam_mulai, status) VALUES (?, ?, ?, ?)',
      [studio_id, tanggal, jam_mulai, status || 'Tersedia']
    );
    res.status(201).json({ success: true, message: 'Jadwal berhasil ditambahkan', data: { id: result.insertId } });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error', data: null });
  }
};

exports.deleteSchedule = async (req, res) => {
  try {
    const { id } = req.params;
    await db.query('DELETE FROM schedules WHERE id = ?', [id]);
    res.json({ success: true, message: 'Jadwal berhasil dihapus', data: null });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error', data: null });
  }
};
