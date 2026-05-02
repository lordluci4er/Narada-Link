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
      seen: false,
      status: "sent",
      deliveredAt: null,
      seenAt: null,
    });

    const sender = await User.findById(senderId);
    const io = req.app.get("io");

    /// 🔥 REALTIME MESSAGE
    io.to(receiverIdStr).emit("newMessage", {
      messageId: message._id,
      senderId,
      receiverId: receiverIdStr,
      text: message.text,
      createdAt: message.createdAt,
      senderName: sender?.name || "Narada Link User",
      status: "sent",
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


/// 🔥 GET MESSAGES (🔥 UPDATED WITH REALTIME SEEN)
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

    /// 🔥 FIND UNSEEN
    const unseenMessages = messages.filter(
      (m) =>
        m.senderId === userId &&
        m.receiverId === myId &&
        m.status !== "seen"
    );

    /// 🔥 UPDATE ONLY UNSEEN
    if (unseenMessages.length > 0) {
      const ids = unseenMessages.map((m) => m._id);

      await Message.updateMany(
        { _id: { $in: ids } },
        {
          $set: {
            status: "seen",
            seen: true,
            seenAt: new Date(),
          },
        }
      );

      /// 🔥 REALTIME EMIT (VERY IMPORTANT)
      ids.forEach((id) => {
        io.to(userId).emit("messageSeen", {
          messageId: id,
        });
      });
    }

    /// 🔥 FORMAT RESPONSE
    const formatted = messages.map((m) => ({
      ...m.toObject(),
      senderId: m.senderId.toString(),
      receiverId: m.receiverId.toString(),
      text: m.text || "",
      status: m.status || "sent",
      deliveredAt: m.deliveredAt || null,
      seenAt: m.seenAt || null,
    }));

    res.json(formatted);

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

    if (messages.length === 0) {
      return res.json({ msg: "Nothing to update" });
    }

    const io = req.app.get("io");

    for (const msg of messages) {
      await Message.updateOne(
        { _id: msg._id },
        {
          $set: {
            status: "delivered",
            deliveredAt: new Date(),
          },
        }
      );

      io.to(msg.senderId).emit("messageDelivered", {
        messageId: msg._id,
      });
    }

    res.json({ msg: "Delivered updated" });

  } catch (err) {
    console.error("Delivered Error:", err);
    res.status(500).json({ msg: "Error updating delivered" });
  }
};


/// 🔥 MARK AS SEEN (API)
export const markAsSeen = async (req, res) => {
  try {
    const myId = (req.user?.id || req.user).toString();
    const userId = req.params.userId.toString();

    const messages = await Message.find({
      senderId: userId,
      receiverId: myId,
      status: { $ne: "seen" },
    });

    if (messages.length === 0) {
      return res.json({ msg: "Nothing to update" });
    }

    const io = req.app.get("io");

    for (const msg of messages) {
      await Message.updateOne(
        { _id: msg._id },
        {
          $set: {
            status: "seen",
            seen: true,
            seenAt: new Date(),
          },
        }
      );

      io.to(userId).emit("messageSeen", {
        messageId: msg._id,
      });
    }

    res.json({ msg: "Seen updated" });

  } catch (err) {
    console.error("Seen Error:", err);
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
    ]);

    res.json(chats);

  } catch (err) {
    console.error("Recent Chats Error:", err);
    res.status(500).json({ msg: "Server error" });
  }
};