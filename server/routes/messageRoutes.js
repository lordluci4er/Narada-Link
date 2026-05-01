import express from "express";
import protect from "../middleware/authMiddleware.js";
import {
  sendMessage,
  getMessages,
} from "../controllers/messageController.js";

const router = express.Router();

// 🔥 SEND MESSAGE
router.post("/", protect, sendMessage);

// 🔥 GET ALL MESSAGES (chat between 2 users)
router.get("/:userId", protect, getMessages);

export default router;