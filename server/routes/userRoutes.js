import express from "express";
import {
  setUsername,
  searchUsers
} from "../controllers/userController.js";

import protect from "../middleware/authMiddleware.js";

const router = express.Router();

// 🔥 Set username (first time setup)
router.post("/set-username", protect, setUsername);

// 🔍 Search users (chat / add friend / explore)
router.get("/search", protect, searchUsers);

export default router;