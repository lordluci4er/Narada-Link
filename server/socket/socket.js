import Message from "../models/Message.js";

const users = {}; // 🔥 userId -> socketId mapping

const initSocket = (io) => {
  io.on("connection", (socket) => {
    console.log("⚡ Connected:", socket.id);

    // 🔥 USER JOIN
    socket.on("join", (userId) => {
      if (!userId) return;

      users[userId] = socket.id;
      socket.join(userId);

      console.log("👤 Joined:", userId);
    });

    // 🔥 SEND MESSAGE
    socket.on("send_message", async (data) => {
      try {
        const { senderId, receiverId, text } = data;

        // ❌ validation
        if (!senderId || !receiverId || !text) {
          return socket.emit("error", "Invalid message data");
        }

        // 💾 save to DB
        const msg = await Message.create({
          senderId,
          receiverId,
          text,
        });

        // 🔥 send to receiver (room based)
        io.to(receiverId).emit("receive_message", msg);

        // 🔥 also send back to sender (sync)
        io.to(senderId).emit("receive_message", msg);

      } catch (error) {
        console.error("❌ Socket Message Error:", error.message);
        socket.emit("error", "Message failed");
      }
    });

    // 🔥 DISCONNECT
    socket.on("disconnect", () => {
      console.log("❌ Disconnected:", socket.id);

      // 🧹 cleanup mapping
      for (const userId in users) {
        if (users[userId] === socket.id) {
          delete users[userId];
          break;
        }
      }
    });
  });
};

export default initSocket;