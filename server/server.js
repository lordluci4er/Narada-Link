import dotenv from "dotenv";
import http from "http";
import { Server } from "socket.io";

import app from "./app.js";
import connectDB from "./config/db.js";
import initSocket from "./socket/socket.js";

import Message from "./models/Message.js";
import User from "./models/User.js";

dotenv.config();

/// 🔥 CONNECT DB
connectDB();

/// 🔥 CREATE SERVER
const server = http.createServer(app);

/// 🔥 SOCKET.IO
const io = new Server(server, {
  cors: {
    origin: "*", // ⚠️ restrict in production
    methods: ["GET", "POST", "PUT", "DELETE"],
    credentials: true,
  },
  transports: ["websocket", "polling"],
  pingTimeout: 60000,
  pingInterval: 25000,
});

/// 🔥 GLOBAL IO
app.set("io", io);

/// 🔥 OPTIONAL SOCKET FILE
initSocket(io);


/// ===============================
/// 🔥 MAIN CONNECTION
/// ===============================
io.on("connection", async (socket) => {
  console.log("🟢 Connected:", socket.id);

  let userId = socket.handshake.query.userId;

  /// =========================
  /// 🟢 HANDLE JOIN
  /// =========================
  const handleJoin = async (uid) => {
    if (!uid) return;

    userId = uid.toString();
    socket.userId = userId;

    socket.join(userId);

    const now = new Date();

    /// 🟢 UPDATE ONLINE
    await User.findByIdAndUpdate(userId, {
      isOnline: true,
      lastSeen: now,
    });

    console.log(`👤 User ${userId} joined`);

    /// 🔥 BROADCAST ONLINE
    io.emit("userStatus", {
      userId,
      isOnline: true,
      lastSeen: now,
    });

    /// =========================
    /// 🔥 AUTO DELIVERED (JOIN FIX)
    /// =========================
    const undelivered = await Message.find({
      receiverId: userId,
      status: "sent",
    });

    if (undelivered.length > 0) {
      const deliveredAt = new Date();
      const ids = undelivered.map((m) => m._id);

      await Message.updateMany(
        { _id: { $in: ids } },
        {
          $set: {
            status: "delivered",
            deliveredAt,
          },
        }
      );

      undelivered.forEach((msg) => {
        io.to(msg.senderId.toString()).emit("messageDelivered", {
          messageId: msg._id,
        });
      });
    }
  };

  /// 🔥 AUTO JOIN (HANDSHAKE)
  if (userId) {
    await handleJoin(userId);
  }

  /// 🔥 MANUAL JOIN (SAFE)
  socket.on("join", async (uid) => {
    await handleJoin(uid);
  });

  /// =========================
  /// 👀 MESSAGE SEEN (FINAL)
  /// =========================
  socket.on("messageSeen", async ({ userId: senderId }) => {
    try {
      if (!socket.userId || !senderId) return;

      const messages = await Message.find({
        senderId: senderId,
        receiverId: socket.userId,
        status: { $ne: "seen" },
      });

      if (messages.length === 0) return;

      const seenAt = new Date();
      const ids = messages.map((m) => m._id);

      await Message.updateMany(
        { _id: { $in: ids } },
        {
          $set: {
            status: "seen",
            seen: true,
            seenAt,
          },
        }
      );

      /// 🔥 BULK EMIT (UPDATED)
      io.to(senderId).emit("messagesSeen", {
        messageIds: ids,
        seenAt,
      });

    } catch (err) {
      console.log("❌ Seen Error:", err.message);
    }
  });

  /// =========================
  /// 📦 MESSAGE DELIVERED (MANUAL TRIGGER)
  /// =========================
  socket.on("messageDelivered", async () => {
    try {
      if (!socket.userId) return;

      const messages = await Message.find({
        receiverId: socket.userId,
        status: "sent",
      });

      if (messages.length === 0) return;

      const deliveredAt = new Date();
      const ids = messages.map((m) => m._id);

      await Message.updateMany(
        { _id: { $in: ids } },
        {
          $set: {
            status: "delivered",
            deliveredAt,
          },
        }
      );

      messages.forEach((msg) => {
        io.to(msg.senderId.toString()).emit("messageDelivered", {
          messageId: msg._id,
        });
      });

    } catch (err) {
      console.log("❌ Delivered Error:", err.message);
    }
  });

  /// =========================
  /// 🔴 DISCONNECT
  /// =========================
  socket.on("disconnect", async () => {
    console.log("🔴 Disconnected:", socket.id);

    if (!socket.userId) return;

    const now = new Date();

    await User.findByIdAndUpdate(socket.userId, {
      isOnline: false,
      lastSeen: now,
    });

    /// 🔥 BROADCAST OFFLINE
    io.emit("userStatus", {
      userId: socket.userId,
      isOnline: false,
      lastSeen: now,
    });
  });

  /// =========================
  /// ❌ ERROR
  /// =========================
  socket.on("error", (err) => {
    console.log("❌ Socket Error:", err);
  });
});


/// 🚀 START SERVER
const PORT = process.env.PORT || 5000;

server.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});