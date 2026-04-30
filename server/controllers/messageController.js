import Message from "../models/Message.js";

export const getMessages = async (req, res) => {
  const messages = await Message.find({
    $or: [
      { senderId: req.user, receiverId: req.params.userId },
      { senderId: req.params.userId, receiverId: req.user }
    ]
  }).sort({ createdAt: 1 });

  res.json(messages);
};