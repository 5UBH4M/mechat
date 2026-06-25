const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const express = require("express");
const crypto = require("crypto");
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const http = require("http");
const https = require("https");

// --- Firebase Service Account (prefer env var, fallback to file) ---
let serviceAccount;
if (process.env.FIREBASE_SERVICE_ACCOUNT) {
  serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
} else {
  try {
    serviceAccount = require('./serviceAccountKey.json');
    console.warn('[SECURITY] Using local serviceAccountKey.json — set FIREBASE_SERVICE_ACCOUNT env var in production');
  } catch (e) {
    console.error('FATAL: No Firebase credentials found. Set FIREBASE_SERVICE_ACCOUNT env var or provide serviceAccountKey.json');
    process.exit(1);
  }
}

// --- HTTP Server for Render Health Checks + Keep-Alive ---
const app = express();
const port = process.env.PORT || 3000;

app.use(helmet());

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(limiter);

app.get("/", (req, res) => {
  res.send("MeChat Standalone Backend is running!");
});

app.get("/health", (req, res) => {
  res.json({ status: "ok", uptime: process.uptime(), timestamp: new Date().toISOString() });
});

app.get("/ping", (req, res) => {
  res.send("pong");
});

const server = app.listen(port, () => {
  console.log(`Server listening on port ${port} (Required for Render Web Service)`);
  
  // Self-ping every 14 minutes to prevent Render free tier from sleeping
  // Render puts free services to sleep after 15 min of inactivity
  const RENDER_URL = process.env.RENDER_EXTERNAL_URL || `http://localhost:${port}`;
  setInterval(() => {
    const client = RENDER_URL.startsWith("https") ? https : http;
    client.get(`${RENDER_URL}/ping`, (res) => {
      console.log(`[Keep-Alive] Self-ping: ${res.statusCode}`);
    }).on("error", (err) => {
      console.error("[Keep-Alive] Self-ping failed:", err.message);
    });
  }, 14 * 60 * 1000); // Every 14 minutes
});
// --------------------------------------------------

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();
const messaging = getMessaging();

// Helper to decrypt the message text using the same logic as the Flutter app
function decryptMessage(encryptedText, chatId) {
  if (!encryptedText || typeof encryptedText !== 'string' || !encryptedText.includes(':')) {
    return "New message"; // Fallback if format is unexpected
  }
  
  try {
    const parts = encryptedText.split(':');
    const iv = Buffer.from(parts[0], 'base64');
    const ciphertext = Buffer.from(parts[1], 'base64');
    
    // Derive key using SHA-256 of the chatId (same as Flutter's _deriveKey)
    const key = crypto.createHash('sha256').update(chatId, 'utf8').digest();
    
    const decipher = crypto.createDecipheriv('aes-256-cbc', key, iv);
    // Disable auto padding because Flutter's encrypt package uses PKCS7 which OpenSSL handles,
    // but sometimes there are discrepancies. Usually auto padding is fine for AES-CBC.
    // Let's leave it default (true).
    
    let decrypted = decipher.update(ciphertext, undefined, 'utf8');
    decrypted += decipher.final('utf8');
    return decrypted;
  } catch (err) {
    console.error("Decryption error:", err);
    return "New message";
  }
}

// Per-user notification throttling (max 1 notification per user per 2 seconds)
const notificationThrottle = new Map();
function shouldThrottle(userId) {
  const now = Date.now();
  const lastSent = notificationThrottle.get(userId);
  if (lastSent && now - lastSent < 2000) return true;
  notificationThrottle.set(userId, now);
  // Clean up old entries every 1000 entries
  if (notificationThrottle.size > 1000) {
    for (const [key, time] of notificationThrottle) {
      if (now - time > 60000) notificationThrottle.delete(key);
    }
  }
  return false;
}

console.log("Listening for new messages and calls...");

// --- Graceful Shutdown ---
let messageUnsubscribe;
let callUnsubscribe;

