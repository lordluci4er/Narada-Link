import express from "express";
import protect from "../middleware/authMiddleware.js";

import {
  setUsername,
  setName,
  updateProfile,
  searchUsers,
  getMe,
  saveFcmToken,
  getUserStatus, // 🔥 NEW IMPORT
} from "../controllers/userController.js";

const router = express.Router();

/// 🔥 SET USERNAME (FIRST TIME)
router.post("/set-username", protect, setUsername);

/// 🔥 SET NAME
router.post("/set-name", protect, setName);

/// 🔥 UPDATE PROFILE
router.put("/update", protect, updateProfile);

/// 🔍 SEARCH USERS
router.get("/search", protect, searchUsers);

/// 👤 GET CURRENT USER
router.get("/me", protect, getMe);

/// 🟢 GET USER ONLINE STATUS (🔥 NEW)
router.get("/status/:userId", protect, getUserStatus);

/// 🔔 SAVE FCM TOKEN
router.post("/fcm-token", protect, saveFcmToken);

export default router;