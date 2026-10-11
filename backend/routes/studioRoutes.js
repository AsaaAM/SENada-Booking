const express = require('express');
const router = express.Router();
const studioController = require('../controllers/studioController');
const { verifyToken, requireAdmin } = require('../middleware/authMiddleware');

router.get('/', studioController.getAllStudios);
router.get('/filters', studioController.getStudioFilters);
router.get('/:id', studioController.getStudioById);
router.get('/:id/schedules', studioController.getStudioSchedules);

const upload = require('../middleware/uploadMiddleware');

// Upload studio images (single / multiple files)
router.post('/upload', verifyToken, requireAdmin, upload.array('images', 10), studioController.uploadImages);

// Admin studio management
router.post('/', verifyToken, requireAdmin, studioController.createStudio);
router.put('/:id', verifyToken, requireAdmin, studioController.updateStudio);
router.delete('/:id', verifyToken, requireAdmin, studioController.deleteStudio);

module.exports = router;

