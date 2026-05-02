import mongoose from "mongoose";
import Message from "../models/Message.js";
import User from "../models/User.js";
import admin from "../config/firebaseAdmin.js";

/// 🔥 SEND MESSAGE (UPDATED WITH REPLY SUPPORT)
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

      /// 🔥 REPLY FIELDS
      replyTo: replyTo || null,
      replyText: replyText || null,
      replySenderId: replySenderId || null,

      seen: false,
      status: "sent",
      deliveredAt: null,
      seenAt: null,
    });

    const sender = await User.findById(senderId);
    const io = req.app.get("io");

    /// 🔥 REALTIME (INCLUDE REPLY DATA)
    io.to(receiverIdStr).emit("newMessage", {
      messageId: message._id,
      senderId,
      receiverId: receiverIdStr,
      text: message.text,
      createdAt: message.createdAt,
      senderName: sender?.name || "Narada Link User",
      status: "sent",

      /// 🔥 REPLY DATA SEND
      replyTo: message.replyTo,
      replyText: message.replyText,
      replySenderId: message.replySenderId,
    });

    /// 🔔 PUSH NOTIFICATION
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


/// 🔥 GET MESSAGES + AUTO SEEN (UPDATED WITH REPLY)
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

    /// 🔥 MARK SEEN
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

      /// 🔥 BULK EMIT (BETTER THAN LOOP)
      io.to(userId).emit("messagesSeen", {
        messageIds: unseenIds,
        seenAt: now,
      });
    }

    /// 🔥 FORMAT RESPONSE (INCLUDE REPLY)
    const formatted = messages.map((m) => ({
      ...m.toObject(),
      senderId: m.senderId.toString(),
      receiverId: m.receiverId.toString(),

      text: m.text || "",
      status: m.status || "sent",

      deliveredAt: m.deliveredAt || null,
      seenAt: m.seenAt || null,

      /// 🔥 REPLY DATA
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


/// 🔥 MARK AS DELIVERED (NO CHANGE NEEDED)
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


/// 🔥 GET CONVERSATIONS (NO CHANGE)
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
        name: user?.name?.trim() || "Narada Link User",
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