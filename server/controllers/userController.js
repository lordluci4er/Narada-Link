import User from "../models/User.js";
import { validateUsername } from "../utils/validators.js";

// 🔥 Set Username
export const setUsername = async (req, res) => {
  try {
    const { username } = req.body;

    // ❌ Missing
    if (!username) {
      return res.status(400).json({ msg: "Username required" });
    }

    // 🔤 Normalize
    const clean = username.toLowerCase().trim();

    // ✅ Validation (external + fallback)
    const error = validateUsername ? validateUsername(clean) : null;
    if (error) {
      return res.status(400).json({ msg: error });
    }

    // 🔒 Ensure user exists
    const currentUser = await User.findById(req.user.id);
    if (!currentUser) {
      return res.status(404).json({ msg: "User not found" });
    }

    // ❌ Prevent changing username again (optional but recommended)
    if (currentUser.username) {
      return res.status(400).json({
        msg: "Username already set. Cannot change."
      });
    }

    // ⚡ ATOMIC update (race-condition safe)
    const updated = await User.findOneAndUpdate(
      {
        _id: req.user.id,
        username: { $in: [null, ""] } // only if not set
      },
      { $set: { username: clean } },
      { new: true }
    ).select("-__v");

    if (!updated) {
      return res.status(400).json({
        msg: "Username already set or conflict occurred"
      });
    }

    res.json({ user: updated });

  } catch (err) {
    console.error("Set Username Error:", err);
    res.status(500).json({ msg: "Server error" });
  }
};


// 🔍 Search Users
export const searchUsers = async (req, res) => {
  try {
    const { username } = req.query;

    if (!username) {
      return res.status(400).json({ msg: "Search query required" });
    }

    const clean = username.toLowerCase().trim();

    const users = await User.find({
      username: { $regex: clean, $options: "i" }
    })
      .select("username avatar email") // 🔥 optimized
      .limit(20);

    res.json(users);

  } catch (err) {
    console.error("Search Error:", err);
    res.status(500).json({ msg: "Server error" });
  }
};