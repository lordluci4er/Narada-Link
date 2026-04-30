import admin from "firebase-admin";

// 🔥 ENV se JSON read kar
const serviceAccount = JSON.parse(
  process.env.FIREBASE_SERVICE_ACCOUNT
);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

export default admin;