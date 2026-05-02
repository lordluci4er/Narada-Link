import express from "express";
import protect from "../middleware/authMiddleware.js";
import {
  sendMessage,
  getMessages,
  getRecentChats,
  getConversations,
  markAsSeen, // 🔥 NEW
} from "../controllers/messageController.js";

const router = express.Router();

/// 🔥 SEND MESSAGE
// POST /api/messages
router.post("/", protect, sendMessage);

/// 🔥 GET CONVERSATIONS (WITH UNREAD COUNT)
// GET /api/messages/conversations
router.get("/conversations", protect, getConversations);

/// 🔥 GET RECENT CHATS
// GET /api/messages/recent
router.get("/recent", protect, getRecentChats);

/// 🔥 MARK AS SEEN (🔥 NEW)
// PUT /api/messages/seen/:userId
router.put("/seen/:userId", protect, markAsSeen);

/// 🔥 GET CHAT BETWEEN TWO USERS
// GET /api/messages/:userId
router.get("/:userId", protect, getMessages);

export default router;