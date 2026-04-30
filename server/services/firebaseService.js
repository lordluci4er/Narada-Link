// services/firebaseService.js

import admin from "../config/firebase.js";

export const verifyFirebaseToken = async (token) => {
  try {
    const decoded = await admin.auth().verifyIdToken(token);

    return {
      uid: decoded.uid,
      email: decoded.email,
      picture: decoded.picture,
      name: decoded.name
    };

  } catch (error) {
    throw new Error("Invalid Firebase token");
  }
};