import User from "../models/User.js";
import generateToken from "../utils/generateToken.js";
import { verifyFirebaseToken } from "../services/firebaseService.js";

export const googleAuth = async (req, res) => {
  try {
    const { token } = req.body;

    // ❗ Token check
    if (!token) {
      return res.status(400).json({ msg: "Token is required" });
    }

    // 🔐 Verify Firebase token
    const decoded = await verifyFirebaseToken(token);

    // 🔍 Find existing user
    let user = await User.findOne({ googleId: decoded.uid });

    // 🆕 Create new user if not exists
    if (!user) {
      user = await User.create({
        googleId: decoded.uid,
        email: decoded.email,
        avatar: decoded.picture,
      });
    }

    // 🔑 Generate JWT
    const jwtToken = generateToken(user);

    res.json({
      user,
      token: jwtToken,
    });

  } catch (err) {
    res.status(401).json({
      msg: err.message || "Authentication failed",
    });
  }
};