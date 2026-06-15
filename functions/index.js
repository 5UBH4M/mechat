const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendPushNotificationOnNewMessage = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const message = snap.data();
    
    // We only care if it's a real message (not from notes_to_self)
    if (message.receiverId === message.senderId || message.receiverId === 'notes_to_self') {
      return;
    }

    // Get the receiver's user document to find their push token
    const receiverDoc = await admin.firestore().collection("users").doc(message.receiverId).get();
    if (!receiverDoc.exists) return;

    const receiverData = receiverDoc.data();
    const pushToken = receiverData.pushToken;

    if (!pushToken) {
      console.log(`No push token for user ${message.receiverId}`);
      return;
    }

    // Get sender's details for the notification title
    const senderDoc = await admin.firestore().collection("users").doc(message.senderId).get();
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
        chatId: event.params.chatId,
        senderId: message.senderId,
        click_action: "FLUTTER_NOTIFICATION_CLICK"
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'mechat_channel',
          sound: 'default'
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default'
          }
        }
      }
    };

    try {
      await admin.messaging().send(payload);
      console.log("Successfully sent push notification to", message.receiverId);
    } catch (error) {
      console.error("Error sending push notification:", error);
    }
  }
);

exports.sendPushNotificationOnNewCall = onDocumentCreated(
  "calls/{callId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const callData = snap.data();
    
    if (callData.status !== 'dialing') return;

    const receiverDoc = await admin.firestore().collection("users").doc(callData.receiverId).get();
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
        callId: event.params.callId,
        click_action: "FLUTTER_NOTIFICATION_CLICK"
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'mechat_channel',
          sound: 'default'
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            'content-available': 1
          }
        }
      }
    };

    try {
      await admin.messaging().send(payload);
    } catch (error) {
      console.error("Error sending call notification:", error);
    }
  }
);
