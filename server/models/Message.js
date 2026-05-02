import mongoose from "mongoose";

const messageSchema = new mongoose.Schema(
  {
    senderId: {
      type: String,
      required: true,
    },

    receiverId: {
      type: String,
      required: true,
    },

    text: {
      type: String,
      default: "",
    },

    /// 👁️ BASIC READ FLAG (quick check)
    seen: {
      type: Boolean,
      default: false,
    },

    /// 🔥 MESSAGE STATUS (WhatsApp style)
    status: {
      type: String,
      enum: ["sent", "delivered", "seen"],
      default: "sent",
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
    timestamps: true,
  }
);

export default mongoose.model("Message", messageSchema);