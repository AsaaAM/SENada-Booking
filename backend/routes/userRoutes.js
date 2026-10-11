const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { verifyToken } = require('../middleware/authMiddleware');

router.get('/:id', verifyToken, userController.getUserProfile);
router.put('/:id', verifyToken, userController.updateUserProfile);
router.put('/:id/change-password', verifyToken, userController.changePassword);

module.exports = router;
