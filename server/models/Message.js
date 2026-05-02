import mongoose from "mongoose";

const messageSchema = new mongoose.Schema(
  {
    /// 👤 SENDER
    senderId: {
      type: String,
      required: true,
      index: true,
    },

    /// 👤 RECEIVER
    receiverId: {
      type: String,
      required: true,
      index: true,
    },

    /// 💬 TEXT
    text: {
      type: String,
      default: "",
      trim: true,
    },

    /// 🔁 REPLY SUPPORT (🔥 NEW)

    // original message reference
    replyTo: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Message",
      default: null,
    },

    // original message text snapshot (fast UI)
    replyText: {
      type: String,
      default: null,
    },

    // kisne original message bheja tha
    replySenderId: {
      type: String,
      default: null,
    },

    /// 👁️ QUICK FLAG
    seen: {
      type: Boolean,
      default: false,
      index: true,
    },

    /// 🔥 STATUS SYSTEM
    status: {
      type: String,
      enum: ["sent", "delivered", "seen"],
      default: "sent",
      index: true,
    },

    /// 🕒 TIMES
    deliveredAt: {
      type: Date,
      default: null,
    },

    seenAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true, // createdAt, updatedAt
  }
);

/// 🔥🔥🔥 INDEXES

/// chat fetch fast
messageSchema.index({ senderId: 1, receiverId: 1, createdAt: 1 });

/// unread count fast
messageSchema.index({ receiverId: 1, status: 1 });

/// reverse chat queries
messageSchema.index({ receiverId: 1, senderId: 1, createdAt: 1 });

/// 🔥 reply lookup optimization
messageSchema.index({ replyTo: 1 });

export default mongoose.model("Message", messageSchema);