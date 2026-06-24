const crypto = require("crypto");

function decryptMessage(encryptedText, chatId) {
  if (!encryptedText || typeof encryptedText !== 'string' || !encryptedText.includes(':')) {
    return "New message (no colon)";
  }
  
  try {
    const parts = encryptedText.split(':');
    const iv = Buffer.from(parts[0], 'base64');
    const ciphertext = Buffer.from(parts[1], 'base64');
    
    const key = crypto.createHash('sha256').update(chatId, 'utf8').digest();
    
    const decipher = crypto.createDecipheriv('aes-256-cbc', key, iv);
    
    let decrypted = decipher.update(ciphertext, undefined, 'utf8');
    decrypted += decipher.final('utf8');
    return decrypted;
  } catch (err) {
    return "New message (error: " + err.message + ")";
  }
}

// Simulated data
const chatId = "user1_user2";
const text = "Hello World!";
const key = crypto.createHash('sha256').update(chatId, 'utf8').digest();
const iv = crypto.randomBytes(16);
const cipher = crypto.createCipheriv('aes-256-cbc', key, iv);
let encrypted = cipher.update(text, 'utf8', 'base64');
encrypted += cipher.final('base64');
const combined = iv.toString('base64') + ':' + encrypted;

console.log("Original:", text);
console.log("Encrypted:", combined);
console.log("Decrypted:", decryptMessage(combined, chatId));
