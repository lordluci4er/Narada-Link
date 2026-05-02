import User from "../models/User.js";
import { validateUsername } from "../utils/validators.js";

/// 🔥 SET USERNAME
export const setUsername = async (req, res) => {
  try {
    const { username } = req.body;

    if (!username) {
      return res.status(400).json({ msg: "Username required" });
    }

    const clean = username.toLowerCase().trim();

    const error = validateUsername ? validateUsername(clean) : null;
    if (error) {
      return res.status(400).json({ msg: error });
    }

    const userId = req.user?.id || req.user;

    const currentUser = await User.findById(userId);
    if (!currentUser) {
      return res.status(404).json({ msg: "User not found" });
    }

    /// ❌ prevent change
    if (currentUser.username) {
      return res.status(400).json({
        msg: "Username already set. Cannot change.",
      });
    }

    const updated = await User.findOneAndUpdate(
      {
        _id: userId,
        username: { $in: [null, ""] },
      },
      { $set: { username: clean } },
      { new: true }
    ).select("-__v");

    if (!updated) {
      return res.status(400).json({
        msg: "Username already set or conflict occurred",
      });
    }

    res.json({ user: updated });

  } catch (err) {
    console.error("Set Username Error:", err);
    res.status(500).json({ msg: "Server error" });
  }
};


/// 🔥 SET NAME
export const setName = async (req, res) => {
  try {
    const userId = req.user?.id || req.user;
    const { name } = req.body;

    if (!name || name.trim().length < 2) {
      return res.status(400).json({ msg: "Valid name required" });
    }

    const updated = await User.findByIdAndUpdate(
      userId,
      { name: name.trim() },
      { new: true }
    ).select("-__v");

    res.json(updated);

  } catch (err) {
    console.error("Set Name Error:", err);
    res.status(500).json({ msg: "Error setting name" });
  }
};


/// 🔥 UPDATE PROFILE
export const updateProfile = async (req, res) => {
  try {
    const userId = req.user?.id || req.user;
    const { name, avatar } = req.body;

    const updateData = {};

    if (name && name.trim().length >= 2) {
      updateData.name = name.trim();
    }

    if (avatar && avatar.trim().length > 0) {
      updateData.avatar = avatar.trim();
    }

    const updated = await User.findByIdAndUpdate(
      userId,
      updateData,
      { new: true }
    ).select("-__v");

    res.json(updated);

  } catch (err) {
    console.error("Update Profile Error:", err);
    res.status(500).json({ msg: "Profile update failed" });
  }
};


/// 🔍 SEARCH USERS (🔥 DEFAULT NAME FIX)
export const searchUsers = async (req, res) => {
  try {
    const { username } = req.query;

    if (!username) {
      return res.status(400).json({ msg: "Search query required" });
    }

    const clean = username.toLowerCase().trim();
    const userId = req.user?.id || req.user;

    const users = await User.find({
      username: { $regex: clean, $options: "i" },
      _id: { $ne: userId },
    })
      .select("username name avatar")
      .limit(20);

    /// 🔥 DEFAULT NAME FIX
    const safeUsers = users.map((u) => ({
      ...u._doc,
      name: u.name || "Narada Link User",
    }));

    res.json(safeUsers);

  } catch (err) {
    console.error("Search Error:", err);
    res.status(500).json({ msg: "Server error" });
  }
};


/// 👤 GET CURRENT USER (🔥 SAFE RETURN)
export const getMe = async (req, res) => {
  try {
    const userId = req.user?.id || req.user;

    const user = await User.findById(userId).select("-__v");

    if (!user) {
      return res.status(404).json({ msg: "User not found" });
    }

    res.json({
      ...user._doc,
      name: user.name || "Narada Link User",
    });

  } catch (error) {
    console.log("❌ getMe error:", error.message);
    res.status(500).json({ msg: "Server error" });
  }
};


/// 🔔 SAVE FCM TOKEN
export const saveFcmToken = async (req, res) => {
  try {
    const userId = req.user?.id || req.user;
    const { token } = req.body;

    if (!token) {
      return res.status(400).json({ msg: "FCM token required" });
    }

    await User.findByIdAndUpdate(userId, {
      fcmToken: token,
    });

    console.log("🔔 FCM token saved for user:", userId);

    res.json({ msg: "Token saved" });

  } catch (err) {
    console.error("FCM Save Error:", err);
    res.status(500).json({ msg: "Error saving token" });
  }
};