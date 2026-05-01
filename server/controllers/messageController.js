import Message from "../models/Message.js";
import User from "../models/User.js";
import admin from "../config/firebaseAdmin.js";

/// 🔥 SEND MESSAGE + PUSH NOTIFICATION
export const sendMessage = async (req, res) => {
  try {
    // 🔥 SAFE USER ID (always string)
    const senderId = (req.user?.id || req.user).toString();
    const { receiverId, text } = req.body;

    if (!receiverId || !text) {
      return res.status(400).json({ msg: "Missing fields" });
    }

    // 💾 Save message
    const message = await Message.create({
      senderId,
      receiverId,
      text,
    });

    // 🔍 Get receiver
    const receiver = await User.findById(receiverId);

    // 🔔 SEND PUSH NOTIFICATION
    if (receiver?.fcmToken) {
      try {
        await admin.messaging().send({
          token: receiver.fcmToken,
          notification: {
            title: "New Message 💬",
            body: text,
          },
          data: {
            senderId: String(senderId),
            receiverId: String(receiverId),
            type: "chat",
          },
        });

        console.log("🔔 Notification sent to:", receiverId);

      } catch (err) {
        console.log("⚠️ FCM send error:", err.message);
      }
    }

    // ✅ RESPONSE WITH STRING IDS
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


/// 🔥 GET MESSAGES
export const getMessages = async (req, res) => {
  try {
    const myId = (req.user?.id || req.user).toString();
    const userId = req.params.userId;

    const messages = await Message.find({
      $or: [
        { senderId: myId, receiverId: userId },
        { senderId: userId, receiverId: myId },
      ],
    }).sort({ createdAt: 1 });

    // ✅ FORMAT ALL IDS TO STRING
    const formattedMessages = messages.map((m) => ({
      ...m.toObject(),
      senderId: m.senderId.toString(),
      receiverId: m.receiverId.toString(),
    }));

    res.json(formattedMessages);

  } catch (error) {
    console.error("Get Messages Error:", error);
    res.status(500).json({ msg: "Server error" });
  }
};