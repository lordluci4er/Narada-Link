import User from "../models/User.js";
import { validateUsername } from "../utils/validators.js";

// 🔥 Set Username
export const setUsername = async (req, res) => {
  try {
    const { username } = req.body;

    // ✅ Validation
    const error = validateUsername(username);
    if (error) {
      return res.status(400).json({ msg: error });
    }

    // ✅ Check if username already exists
    const exists = await User.findOne({ username });
    if (exists) {
      return res.status(400).json({ msg: "Username already taken" });
    }

    // ✅ Update current user
    const user = await User.findByIdAndUpdate(
      req.user,
      { username },
      { new: true }
    ).select("-__v");

    res.json(user);

  } catch (err) {
    res.status(500).json({ msg: "Server error" });
  }
};


// 🔍 Search Users
export const searchUsers = async (req, res) => {
  try {
    const { username } = req.query;

    // ❗ Agar empty search ho
    if (!username) {
      return res.status(400).json({ msg: "Search query required" });
    }

    const users = await User.find({
      username: { $regex: username, $options: "i" }
    })
      .select("-__v")
      .limit(20); // 🔥 limit laga diya performance ke liye

    res.json(users);

  } catch (err) {
    res.status(500).json({ msg: "Server error" });
  }
};