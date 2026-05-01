import jwt from "jsonwebtoken";

const authMiddleware = (req, res, next) => {
  const authHeader = req.headers.authorization;

  // 🔍 Check header exists
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ msg: "No token provided" });
  }

  try {
    // 🔑 Extract token safely
    const token = authHeader.split(" ")[1];

    // 🔐 Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // ✅ BEST PRACTICE: normalize user id
    req.user = {
      id: decoded.id, // 🔥 consistent everywhere
    };

    next();
  } catch (error) {
    console.error("❌ Token Error:", error.message);
    return res.status(401).json({ msg: "Invalid or expired token" });
  }
};

export default authMiddleware;