import express from "express";
import {
  setUsername,
  setName,        // 🔥 NEW IMPORT
  searchUsers,
  getMe,
  saveFcmToken,
} from "../controllers/userController.js";

import protect from "../middleware/authMiddleware.js";

const router = express.Router();

/// 🔥 SET USERNAME (FIRST TIME)
router.post("/set-username", protect, setUsername);

/// 🔥 SET NAME (NEW)
router.post("/set-name", protect, setName);

/// 🔍 SEARCH USERS
router.get("/search", protect, searchUsers);

/// 👤 GET CURRENT USER
router.get("/me", protect, getMe);

/// 🔔 SAVE FCM TOKEN
router.post("/fcm-token", protect, saveFcmToken);

export default router;