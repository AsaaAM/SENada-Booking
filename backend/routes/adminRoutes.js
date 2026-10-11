const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const studioController = require('../controllers/studioController');
const { verifyToken, requireAdmin } = require('../middleware/authMiddleware');

router.get('/bookings', verifyToken, requireAdmin, adminController.getAllBookings);
router.put('/bookings/:id/approve', verifyToken, requireAdmin, adminController.approveBooking);
router.put('/bookings/:id/reject', verifyToken, requireAdmin, adminController.rejectBooking);

const upload = require('../middleware/uploadMiddleware');

// Studios Management
router.post('/studios/upload', verifyToken, requireAdmin, upload.array('images', 10), studioController.uploadImages);
router.post('/studios', verifyToken, requireAdmin, studioController.createStudio);
router.put('/studios/:id', verifyToken, requireAdmin, studioController.updateStudio);
router.delete('/studios/:id', verifyToken, requireAdmin, studioController.deleteStudio);



// CRUD Slots
router.post('/schedules', verifyToken, requireAdmin, adminController.addSchedule);
router.delete('/schedules/:id', verifyToken, requireAdmin, adminController.deleteSchedule);

module.exports = router;

