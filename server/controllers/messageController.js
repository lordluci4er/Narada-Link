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
      } catch (err) {}
    }

    res.status(201).json({
      ...message.toObject(),
      senderId,
      receiverId: receiverIdStr,
    });

  } catch (error) {
    res.status(500).json({ msg: "Server error" });
  }
};


/// 🔥 GET ALL MESSAGES
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

    res.json(messages);

  } catch (error) {
    res.status(500).json({ msg: "Server error" });
  }
};


/// 🔥 GET RECENT CHATS (WORKING)
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
          senderId: { $first: "$senderId" },
          createdAt: { $first: "$createdAt" },
        },
      },

      { $sort: { createdAt: -1 } },
    ]);

    res.json(chats);

  } catch (err) {
    res.status(500).json({ msg: "Server error" });
  }
};


/// 🔥 GET CONVERSATIONS (🔥 FINAL FIXED VERSION)
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

      /// 🔥 FIX: convert string → ObjectId
      {
        $addFields: {
          userObjectId: { $toObjectId: "$_id" },
        },
      },

      /// 🔥 JOIN USERS (NOW WORKS)
      {
        $lookup: {
          from: "users",
          localField: "userObjectId",
          foreignField: "_id",
          as: "user",
        },
      },

      { $unwind: "$user" },

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

    res.json(conversations);

  } catch (err) {
    console.error(err);
    res.status(500).json({ msg: "Server error" });
  }
};