import express from "express";
import {
  setUsername,
  searchUsers,
  getMe,
  saveFcmToken, // 🔥 NEW IMPORT
} from "../controllers/userController.js";

import protect from "../middleware/authMiddleware.js";

const router = express.Router();

// 🔥 Set username (first time setup)
router.post("/set-username", protect, setUsername);

// 🔍 Search users
router.get("/search", protect, searchUsers);

// 👤 Get current logged-in user
router.get("/me", protect, getMe);

// 🔔 Save FCM token (🔥 PUSH NOTIFICATION CORE)
router.post("/fcm-token", protect, saveFcmToken);

export default router;