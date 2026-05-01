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

    const message = await Message.create({
      senderId,
      receiverId: receiverIdStr,
      text,
    });

    const receiver = await User.findById(receiverIdStr);

    if (receiver?.fcmToken) {
      try {
        await admin.messaging().send({
          token: receiver.fcmToken,
          notification: {
            title: "New Message 💬",
            body: text,
          },
          data: {
            senderId,
            receiverId: receiverIdStr,
            type: "chat",
          },
        });
      } catch (err) {
        console.log("⚠️ FCM error:", err.message);
      }
    }

    res.status(201).json({
      ...message.toObject(),
      senderId: message.senderId.toString(),
      receiverId: message.receiverId.toString(),
    });

  } catch (error) {
    console.error("Send Message Error:", error);
    res.status(500).json({ msg: "Server error" });
  }
};


/// 🔥 GET ALL MESSAGES (CHAT)
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
    }));

    res.json(formatted);

  } catch (error) {
    console.error("Get Messages Error:", error);
    res.status(500).json({ msg: "Server error" });
  }
};


/// 🔥 GET RECENT CHATS (BASIC LIST)
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
        $addFields: {
          chatUser: {
            $cond: [
              { $eq: ["$senderId", userId] },
              "$receiverId",
              "$senderId",
            ],
          },
        },
      },

      {
        $group: {
          _id: "$chatUser",
          lastMessage: { $first: "$text" },
          createdAt: { $first: "$createdAt" },
          senderId: { $first: "$senderId" },
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


/// 🔥 GET CONVERSATIONS (WITH USER DETAILS)
export const getConversations = async (req, res) => {
  try {
    const myId = (req.user?.id || req.user).toString();

    const messages = await Message.aggregate([
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
        $addFields: {
          chatUser: {
            $cond: [
              { $eq: ["$senderId", myId] },
              "$receiverId",
              "$senderId",
            ],
          },
        },
      },

      {
        $group: {
          _id: "$chatUser",
          lastMessage: { $first: "$text" },
          senderId: { $first: "$senderId" },
          createdAt: { $first: "$createdAt" },
        },
      },

      /// 🔥 JOIN USER DATA
      {
        $lookup: {
          from: "users",
          localField: "_id",
          foreignField: "_id",
          as: "user",
        },
      },

      { $unwind: "$user" },

      /// 🔥 FINAL SHAPE
      {
        $project: {
          userId: "$_id",
          username: "$user.username",
          avatar: "$user.avatar",
          lastMessage: 1,
          senderId: 1,
          createdAt: 1,
        },
      },

      { $sort: { createdAt: -1 } },
    ]);

    res.json(messages);

  } catch (err) {
    console.error("Conversations Error:", err);
    res.status(500).json({ msg: "Server error" });
  }
};