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
    console.error(error);
    res.status(500).json({ msg: "Server error" });
  }
};


/// 🔥 GET MESSAGES
export const getMessages = async (req, res) => {
  try {
    const myId = (req.user?.id || req.user).toString();
    const userId = req.params.userId.toString();

    const myObjectId = new mongoose.Types.ObjectId(myId);
    const userObjectId = new mongoose.Types.ObjectId(userId);

    const messages = await Message.find({
      $or: [
        { senderId: myObjectId, receiverId: userObjectId },
        { senderId: userObjectId, receiverId: myObjectId },
      ],
    }).sort({ createdAt: 1 });

    const formatted = messages.map((m) => ({
      ...m.toObject(),
      senderId: m.senderId.toString(),
      receiverId: m.receiverId.toString(),
    }));

    res.json(formatted);

  } catch (error) {
    console.error(error);
    res.status(500).json({ msg: "Server error" });
  }
};