const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const express = require("express");

// NOTE: You must generate a private key from your Firebase Console
// (Project Settings -> Service Accounts -> Generate New Private Key)
// Place the downloaded JSON file in this folder and rename it to 'serviceAccountKey.json'
const serviceAccount = require("./serviceAccountKey.json");

// --- Dummy HTTP Server for Render Health Checks ---
const app = express();
const port = process.env.PORT || 3000;

app.get("/", (req, res) => {
  res.send("MeChat Standalone Backend is running!");
});

app.listen(port, () => {
  console.log(`Server listening on port ${port} (Required for Render Web Service)`);
});
// --------------------------------------------------

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();
const messaging = getMessaging();

console.log("Listening for new messages and calls...");

// --- Listen to new messages ---
// Note: We use a collectionGroup query to listen to all messages across all chats
db.collectionGroup("messages").onSnapshot((snapshot) => {
  snapshot.docChanges().forEach(async (change) => {
    if (change.type === "added") {
      const message = change.doc.data();
      const chatId = change.doc.ref.parent.parent.id;

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

      const senderDoc = await db.collection("users").doc(message.senderId).get();
      const senderName = senderDoc.exists ? senderDoc.data().displayName : "Someone";

      let body = message.type === 'text' ? message.content : `📸 Sent a ${message.type}`;
      if (message.type === 'location') body = `📍 Shared a location`;
      if (message.type === 'contact') body = `👤 Shared a contact`;

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
        console.log(`[Message] Notification sent to ${message.receiverId}`);
      } catch (error) {
        console.error("[Message] Error sending notification:", error);
      }
    }
  });
});

// --- Listen to new calls ---
db.collection("calls").onSnapshot((snapshot) => {
  snapshot.docChanges().forEach(async (change) => {
    if (change.type === "added" || change.type === "modified") {
      const callData = change.doc.data();
      const callId = change.doc.id;

      // Only notify when dialing and it's a new state
      if (callData.status !== 'dialing') return;

      // Similar to messages, avoid old calls
      const callTime = callData.timestamp ? callData.timestamp.toDate() : new Date();
      if (new Date() - callTime > 10000) return;

      const receiverDoc = await db.collection("users").doc(callData.receiverId).get();
      if (!receiverDoc.exists) return;

      const pushToken = receiverDoc.data().pushToken;
      if (!pushToken) return;

      const callerName = callData.callerName || "Someone";
      const callType = callData.type === 'video' ? 'Video' : 'Voice';

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
        console.log(`[Call] Notification sent to ${callData.receiverId}`);
      } catch (error) {
        // Ignored if duplicate or invalid
      }
    }
  });
});
