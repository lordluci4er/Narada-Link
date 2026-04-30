// utils/validators.js

export const validateUsername = (username) => {
  if (!username) return "Username is required";

  if (username.length < 3 || username.length > 20) {
    return "Username must be 3–20 characters";
  }

  const regex = /^[a-zA-Z0-9_]+$/;
  if (!regex.test(username)) {
    return "Username can only contain letters, numbers, and underscore";
  }

  return null;
};


export const validateMessage = (message) => {
  if (!message) return "Message cannot be empty";

  if (message.length > 1000) {
    return "Message too long (max 1000 characters)";
  }

  return null;
};