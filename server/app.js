import express from "express";
import cors from "cors";

import authRoutes from "./routes/authRoutes.js";
import userRoutes from "./routes/userRoutes.js";
import messageRoutes from "./routes/messageRoutes.js";

const app = express();

// 🔥 Middlewares
app.use(cors({
  origin: "*", // production me specific domain rakhna
}));
app.use(express.json());

// 🚀 API Routes
app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);     // ✅ username + search
app.use("/api/messages", messageRoutes);

// 🏠 Health check route
app.get("/", (req, res) => {
  res.send("Narada Link API running 🚀");
});

// ❌ 404 Handler (important)
app.use((req, res) => {
  res.status(404).json({ msg: "Route not found" });
});

// 💥 Global Error Handler
app.use((err, req, res, next) => {
  console.error("Global Error:", err);
  res.status(500).json({ msg: "Server error" });
});

export default app;