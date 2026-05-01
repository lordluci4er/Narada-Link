import mongoose from "mongoose";

const messageSchema = new mongoose.Schema({
  senderId: String,
  receiverId: String,
  text: String, // 🔥 FIXED
}, { timestamps: true });

export default mongoose.model("Message", messageSchema);