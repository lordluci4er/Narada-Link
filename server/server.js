import dotenv from "dotenv";
import http from "http";
import { Server } from "socket.io";

import app from "./app.js";
import connectDB from "./config/db.js";
import initSocket from "./socket/socket.js";

dotenv.config();

// 🔥 DB connect
connectDB();

// 🔥 HTTP server
const server = http.createServer(app);

// 🔥 Socket.IO setup
const io = new Server(server, {
  cors: {
    origin: "*", // ⚠️ production me specific domain use karna
  },
  transports: ["websocket", "polling"], // 🔥 stability
});

// 🔥 initialize socket logic (separate file)
initSocket(io);

// 🔥 optional: attach io globally (future use)
app.set("io", io);

// 🔥 PORT
const PORT = process.env.PORT || 5000;

// 🚀 start server
server.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});