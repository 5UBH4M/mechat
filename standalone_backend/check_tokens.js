const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const serviceAccount = require("./serviceAccountKey.json");
initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();
async function check() {
  const usersRef = await db.collection("users").get();
  for (const doc of usersRef.docs) {
    console.log(doc.id, "=>", doc.data().pushToken);
  }
}
check();
