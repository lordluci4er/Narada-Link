import express from "express";
import protect from "../middleware/authMiddleware.js";
import {
  sendMessage,
  getMessages,
  getRecentChats, // 🔥 added
} from "../controllers/messageController.js";

const router = express.Router();

// 🔥 SEND MESSAGE
router.post("/", protect, sendMessage);

// 🔥 GET RECENT CHATS (⚠️ ALWAYS keep above /:userId)
router.get("/recent", protect, getRecentChats);

// 🔥 GET ALL MESSAGES (chat between 2 users)
router.get("/:userId", protect, getMessages);

export default router;