import dotenv from "dotenv";
import http from "http";
import { Server } from "socket.io";

import app from "./app.js";
import connectDB from "./config/db.js";
import initSocket from "./socket/socket.js";

dotenv.config();

/// 🔥 CONNECT DATABASE
connectDB();

/// 🔥 CREATE HTTP SERVER
const server = http.createServer(app);

/// 🔥 SOCKET.IO SETUP
const io = new Server(server, {
  cors: {
    origin: "*", // ⚠️ production me specific domain use karo
    methods: ["GET", "POST", "PUT", "DELETE"],
    credentials: true,
  },
  transports: ["websocket", "polling"],
  pingTimeout: 60000,     // 🔥 connection stable
  pingInterval: 25000,
});

/// 🔥 MAKE IO GLOBAL (IMPORTANT)
app.set("io", io);

/// 🔥 INIT SOCKET EVENTS
initSocket(io);

/// 🔥 CONNECTION HANDLING (IMPROVED)
io.on("connection", (socket) => {
  console.log("🟢 Connected:", socket.id);

  /// 🔥 JOIN ROOM (userId based)
  socket.on("join", (userId) => {
    if (!userId) return;

    socket.join(userId.toString());
    console.log(`👤 User ${userId} joined room`);
  });

  /// 🔥 DISCONNECT
  socket.on("disconnect", () => {
    console.log("🔴 Disconnected:", socket.id);
  });

  /// ❌ ERROR HANDLING
  socket.on("error", (err) => {
    console.log("❌ Socket Error:", err);
  });
});

/// 🔥 PORT
const PORT = process.env.PORT || 5000;

/// 🚀 START SERVER
server.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});