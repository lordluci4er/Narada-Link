import express from "express";
import cors from "cors";

import authRoutes from "./routes/authRoutes.js";
import userRoutes from "./routes/userRoutes.js";
import messageRoutes from "./routes/messageRoutes.js";

const app = express();

// 🔥 Middlewares
app.use(cors({
  origin: "*", // ⚠️ production me specific domain use karna
  methods: ["GET", "POST", "PUT", "DELETE"],
  credentials: true,
}));

app.use(express.json());

// 🚀 API Routes
app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/messages", messageRoutes); // ✅ messages connected

// 🏠 Health check route
app.get("/", (req, res) => {
  res.send("Narada Link API running 🚀");
});

// ❌ 404 Handler
app.use((req, res) => {
  res.status(404).json({
    msg: "Route not found",
    path: req.originalUrl, // 🔥 helpful debug
  });
});

// 💥 Global Error Handler
app.use((err, req, res, next) => {
  console.error("🔥 Global Error:", err.message);

  res.status(err.status || 500).json({
    msg: err.message || "Server error",
  });
});

export default app;