import admin from "firebase-admin";

let serviceAccount;

if (process.env.FIREBASE_SERVICE_ACCOUNT) {
  // 🔥 Render (production)
  serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
} else {
  // 💻 Local development
  const fs = await import("fs");
  serviceAccount = JSON.parse(
    fs.readFileSync(new URL("./firebaseServiceAccount.json", import.meta.url))
  );
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

export default admin;