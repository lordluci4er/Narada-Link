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
      sparse: true,   // 🔥 allows multiple null usernames
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
    },
  },
  { timestamps: true }
);

export default mongoose.model("User", userSchema);