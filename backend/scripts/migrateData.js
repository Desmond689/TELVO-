// scripts/migrateData.js
require('dotenv').config();
const { initializeFirebase, getFirestore } = require('../src/config/firebase');
const { logger } = require('../src/utils/logger');

const migrateData = async () => {
  try {
    initializeFirebase();
    const db = getFirestore();
    
    console.log('🔄 Starting data migration...');
    
    // Example migration: Add new field to all users
    const usersSnapshot = await db.collection('users').get();
    const batch = db.batch();
    
    usersSnapshot.docs.forEach((doc) => {
      const data = doc.data();
      if (!data.hasOwnProperty('isEmailVerified')) {
        batch.update(doc.ref, {
          isEmailVerified: false,
          updatedAt: new Date()
        });
      }
    });
    
    await batch.commit();
    console.log(`✅ Migrated ${usersSnapshot.docs.length} users`);
    
    console.log('🎉 Migration completed successfully!');
  } catch (error) {
    console.error('❌ Migration failed:', error);
  }
};

migrateData();