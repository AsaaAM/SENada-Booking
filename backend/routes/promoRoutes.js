const express = require('express');
const router = express.Router();
const promoController = require('../controllers/promoController');
const { verifyToken, requireAdmin } = require('../middleware/authMiddleware');

// Validasi kupon untuk user saat checkout booking
router.post('/validate', verifyToken, promoController.validatePromo);

// Ambil semua daftar promo
router.get('/', verifyToken, promoController.getAllPromos);

// Admin: Tambah, update, dan hapus kupon
router.post('/', verifyToken, requireAdmin, promoController.createPromo);
router.put('/:id', verifyToken, requireAdmin, promoController.updatePromo);
router.delete('/:id', verifyToken, requireAdmin, promoController.deletePromo);

module.exports = router;
