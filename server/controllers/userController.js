import User from "../models/User.js";
import { validateUsername } from "../utils/validators.js";

/// 🔥 SET USERNAME + NAME
export const setUsername = async (req, res) => {
  try {
    const userId = req.user?.id || req.user;
    const { name, username } = req.body;

    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({ msg: "User not found" });
    }

    /// 🔥 NAME UPDATE
    if (name && name.trim().length >= 2) {
      user.name = name.trim();
    }

    /// 🔥 USERNAME UPDATE
    if (username) {
      const clean = username.toLowerCase().trim();

      const error = validateUsername
        ? validateUsername(clean)
        : null;

      if (error) {
        return res.status(400).json({ msg: error });
      }

      if (user.username) {
        return res.status(400).json({
          msg: "Username already set",
        });
      }

      const exists = await User.findOne({ username: clean });

      if (exists) {
        return res.status(400).json({
          msg: "Username already taken",
        });
      }

      user.username = clean;
    }

    await user.save();

    /// 🔥 SOCKET EMIT
    const io = req.app.get("io");

    io.emit("userUpdated", {
      userId: user._id,
      name: user.name,
      avatar: user.avatar,
    });

    res.json({
      msg: "Updated",
      user: {
        ...user._doc,
        name: user.name || "Narada Link User",
      },
    });

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

    const updatedUser = await User.findByIdAndUpdate(
      userId,
      { name: name.trim() },
      { new: true }
    );

    if (!updatedUser) {
      return res.status(404).json({ msg: "User not found" });
    }

    const io = req.app.get("io");

    io.emit("userUpdated", {
      userId: updatedUser._id,
      name: updatedUser.name,
    });

    res.json({
      ...updatedUser._doc,
      name: updatedUser.name || "Narada Link User",
    });

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

    const updatedUser = await User.findByIdAndUpdate(
      userId,
      updateData,
      { new: true }
    );

    if (!updatedUser) {
      return res.status(404).json({ msg: "User not found" });
    }

    const io = req.app.get("io");

    io.emit("userUpdated", {
      userId: updatedUser._id,
      name: updatedUser.name,
      avatar: updatedUser.avatar,
    });

    res.json({
      ...updatedUser._doc,
      name: updatedUser.name || "Narada Link User",
    });

  } catch (err) {
    console.error("Update Profile Error:", err);
    res.status(500).json({ msg: "Profile update failed" });
  }
};


/// 🔍 SEARCH USERS
export const searchUsers = async (req, res) => {
  try {
    const query = (req.query.username || "").toLowerCase().trim();

    if (!query) {
      return res.json([]);
    }

    const userId = req.user?.id || req.user;

    const users = await User.find({
      username: { $regex: query, $options: "i" },
      _id: { $ne: userId },
    })
      .select("name username avatar isOnline lastSeen")
      .limit(20);

    const result = users.map((u) => ({
      _id: u._id,
      name:
        u.name && u.name.trim() !== ""
          ? u.name
          : "Narada Link User",
      username: u.username || "",
      avatar: u.avatar || null,
      isOnline: u.isOnline || false,
      lastSeen: u.lastSeen || null,
    }));

    res.json(result);

  } catch (err) {
    console.error("Search Error:", err);
    res.status(500).json({ msg: "Server error" });
  }
};


/// 👤 GET CURRENT USER
export const getMe = async (req, res) => {
  try {
    const userId = req.user?.id || req.user;

    const user = await User.findById(userId);

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

    res.json({ msg: "Token saved" });

  } catch (err) {
    console.error("FCM Save Error:", err);
    res.status(500).json({ msg: "Error saving token" });
  }
};


/// 🟢 GET USER STATUS (🔥 NEW)
export const getUserStatus = async (req, res) => {
  try {
    const user = await User.findById(req.params.userId)
      .select("isOnline lastSeen");

    if (!user) {
      return res.status(404).json({ msg: "User not found" });
    }

    res.json({
      isOnline: user.isOnline,
      lastSeen: user.lastSeen,
    });

  } catch (err) {
    console.error("User Status Error:", err);
    res.status(500).json({ msg: "Server error" });
  }
};