const admin = require('firebase-admin');

let db = null;
let auth = null;

function initFirebase() {
  if (admin.apps.length === 0) {
    const serviceAccount = {
      projectId: process.env.FIREBASE_PROJECT_ID,
      privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    };

    if (process.env.NODE_ENV === 'development' && !process.env.FIREBASE_PRIVATE_KEY) {
      admin.initializeApp({
        projectId: process.env.FIREBASE_PROJECT_ID,
      });
      console.log('Firebase initialized in development mode (emulator)');
    } else {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      console.log('Firebase initialized with service account');
    }
  }

  db = admin.firestore();
  auth = admin.auth();
  return { admin, db, auth };
}

function getDb() {
  if (!db) initFirebase();
  return db;
}

function getAuth() {
  if (!auth) initFirebase();
  return auth;
}

module.exports = { initFirebase, getDb, getAuth, admin };
