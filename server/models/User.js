import mongoose from "mongoose";

const userSchema = new mongoose.Schema(
  {
    /// 🔐 GOOGLE AUTH
    googleId: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },

    /// 👤 FULL NAME
    name: {
      type: String,
      trim: true,
      default: "Narada Link User",
      maxlength: 50,
    },

    /// 🆔 USERNAME
    username: {
      type: String,
      unique: true,
      sparse: true, // allow multiple null
      trim: true,
      lowercase: true,
      minlength: 3,
      maxlength: 20,
      index: true,
    },

    /// 📧 EMAIL
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
      index: true,
    },

    /// 🖼️ AVATAR
    avatar: {
      type: String,
      default: null,
    },

    /// 🔔 FCM TOKEN
    fcmToken: {
      type: String,
      default: null,
    },

    /// 🟢 ONLINE STATUS (🔥 REALTIME)
    isOnline: {
      type: Boolean,
      default: false,
    },

    /// ⏱ LAST SEEN (🔥 IMPORTANT)
    lastSeen: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

export default mongoose.model("User", userSchema);