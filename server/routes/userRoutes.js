import express from "express";
import { setUsername, searchUsers } from "../controllers/userController.js";
import auth from "../middleware/authMiddleware.js";

const router = express.Router();

router.post("/username", auth, setUsername);
router.get("/search", auth, searchUsers);

export default router;