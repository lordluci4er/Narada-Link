import express from "express";
import cors from "cors";

import authRoutes from "./routes/authRoutes.js";
import userRoutes from "./routes/userRoutes.js";
import messageRoutes from "./routes/messageRoutes.js";

const app = express();

/// 🔥 CORS (improved)
app.use(
  cors({
    origin: "*", // ⚠️ production me specific domain use karna
    methods: ["GET", "POST", "PUT", "DELETE"],
    credentials: true,
  })
);

/// 🔥 BODY PARSER
app.use(express.json());

/// 🔥 OPTIONAL: attach io middleware (safe access everywhere)
app.use((req, res, next) => {
  req.io = req.app.get("io"); // 🔥 now controller me direct use kar sakte ho
  next();
});

/// 🚀 ROUTES
app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/messages", messageRoutes);

/// 🏠 HEALTH CHECK
app.get("/", (req, res) => {
  res.send("Narada Link API running 🚀");
});

/// ❌ 404 HANDLER
app.use((req, res) => {
  res.status(404).json({
    msg: "Route not found",
    path: req.originalUrl,
  });
});

/// 💥 GLOBAL ERROR HANDLER
app.use((err, req, res, next) => {
  console.error("🔥 Global Error:", err.message);

  res.status(err.status || 500).json({
    msg: err.message || "Server error",
  });
});

export default app;