// --- Listen to new messages ---
// Note: We use a collectionGroup query to listen to all messages across all chats
messageUnsubscribe = db.collectionGroup("messages").onSnapshot((snapshot) => {
  snapshot.docChanges().forEach(async (change) => {
    if (change.type === "added") {
      const message = change.doc.data();
      const chatId = change.doc.ref.parent.parent.id;

      // Input validation
      const idPattern = /^[a-zA-Z0-9_-]{1,128}$/;
      if (!message.receiverId || !idPattern.test(message.receiverId)) return;
      if (!message.senderId || !idPattern.test(message.senderId)) return;

      // We only care if it's a real message (not from notes_to_self)
      if (message.receiverId === message.senderId || message.receiverId === 'notes_to_self') {
        return;
      }

      // Check if this message was created very recently (within last 10 seconds)
      // to avoid sending notifications for old messages when the server starts
      const msgTime = message.timestamp ? message.timestamp.toDate() : new Date();
      if (new Date() - msgTime > 10000) return;

      const receiverDoc = await db.collection("users").doc(message.receiverId).get();
      if (!receiverDoc.exists) return;

      const pushToken = receiverDoc.data().pushToken;
      if (!pushToken) return;

      const hideSender = receiverDoc.data().hideNotificationSender === true;
      const hideMessage = receiverDoc.data().hideNotificationMessage === true;

      const senderDoc = await db.collection("users").doc(message.senderId).get();
      const senderName = senderDoc.exists && !hideSender ? senderDoc.data().displayName : "New Message";

      let body = '';
      if (!hideMessage) {
        if (message.type === 'text') {
          body = decryptMessage(message.content, chatId);
        } else if (message.type === 'location') {
          body = `📍 Shared a location`;
        } else if (message.type === 'contact') {
          body = `👤 Shared a contact`;
        } else if (['image', 'video', 'audio', 'document'].includes(message.type)) {
          body = `📸 Sent a ${message.type}`;
        } else {
          body = `📬 New message`;
        }
      } else {
        body = hideSender ? 'Open app to view message' : 'Sent a hidden message';
      }

      if (shouldThrottle(message.receiverId)) return;

      const payload = {
        token: pushToken,
        notification: {
          title: senderName,
          body: body,
        },
        data: {
          chatId: chatId,
          senderId: message.senderId,
          click_action: "FLUTTER_NOTIFICATION_CLICK"
        },
        android: {
          priority: 'high',
          notification: { channelId: 'mechat_channel', sound: 'default' }
        },
        apns: {
          payload: { aps: { sound: 'default' } }
        }
      };

      try {
        await messaging.send(payload);
        console.log(`[Message] Notification sent successfully`);
      } catch (error) {
        console.error("[Message] Error sending notification:", error);
      }
    }
  });
}, (error) => {
  console.error('[Message Listener] Firestore listener error:', error);
});

// --- Listen to new calls ---
callUnsubscribe = db.collection("calls").onSnapshot((snapshot) => {
  snapshot.docChanges().forEach(async (change) => {
    if (change.type === "added" || change.type === "modified") {
      const callData = change.doc.data();
      const callId = change.doc.id;

      // Input validation
      const idPattern = /^[a-zA-Z0-9_-]{1,128}$/;
      if (!callData.receiverId || !idPattern.test(callData.receiverId)) return;

      // Only notify when dialing and it's a new state
      if (callData.status !== 'dialing') return;

      // Similar to messages, avoid old calls
      const callTime = callData.timestamp ? callData.timestamp.toDate() : new Date();
      if (new Date() - callTime > 10000) return;

      const receiverDoc = await db.collection("users").doc(callData.receiverId).get();
      if (!receiverDoc.exists) return;

      const pushToken = receiverDoc.data().pushToken;
      if (!pushToken) return;

      const rawCallerName = callData.callerName || "Someone";
      const callerName = rawCallerName.replace(/[^a-zA-Z0-9 .'-]/g, '').substring(0, 50);
      const callType = (callData.type === 'video') ? 'Video' : 'Voice';

      if (shouldThrottle(callData.receiverId)) return;

      const payload = {
        token: pushToken,
        notification: {
          title: 'Incoming Call',
          body: `${callerName} is calling you (${callType})`,
        },
        data: {
          callId: callId,
          click_action: "FLUTTER_NOTIFICATION_CLICK"
        },
        android: {
          priority: 'high',
          notification: { channelId: 'mechat_channel', sound: 'default' }
        },
        apns: {
          payload: { aps: { sound: 'default', 'content-available': 1 } }
        }
      };

      try {
        await messaging.send(payload);
        console.log(`[Call] Notification sent successfully`);
      } catch (error) {
        console.error('[Call] Error sending notification:', error.message);
      }
    }
  });
}, (error) => {
  console.error('[Call Listener] Firestore listener error:', error);
});

// --- Graceful Shutdown Handlers ---
process.on('SIGTERM', () => {
  console.log('Received SIGTERM, shutting down gracefully...');
  if (messageUnsubscribe) messageUnsubscribe();
  if (callUnsubscribe) callUnsubscribe();
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('Received SIGINT, shutting down gracefully...');
  if (messageUnsubscribe) messageUnsubscribe();
  if (callUnsubscribe) callUnsubscribe();
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('[Unhandled Rejection]', reason);
});
