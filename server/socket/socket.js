import Message from "../models/Message.js";

const initSocket = (io) => {
  io.on("connection", (socket) => {
    console.log("⚡ Connected:", socket.id);

    /// 🔥 USER JOIN (room based)
    socket.on("join", (userId) => {
      if (!userId) return;

      const userIdStr = userId.toString();
      socket.join(userIdStr);

      console.log("👤 Joined:", userIdStr);
    });

    /// 🔥 NEW MESSAGE TRIGGER (NO DB SAVE HERE)
    socket.on("send_message", (data) => {
      try {
        const { senderId, receiverId, text } = data;

        // ✅ validation
        if (!senderId || !receiverId || !text) {
          return socket.emit("error", "Invalid data");
        }

        const senderIdStr = senderId.toString();
        const receiverIdStr = receiverId.toString();

        // 🔥 SEND TO RECEIVER (with text)
        io.to(receiverIdStr).emit("receive_message", {
          senderId: senderIdStr,
          receiverId: receiverIdStr,
          text: text, // ✅ FIXED (MAIN ISSUE)
        });

        // 🔥 optional debug log
        console.log("📨 Message Triggered:", {
          from: senderIdStr,
          to: receiverIdStr,
          text,
        });

      } catch (error) {
        console.error("❌ Socket Error:", error.message);
        socket.emit("error", "Socket failed");
      }
    });

    /// 🔥 DISCONNECT
    socket.on("disconnect", () => {
      console.log("❌ Disconnected:", socket.id);
    });
  });
};

export default initSocket;