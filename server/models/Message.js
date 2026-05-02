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

    /// 💬 MESSAGE TEXT
    text: {
      type: String,
      default: "",
      trim: true,
    },

    /// 👁️ QUICK FLAG (optional but useful for queries)
    seen: {
      type: Boolean,
      default: false,
    },

    /// 🔥 STATUS SYSTEM (MAIN LOGIC)
    status: {
      type: String,
      enum: ["sent", "delivered", "seen"],
      default: "sent",
      index: true,
    },

    /// 🕒 DELIVERY TIME
    deliveredAt: {
      type: Date,
      default: null,
    },

    /// 🕒 SEEN TIME
    seenAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true, // createdAt, updatedAt
  }
);

export default mongoose.model("Message", messageSchema);