import Message from "../models/Message.js";

const initSocket = (io) => {
  io.on("connection", (socket) => {

    socket.on("join", (userId) => {
      socket.join(userId);
    });

    socket.on("send_message", async (data) => {
      const msg = await Message.create(data);

      io.to(data.receiverId).emit("receive_message", msg);
    });

  });
};

export default initSocket;