const express = require('express');
const router = express.Router();
const bookingController = require('../controllers/bookingController');
const { verifyToken } = require('../middleware/authMiddleware');

router.post('/', verifyToken, bookingController.createBooking);
router.get('/user/:userId', verifyToken, bookingController.getUserBookings);
router.put('/:id/cancel', verifyToken, bookingController.cancelBooking);

module.exports = router;
