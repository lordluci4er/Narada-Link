import dotenv from "dotenv";
import http from "http";
import { Server } from "socket.io";

import app from "./app.js";
import connectDB from "./config/db.js";
import initSocket from "./socket/socket.js";
import Message from "./models/Message.js";

dotenv.config();

/// 🔥 CONNECT DATABASE
connectDB();

/// 🔥 CREATE SERVER
const server = http.createServer(app);

/// 🔥 SOCKET.IO SETUP
const io = new Server(server, {
  cors: {
    origin: "*", // ⚠️ production me restrict karo
    methods: ["GET", "POST", "PUT", "DELETE"],
    credentials: true,
  },
  transports: ["websocket", "polling"],
  pingTimeout: 60000,
  pingInterval: 25000,
});

/// 🔥 GLOBAL IO
app.set("io", io);

/// 🔥 INIT CUSTOM SOCKET FILE (if any)
initSocket(io);


/// 🔥 CONNECTION
io.on("connection", (socket) => {
  console.log("🟢 Connected:", socket.id);

  /// 🔥 JOIN ROOM + STORE USER ID
  socket.on("join", (userId) => {
    if (!userId) return;

    socket.userId = userId.toString(); // ✅ FIX (VERY IMPORTANT)

    socket.join(socket.userId);

    console.log(`👤 User ${socket.userId} joined`);
  });

  /// 🔥 REALTIME SEEN (🔥 FINAL)
  socket.on("messageSeen", async ({ userId }) => {
    try {
      if (!socket.userId || !userId) return;

      /// 🔥 UPDATE DB
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

      /// 🔥 EMIT BACK TO SENDER
      messages.forEach((msg) => {
        io.to(userId).emit("messageSeen", {
          messageId: msg._id,
        });
      });

    } catch (err) {
      console.log("❌ Seen Socket Error:", err.message);
    }
  });

  /// 🔥 REALTIME DELIVERED (OPTIONAL BUT 🔥 PRO)
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
      console.log("❌ Delivered Socket Error:", err.message);
    }
  });

  /// 🔴 DISCONNECT
  socket.on("disconnect", () => {
    console.log("🔴 Disconnected:", socket.id);
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