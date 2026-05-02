import dotenv from "dotenv";
import http from "http";
import { Server } from "socket.io";

import app from "./app.js";
import connectDB from "./config/db.js";
import initSocket from "./socket/socket.js";

import Message from "./models/Message.js";
import User from "./models/User.js";

dotenv.config();

/// 🔥 DB CONNECT
connectDB();

/// 🔥 HTTP SERVER
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

/// 🔥 OPTIONAL CUSTOM SOCKET FILE
initSocket(io);

/// 🔥 CONNECTION
io.on("connection", async (socket) => {
  console.log("🟢 Connected:", socket.id);

  /// 🔥 GET USER FROM HANDSHAKE
  const userId = socket.handshake.query.userId;

  if (userId) {
    socket.userId = userId.toString();

    /// 🟢 ONLINE UPDATE
    await User.findByIdAndUpdate(userId, {
      isOnline: true,
      lastSeen: new Date(),
    });

    socket.join(socket.userId);

    console.log(`👤 User ${socket.userId} online`);

    /// 🔥 BROADCAST ONLINE
    io.emit("userStatus", {
      userId: socket.userId,
      isOnline: true,
      lastSeen: new Date(),
    });
  }

  /// 🔥 FALLBACK JOIN (if handshake not used)
  socket.on("join", async (uid) => {
    if (!uid) return;

    socket.userId = uid.toString();
    socket.join(socket.userId);

    await User.findByIdAndUpdate(socket.userId, {
      isOnline: true,
      lastSeen: new Date(),
    });

    io.emit("userStatus", {
      userId: socket.userId,
      isOnline: true,
      lastSeen: new Date(),
    });
  });

  /// 🔥 MESSAGE SEEN (REALTIME)
  socket.on("messageSeen", async ({ userId }) => {
    try {
      if (!socket.userId || !userId) return;

      const messages = await Message.find({
        senderId: userId,
        receiverId: socket.userId,
        status: { $ne: "seen" },
      });

      await Message.updateMany(
        {
          senderId: userId,
          receiverId: socket.userId,
        },
        {
          $set: {
            status: "seen",
            seen: true,
            seenAt: new Date(),
          },
        }
      );

      /// 🔥 EMIT PER MESSAGE
      messages.forEach((msg) => {
        io.to(userId).emit("messageSeen", {
          messageId: msg._id,
        });
      });

    } catch (err) {
      console.log("❌ Seen Error:", err.message);
    }
  });

  /// 🔥 MESSAGE DELIVERED
  socket.on("messageDelivered", async () => {
    try {
      if (!socket.userId) return;

      const messages = await Message.find({
        receiverId: socket.userId,
        status: "sent",
      });

      await Message.updateMany(
        {
          receiverId: socket.userId,
          status: "sent",
        },
        {
          $set: {
            status: "delivered",
            deliveredAt: new Date(),
          },
        }
      );

      messages.forEach((msg) => {
        io.to(msg.senderId).emit("messageDelivered", {
          messageId: msg._id,
        });
      });

    } catch (err) {
      console.log("❌ Delivered Error:", err.message);
    }
  });

  /// 🔴 DISCONNECT
  socket.on("disconnect", async () => {
    console.log("🔴 Disconnected:", socket.id);

    if (!socket.userId) return;

    await User.findByIdAndUpdate(socket.userId, {
      isOnline: false,
      lastSeen: new Date(),
    });

    /// 🔥 BROADCAST OFFLINE
    io.emit("userStatus", {
      userId: socket.userId,
      isOnline: false,
      lastSeen: new Date(),
    });
  });

  /// ❌ ERROR
  socket.on("error", (err) => {
    console.log("❌ Socket Error:", err);
  });
});

/// 🚀 START SERVER
const PORT = process.env.PORT || 5000;

server.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});