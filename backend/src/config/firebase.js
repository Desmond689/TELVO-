// src/config/firebase.js
const admin = require('firebase-admin');
const { getFirestore } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { getAuth } = require('firebase-admin/auth');
const { getMessaging } = require('firebase-admin/messaging');
const { logger } = require('../utils/logger');

let firestore;
let storage;
let auth;
let messaging;

const initializeFirebase = () => {
  if (!admin.apps.length) {
    try {
      // Check if we're using service account or default credentials
      let credential;
      
      if (process.env.FIREBASE_PRIVATE_KEY && process.env.FIREBASE_PROJECT_ID) {
        // Using service account from environment variables
        credential = admin.credential.cert({
          projectId: process.env.FIREBASE_PROJECT_ID,
          privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        });
      } else {
        // Using default credentials (for local development with ADC)
        credential = admin.credential.applicationDefault();
      }

      admin.initializeApp({
        credential: credential,
        databaseURL: process.env.FIREBASE_DATABASE_URL,
        storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
      });

      firestore = getFirestore();
      storage = getStorage();
      auth = getAuth();
      messaging = getMessaging();

      logger.info('🔥 Firebase initialized successfully');
    } catch (error) {
      logger.error('Firebase initialization error:', error);
      throw error;
    }
  }
};

const getFirestoreInstance = () => {
  if (!firestore) {
    throw new Error('Firestore not initialized. Call initializeFirebase first.');
  }
  return firestore;
};

const getStorageInstance = () => {
  if (!storage) {
    throw new Error('Storage not initialized. Call initializeFirebase first.');
  }
  return storage;
};

const getAuthInstance = () => {
  if (!auth) {
    throw new Error('Auth not initialized. Call initializeFirebase first.');
  }
  return auth;
};

const getMessagingInstance = () => {
  if (!messaging) {
    throw new Error('Messaging not initialized. Call initializeFirebase first.');
  }
  return messaging;
};

module.exports = {
  initializeFirebase,
  admin,
  getFirestore: getFirestoreInstance,
  getStorage: getStorageInstance,
  getAuth: getAuthInstance,
  getMessaging: getMessagingInstance,
};