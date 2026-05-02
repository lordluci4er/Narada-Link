import express from "express";
import protect from "../middleware/authMiddleware.js";

import {
  setUsername,
  setName,
  updateProfile, // 🔥 IMPORTANT ADD
  searchUsers,
  getMe,
  saveFcmToken,
} from "../controllers/userController.js";

const router = express.Router();

/// 🔥 SET USERNAME (FIRST TIME)
router.post("/set-username", protect, setUsername);

/// 🔥 SET NAME
router.post("/set-name", protect, setName);

/// 🔥 UPDATE PROFILE (🔥 NEW MAIN API)
router.put("/update", protect, updateProfile);

/// 🔍 SEARCH USERS
router.get("/search", protect, searchUsers);

/// 👤 GET CURRENT USER
router.get("/me", protect, getMe);

/// 🔔 SAVE FCM TOKEN
router.post("/fcm-token", protect, saveFcmToken);

export default router;