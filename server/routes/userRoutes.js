import express from "express";
import {
  setUsername,
  searchUsers,
  getMe, // 🔥 ADD THIS
} from "../controllers/userController.js";

import protect from "../middleware/authMiddleware.js";

const router = express.Router();

// 🔥 Set username (first time setup)
router.post("/set-username", protect, setUsername);

// 🔍 Search users (chat / add friend / explore)
router.get("/search", protect, searchUsers);

// 👤 Get current logged-in user
router.get("/me", protect, getMe); // 🔥 NEW ROUTE

export default router;