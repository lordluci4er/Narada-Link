import Message from "../models/Message.js";

const initSocket = (io) => {
  io.on("connection", (socket) => {
    console.log("⚡ Connected:", socket.id);

    /// 🔥 USER JOIN (ROOM BASED)
    socket.on("join", (userId) => {
      if (!userId) return;

      const userIdStr = userId.toString();
      socket.join(userIdStr);

      console.log("👤 Joined:", userIdStr);
    });

    /// 🔥 SEND MESSAGE (REALTIME)
    socket.on("send_message", (data) => {
      try {
        const { senderId, receiverId, text } = data;

        // ✅ VALIDATION
        if (!senderId || !receiverId || !text) {
          return socket.emit("error", "Invalid message data");
        }

        const senderIdStr = senderId.toString();
        const receiverIdStr = receiverId.toString();

        const payload = {
          senderId: senderIdStr,
          receiverId: receiverIdStr,
          text: text,
          createdAt: new Date().toISOString(),
        };

        /// 🔥 SEND TO RECEIVER
        io.to(receiverIdStr).emit("receive_message", payload);

        /// 🔥 SEND BACK TO SENDER (FOR INSTANT UI SYNC)
        io.to(senderIdStr).emit("receive_message", payload);

        console.log("📨 Message Sent:", payload);

      } catch (error) {
        console.error("❌ Socket Error:", error.message);
        socket.emit("error", "Message failed");
      }
    });

    /// 🔥 TYPING (OPTIONAL FEATURE)
    socket.on("typing", (data) => {
      try {
        const { senderId, receiverId } = data;

        if (!senderId || !receiverId) return;

        io.to(receiverId.toString()).emit("typing", {
          senderId: senderId.toString(),
        });

      } catch (error) {
        console.error("❌ Typing Error:", error.message);
      }
    });

    /// 🔥 DISCONNECT
    socket.on("disconnect", () => {
      console.log("❌ Disconnected:", socket.id);
    });
  });
};

export default initSocket;