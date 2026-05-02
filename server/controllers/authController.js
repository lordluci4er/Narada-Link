import User from "../models/User.js";
import generateToken from "../utils/generateToken.js";
import { verifyFirebaseToken } from "../services/firebaseService.js";

export const googleAuth = async (req, res) => {
  try {
    console.log("🚀 Google Auth API Hit");

    const { token } = req.body;

    /// ❗ Token check
    if (!token) {
      console.log("❌ No token received");
      return res.status(400).json({ msg: "Token is required" });
    }

    console.log("📦 Firebase Token Received");

    /// 🔐 Verify Firebase token
    let decoded;
    try {
      decoded = await verifyFirebaseToken(token);
      console.log("✅ Firebase Token Verified:", decoded.uid);
    } catch (error) {
      console.log("🔥 Firebase Verification Error:", error.message);
      return res.status(401).json({
        msg: "Invalid Firebase token",
        error: error.message,
      });
    }

    /// 🔍 Find existing user
    let user = await User.findOne({ googleId: decoded.uid });

    if (user) {
      console.log("👤 Existing user found");

      /// 🔥 FIX: ensure name exists for old users
      if (!user.name || user.name.trim() === "") {
        user.name = "Narada Link User";
        await user.save();
        console.log("🛠️ Default name applied to existing user");
      }
    }

    /// 🆕 Create new user if not exists
    if (!user) {
      console.log("🆕 Creating new user");

      user = await User.create({
        googleId: decoded.uid,
        email: decoded.email,
        avatar: decoded.picture,

        /// 🔥 IMPORTANT DEFAULT
        name: "Narada Link User",
      });
    }

    /// 🔑 Generate JWT
    const jwtToken = generateToken(user);

    console.log("🔐 JWT Generated");

    res.json({
      user,
      token: jwtToken,
    });

  } catch (err) {
    console.log("❌ Auth Controller Error:", err);

    res.status(401).json({
      msg: err.message || "Authentication failed",
    });
  }
};