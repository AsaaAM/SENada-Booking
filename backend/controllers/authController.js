const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/db');

// helper for email validation
const validateEmail = (email) => {
  return String(email)
    .toLowerCase()
    .match(/^[^\s@]+@[^\s@]+\.[^\s@]+$/);
};

exports.register = async (req, res) => {
  try {
    const { nama_lengkap, email, password, no_hp } = req.body;
    
    // Validations
    if (!nama_lengkap || !email || !password) {
      return res.status(400).json({ success: false, message: 'Data tidak lengkap', data: null });
    }
    if (!validateEmail(email)) {
      return res.status(400).json({ success: false, message: 'Format email tidak valid', data: null });
    }
    if (password.length < 8) {
      return res.status(400).json({ success: false, message: 'Password minimal 8 karakter', data: null });
    }

    // Check email
    const [existing] = await db.query('SELECT id FROM users WHERE email = ?', [email]);
    if (existing.length > 0) return res.status(400).json({ success: false, message: 'Email sudah terdaftar', data: null });

    const hashedPassword = await bcrypt.hash(password, 10);
    
    // Ignore role from body, always 'user'
    const [result] = await db.query(
      'INSERT INTO users (nama_lengkap, email, password_hash, no_hp, role) VALUES (?, ?, ?, ?, ?)',
      [nama_lengkap, email, hashedPassword, no_hp, 'user']
    );

    const token = jwt.sign({ id: result.insertId, role: 'user' }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN || '7d' });
    
    res.status(201).json({ 
      success: true, 
      message: 'Registrasi berhasil', 
      data: { token, user: { id: result.insertId, nama_lengkap, email, no_hp, role: 'user' } }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error', data: null });
  }
};

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Email dan password harus diisi', data: null });
    }

    const [users] = await db.query('SELECT * FROM users WHERE email = ?', [email]);
    if (users.length === 0) return res.status(404).json({ success: false, message: 'User tidak ditemukan', data: null });

    const user = users[0];
    const validPassword = await bcrypt.compare(password, user.password_hash);
    if (!validPassword) return res.status(401).json({ success: false, message: 'Password salah', data: null });

    const token = jwt.sign({ id: user.id, role: user.role }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN || '7d' });
    
    delete user.password_hash; // never send password
    
    res.json({ 
      success: true, 
      message: 'Login berhasil', 
      data: { token, user }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error', data: null });
  }
};
