import mongoose from "mongoose";
import Message from "../models/Message.js";
import User from "../models/User.js";
import admin from "../config/firebaseAdmin.js";

/// 🔥 SEND MESSAGE (HYBRID)
export const sendMessage = async (req, res) => {
  try {
    const senderId = (req.user?.id || req.user).toString();

    const {
      receiverId,
      text,
      replyTo,
      replyText,
      replySenderId,
    } = req.body;

    if (!receiverId || !text) {
      return res.status(400).json({ msg: "Missing fields" });
    }

    const receiverIdStr = receiverId.toString();

    const message = await Message.create({
      senderId,
      receiverId: receiverIdStr,
      text,
      replyTo: replyTo || null,
      replyText: replyText || null,
      replySenderId: replySenderId || null,
      status: "sent",
    });

    const sender = await User.findById(senderId);
    const io = req.app.get("io");

    /// 🔥 REALTIME
    io.to(receiverIdStr).emit("newMessage", {
      messageId: message._id,
      senderId,
      receiverId: receiverIdStr,
      text: message.text,
      createdAt: message.createdAt,
      senderName: sender?.name || "Narada Link User",
      status: "sent",
      replyTo: message.replyTo,
      replyText: message.replyText,
      replySenderId: message.replySenderId,
    });

    /// 🔔 PUSH
    const receiver = await User.findById(receiverIdStr);

    if (receiver?.fcmToken) {
      try {
        await admin.messaging().send({
          token: receiver.fcmToken,
          notification: {
            title: sender?.name || "New Message",
            body: text,
          },
        });
      } catch (err) {
        console.log("FCM Error:", err.message);
      }
    }

    res.status(201).json(message);
  } catch (error) {
    console.error("Send Message Error:", error);
    res.status(500).json({ msg: "Server error" });
  }
};


/// 🔥 GET MESSAGES (CLEAN - FETCH ONLY)
export const getMessages = async (req, res) => {
  try {
    const myId = (req.user?.id || req.user).toString();
    const userId = req.params.userId.toString();

    const messages = await Message.find({
      $or: [
        { senderId: myId, receiverId: userId },
        { senderId: userId, receiverId: myId },
      ],
    }).sort({ createdAt: 1 });

    /// ❌ REMOVED unseen logic + updateMany + emit

    /// 🔥 FORMAT
    const formatted = messages.map((m) => ({
      ...m.toObject(),
      senderId: m.senderId.toString(),
      receiverId: m.receiverId.toString(),
      text: m.text || "",
      status: m.status || "sent",
      deliveredAt: m.deliveredAt || null,
      seenAt: m.seenAt || null,
      replyTo: m.replyTo || null,
      replyText: m.replyText || null,
      replySenderId: m.replySenderId || null,
    }));

    res.json(formatted);
  } catch (error) {
    console.error("Get Messages Error:", error);
    res.status(500).json({ msg: "Server error" });
  }
};


/// ❌ REMOVED markAsDelivered API

/// ❌ REMOVED markAsSeen API


/// 🔥 GET CONVERSATIONS (FIXED)
export const getConversations = async (req, res) => {
  try {
    const myId = (req.user?.id || req.user).toString();

    const conversations = await Message.aggregate([
      {
        $match: {
          $or: [
            { senderId: myId },
            { receiverId: myId },
          ],
        },
      },
      { $sort: { createdAt: -1 } },

      {
        $group: {
          _id: {
            $cond: [
              { $eq: ["$senderId", myId] },
              "$receiverId",
              "$senderId",
            ],
          },
          lastMessage: { $first: "$text" },
          createdAt: { $first: "$createdAt" },
          unreadCount: {
            $sum: {
              $cond: [
                {
                  $and: [
                    { $eq: ["$receiverId", myId] },
                    { $ne: ["$status", "seen"] },
                  ],
                },
                1,
                0,
              ],
            },
          },
        },
      },
    ]);

    /// 🔥 ADD USER DATA
    const userIds = conversations.map(
      (c) => new mongoose.Types.ObjectId(c._id)
    );

    const users = await User.find({
      _id: { $in: userIds },
    }).select("name username avatar");

    const result = conversations.map((c) => {
      const user = users.find(
        (u) => u._id.toString() === c._id.toString()
      );

      return {
        userId: c._id,
        name: user?.name || "Narada Link User",
        username: user?.username || "",
        avatar: user?.avatar || null,
        lastMessage: c.lastMessage,
        createdAt: c.createdAt,
        unreadCount: c.unreadCount,
      };
    });

    res.json(result);
  } catch (err) {
    console.error("Conversations Error:", err);
    res.status(500).json({ msg: "Server error" });
  }
};


/// 🔥 GET RECENT CHATS (UNCHANGED)
export const getRecentChats = async (req, res) => {
  try {
    const userId = (req.user?.id || req.user).toString();

    const chats = await Message.aggregate([
      {
        $match: {
          $or: [
            { senderId: userId },
            { receiverId: userId },
          ],
        },
      },
      { $sort: { createdAt: -1 } },

      {
        $group: {
          _id: {
            $cond: [
              { $eq: ["$senderId", userId] },
              "$receiverId",
              "$senderId",
            ],
          },
          lastMessage: { $first: "$text" },
          createdAt: { $first: "$createdAt" },
        },
      },

      { $sort: { createdAt: -1 } },
    ]);

    res.json(chats);
  } catch (err) {
    console.error("Recent Chats Error:", err);
    res.status(500).json({ msg: "Server error" });
  }
};