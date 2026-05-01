import express from "express";
import protect from "../middleware/authMiddleware.js";
import {
  sendMessage,
  getMessages,
  getRecentChats,
} from "../controllers/messageController.js";

const router = express.Router();

/// 🔥 SEND MESSAGE
// POST /api/messages
router.post("/", protect, sendMessage);

/// 🔥 GET RECENT CHATS (⚠️ must be before :userId)
// GET /api/messages/recent
router.get("/recent", protect, getRecentChats);

/// 🔥 GET CHAT BETWEEN TWO USERS
// GET /api/messages/:userId
router.get("/:userId", protect, getMessages);

export default router;