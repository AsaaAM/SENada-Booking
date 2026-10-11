const db = require('../config/db');
const bcrypt = require('bcryptjs');

exports.getUserProfile = async (req, res) => {
  try {
    const { id } = req.params;
    
    if (req.user.id != id && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Akses ditolak', data: null });
    }

    const [users] = await db.query('SELECT id, nama_lengkap, email, no_hp, poin_nada, role FROM users WHERE id = ?', [id]);
    if (users.length === 0) return res.status(404).json({ success: false, message: 'User tidak ditemukan', data: null });

    const user = users[0];

    const [bookings] = await db.query('SELECT COUNT(*) as total FROM bookings WHERE user_id = ?', [id]);
    user.total_booking = bookings[0].total;

    const [favStudio] = await db.query(
      `SELECT studio_id, COUNT(studio_id) as freq 
       FROM bookings WHERE user_id = ? 
       GROUP BY studio_id ORDER BY freq DESC LIMIT 1`, [id]
    );
    
    user.studio_favorit = favStudio.length > 0 ? favStudio[0].freq : 0; 

    res.json({ success: true, message: 'Berhasil mengambil profil', data: user });
  } catch (error) {
    console.error('Error getUserProfile:', error);
    res.status(500).json({ success: false, message: 'Server error', data: null });
  }
};

exports.updateUserProfile = async (req, res) => {
  try {
    const { id } = req.params;
    const { nama_lengkap, no_hp } = req.body;

    if (req.user.id != id && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Akses ditolak', data: null });
    }

    if (!nama_lengkap || !nama_lengkap.trim()) {
      return res.status(400).json({ success: false, message: 'Nama lengkap tidak boleh kosong', data: null });
    }

    await db.query('UPDATE users SET nama_lengkap = ?, no_hp = ? WHERE id = ?', [nama_lengkap.trim(), no_hp ? no_hp.trim() : '', id]);

    const [updatedUsers] = await db.query('SELECT id, nama_lengkap, email, no_hp, poin_nada, role FROM users WHERE id = ?', [id]);
    res.json({ success: true, message: 'Profil berhasil diperbarui', data: updatedUsers[0] });
  } catch (error) {
    console.error('Error updateUserProfile:', error);
    res.status(500).json({ success: false, message: 'Server error: ' + error.message, data: null });
  }
};

exports.changePassword = async (req, res) => {
  try {
    const { id } = req.params;
    const { password_lama, password_baru } = req.body;

    if (req.user.id != id && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Akses ditolak', data: null });
    }

    if (!password_lama || !password_baru) {
      return res.status(400).json({ success: false, message: 'Kata sandi lama dan baru wajib diisi', data: null });
    }

    if (password_baru.length < 8) {
      return res.status(400).json({ success: false, message: 'Kata sandi baru minimal 8 karakter', data: null });
    }

    const [users] = await db.query('SELECT password_hash FROM users WHERE id = ?', [id]);
    if (users.length === 0) return res.status(404).json({ success: false, message: 'User tidak ditemukan', data: null });

    const isMatch = await bcrypt.compare(password_lama, users[0].password_hash);
    if (!isMatch) {
      return res.status(400).json({ success: false, message: 'Kata sandi lama tidak sesuai', data: null });
    }

    const hashedNew = await bcrypt.hash(password_baru, 10);
    await db.query('UPDATE users SET password_hash = ? WHERE id = ?', [hashedNew, id]);

    res.json({ success: true, message: 'Kata sandi berhasil diubah', data: null });
  } catch (error) {
    console.error('Error changePassword:', error);
    res.status(500).json({ success: false, message: 'Server error: ' + error.message, data: null });
  }
};
