import admin from "firebase-admin";

let serviceAccount;

try {
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    console.log("🔥 Using Firebase ENV config");

    serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  } else {
    console.log("💻 Using local Firebase JSON file");

    const fs = await import("fs");

    serviceAccount = JSON.parse(
      fs.readFileSync(new URL("./firebaseServiceAccount.json", import.meta.url))
    );
  }

  // 🔍 Important debug check
  if (!serviceAccount.project_id) {
    throw new Error("Invalid Firebase JSON (project_id missing)");
  }

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });

  console.log("✅ Firebase initialized successfully");

} catch (error) {
  console.error("🔥 Firebase Init Error:", error.message);
  process.exit(1); // server crash (intentional for debug)
}

export default admin;