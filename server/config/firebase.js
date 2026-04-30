import admin from "firebase-admin";
import fs from "fs";

// 🔥 JSON file read + parse
const serviceAccount = JSON.parse(
  fs.readFileSync(new URL("./firebaseServiceAccount.json", import.meta.url))
);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

export default admin;