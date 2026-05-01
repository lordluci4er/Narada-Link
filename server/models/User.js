import mongoose from "mongoose";

const userSchema = new mongoose.Schema(
  {
    googleId: {
      type: String,
      required: true,
      unique: true,
    },

    username: {
      type: String,
      unique: true,
      sparse: true, // ✅ allow null usernames
      trim: true,
      lowercase: true,
      minlength: 3,
      maxlength: 20,
    },

    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },

    avatar: {
      type: String,
      default: null, // ✅ safer
    },

    /// 🔔 FCM TOKEN
    fcmToken: {
      type: String,
      default: null,
    },

    /// 🟢 ONLINE STATUS (future use)
    isOnline: {
      type: Boolean,
      default: false,
    },

    /// ⏱ LAST SEEN (future use)
    lastSeen: {
      type: Date,
      default: null,
    },
  },
  { timestamps: true }
);

export default mongoose.model("User", userSchema);