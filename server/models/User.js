import mongoose from "mongoose";

const userSchema = new mongoose.Schema({
  googleId: String,
  username: { type: String, unique: true },
  email: String,
  avatar: String,
}, { timestamps: true });

export default mongoose.model("User", userSchema);