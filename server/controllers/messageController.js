import mongoose from "mongoose";
import Message from "../models/Message.js";
import User from "../models/User.js";
import admin from "../config/firebaseAdmin.js";

/// 🔥 SEND MESSAGE
export const sendMessage = async (req, res) => {
  try {
    const senderId = (req.user?.id || req.user).toString();
    const { receiverId, text } = req.body;

    if (!receiverId || !text) {
      return res.status(400).json({ msg: "Missing fields" });
    }

    const receiverIdStr = receiverId.toString();

    /// 🔥 SAVE MESSAGE
    const message = await Message.create({
      senderId,
      receiverId: receiverIdStr,
      text,
      seen: false,
    });

    const sender = await User.findById(senderId);

    /// 🔥 SOCKET EMIT
    const io = req.app.get("io");

    io.to(receiverIdStr).emit("newMessage", {
      senderId,
      receiverId: receiverIdStr,
      text: message.text || "",
      createdAt: message.createdAt,
      senderName: sender?.name || "Narada Link User",
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
          data: {
            senderId,
            receiverId: receiverIdStr,
            type: "chat",
          },
        });
      } catch (err) {
        console.log("FCM Error:", err.message);
      }
    }

    res.status(201).json({
      ...message.toObject(),
      senderId,
      receiverId: receiverIdStr,
      text: message.text || "",
      createdAt: message.createdAt,
      seen: message.seen,
    });

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

    const messages = await Message.find({
      $or: [
        { senderId: myId, receiverId: userId },
        { senderId: userId, receiverId: myId },
      ],
    }).sort({ createdAt: 1 });

    const formatted = messages.map((m) => ({
      ...m.toObject(),
      senderId: m.senderId.toString(),
      receiverId: m.receiverId.toString(),
      text: m.text || "",
      createdAt: m.createdAt,
      seen: m.seen ?? false,
    }));

    res.json(formatted);

  } catch (error) {
    console.error("Get Messages Error:", error);
    res.status(500).json({ msg: "Server error" });
  }
};


/// 🔥 MARK AS SEEN
export const markAsSeen = async (req, res) => {
  try {
    const myId = (req.user?.id || req.user).toString();
    const userId = req.params.userId.toString();

    await Message.updateMany(
      {
        senderId: userId,
        receiverId: myId,
        seen: false,
      },
      { $set: { seen: true } }
    );

    res.json({ msg: "Seen updated" });

  } catch (err) {
    console.error("Mark Seen Error:", err);
    res.status(500).json({ msg: "Error updating seen" });
  }
};


/// 🔥 GET RECENT CHATS
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

      {
        $addFields: {
          lastMessage: { $ifNull: ["$lastMessage", ""] },
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


/// 🔥 GET CONVERSATIONS (🔥 FINAL WITH UNREAD COUNT)
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

          /// 🔥 UNREAD COUNT
          unreadCount: {
            $sum: {
              $cond: [
                {
                  $and: [
                    { $eq: ["$receiverId", myId] },
                    { $eq: ["$seen", false] },
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
        name:
          user?.name && user.name.trim() !== ""
            ? user.name
            : "Narada Link User",
        username: user?.username || "",
        avatar: user?.avatar || null,
        lastMessage: c.lastMessage || "",
        createdAt: c.createdAt,
        unreadCount: c.unreadCount || 0,
      };
    });

    result.sort(
      (a, b) =>
        new Date(b.createdAt) - new Date(a.createdAt)
    );

    res.json(result);

  } catch (err) {
    console.error("Conversations Error:", err);
    res.status(500).json({ msg: "Server error" });
  }
};