import mongoose from "mongoose";
import Message from "../models/Message.js";
import User from "../models/User.js";
import admin from "../config/firebaseAdmin.js";

/// 🔥 SEND MESSAGE
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
      seen: false,
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


/// 🔥 GET MESSAGES
export const getMessages = async (req, res) => {
  try {
    const myId = (req.user?.id || req.user).toString();
    const userId = req.params.userId.toString();
    const io = req.app.get("io");

    const messages = await Message.find({
      $or: [
        { senderId: myId, receiverId: userId },
        { senderId: userId, receiverId: myId },
      ],
    }).sort({ createdAt: 1 });

    /// 🔥 AUTO SEEN
    const unseenIds = messages
      .filter(
        (m) =>
          m.senderId === userId &&
          m.receiverId === myId &&
          m.status !== "seen"
      )
      .map((m) => m._id);

    if (unseenIds.length > 0) {
      const now = new Date();

      await Message.updateMany(
        { _id: { $in: unseenIds } },
        {
          $set: {
            status: "seen",
            seen: true,
            seenAt: now,
          },
        }
      );

      io.to(userId).emit("messagesSeen", {
        messageIds: unseenIds,
        seenAt: now,
      });
    }

    res.json(messages);

  } catch (error) {
    console.error("Get Messages Error:", error);
    res.status(500).json({ msg: "Server error" });
  }
};


/// 🔥 MARK AS DELIVERED
export const markAsDelivered = async (req, res) => {
  try {
    const myId = (req.user?.id || req.user).toString();

    const messages = await Message.find({
      receiverId: myId,
      status: "sent",
    });

    if (!messages.length) {
      return res.json({ msg: "Nothing to update" });
    }

    const ids = messages.map((m) => m._id);
    const io = req.app.get("io");

    const now = new Date();

    await Message.updateMany(
      { _id: { $in: ids } },
      {
        $set: {
          status: "delivered",
          deliveredAt: now,
        },
      }
    );

    messages.forEach((msg) => {
      io.to(msg.senderId).emit("messageDelivered", {
        messageId: msg._id,
      });
    });

    res.json({ msg: "Delivered updated" });

  } catch (err) {
    console.error("Delivered Error:", err);
    res.status(500).json({ msg: "Error updating delivered" });
  }
};


/// 🔥 GET CONVERSATIONS
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
        },
      },
      { $sort: { createdAt: -1 } },
    ]);

    res.json(conversations);

  } catch (err) {
    console.error("Conversations Error:", err);
    res.status(500).json({ msg: "Server error" });
  }
};


/// 🔥 ✅ FIXED: GET RECENT CHATS (MISSING FUNCTION)
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