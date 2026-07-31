// src/config/database.js
const { getFirestore } = require('./firebase');
const { logger } = require('../utils/logger');

const db = getFirestore();

// Database collections
const COLLECTIONS = {
  USERS: 'users',
  JOBS: 'jobs',
  PAYMENTS: 'payments',
  CHATS: 'chats',
  MESSAGES: 'messages',
  REVIEWS: 'reviews',
  NOTIFICATIONS: 'notifications',
  ADMINS: 'admins',
  WALLETS: 'wallets',
  DISPUTES: 'disputes',
  FRAUD_REPORTS: 'fraud_reports',
  PROMOTIONS: 'promotions',
  CATEGORIES: 'categories',
};

// Helper functions
const getCollection = (collectionName) => {
  return db.collection(collectionName);
};

const getDocument = (collectionName, docId) => {
  return db.collection(collectionName).doc(docId);
};

const createDocument = async (collectionName, data) => {
  try {
    const docRef = db.collection(collectionName).doc();
    await docRef.set({
      ...data,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    return { id: docRef.id, ...data };
  } catch (error) {
    logger.error(`Error creating document in ${collectionName}:`, error);
    throw error;
  }
};

const updateDocument = async (collectionName, docId, data) => {
  try {
    await db.collection(collectionName).doc(docId).update({
      ...data,
      updatedAt: new Date(),
    });
    return { id: docId, ...data };
  } catch (error) {
    logger.error(`Error updating document in ${collectionName}:`, error);
    throw error;
  }
};

const deleteDocument = async (collectionName, docId) => {
  try {
    await db.collection(collectionName).doc(docId).delete();
    return true;
  } catch (error) {
    logger.error(`Error deleting document from ${collectionName}:`, error);
    throw error;
  }
};

const getDocumentById = async (collectionName, docId) => {
  try {
    const doc = await db.collection(collectionName).doc(docId).get();
    if (!doc.exists) {
      return null;
    }
    return { id: doc.id, ...doc.data() };
  } catch (error) {
    logger.error(`Error getting document from ${collectionName}:`, error);
    throw error;
  }
};

const queryDocuments = async (collectionName, conditions = [], orderBy = null) => {
  try {
    let query = db.collection(collectionName);
    
    for (const condition of conditions) {
      query = query.where(condition.field, condition.operator, condition.value);
    }
    
    if (orderBy) {
      query = query.orderBy(orderBy.field, orderBy.direction || 'asc');
    }
    
    const snapshot = await query.get();
    const documents = [];
    snapshot.forEach((doc) => {
      documents.push({ id: doc.id, ...doc.data() });
    });
    return documents;
  } catch (error) {
    logger.error(`Error querying documents from ${collectionName}:`, error);
    throw error;
  }
};

const batchWrite = async (operations) => {
  const batch = db.batch();
  for (const op of operations) {
    const ref = db.collection(op.collection).doc(op.id);
    if (op.type === 'set') {
      batch.set(ref, op.data);
    } else if (op.type === 'update') {
      batch.update(ref, op.data);
    } else if (op.type === 'delete') {
      batch.delete(ref);
    }
  }
  await batch.commit();
};

module.exports = {
  db,
  COLLECTIONS,
  getCollection,
  getDocument,
  createDocument,
  updateDocument,
  deleteDocument,
  getDocumentById,
  queryDocuments,
  batchWrite,
};