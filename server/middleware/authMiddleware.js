import jwt from "jsonwebtoken";

const authMiddleware = (req, res, next) => {
  const authHeader = req.headers.authorization;

  // 🔍 Check header exists
  if (!authHeader) {
    return res.status(401).json({ msg: "No token provided" });
  }

  // 🔍 Extract token
  const token = authHeader.split(" ")[1];

  if (!token) {
    return res.status(401).json({ msg: "Invalid token format" });
  }

  try {
    // 🔐 Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // ✅ FIX: store full object (NOT just id)
    req.user = decoded;

    // 🧪 Debug (optional)
    console.log("✅ Authenticated User:", req.user);

    next();
  } catch (error) {
    console.error("❌ Token Error:", error.message);
    return res.status(401).json({ msg: "Invalid or expired token" });
  }
};

export default authMiddleware;