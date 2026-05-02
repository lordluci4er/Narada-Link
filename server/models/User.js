import mongoose from "mongoose";

const userSchema = new mongoose.Schema(
  {
    googleId: {
      type: String,
      required: true,
      unique: true,
    },

    /// 🔥 FULL NAME (DEFAULT FIXED)
    name: {
      type: String,
      trim: true,
      default: "Narada Link User", // ✅ GLOBAL DEFAULT NAME
    },

    username: {
      type: String,
      unique: true,
      sparse: true, // ✅ allow multiple nulls
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
      default: null,
    },

    /// 🔔 FCM TOKEN
    fcmToken: {
      type: String,
      default: null,
    },

    /// 🟢 ONLINE STATUS
    isOnline: {
      type: Boolean,
      default: false,
    },

    /// ⏱ LAST SEEN
    lastSeen: {
      type: Date,
      default: null,
    },
  },
  { timestamps: true }
);

export default mongoose.model("User", userSchema);