// scripts/backupDatabase.js
require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { initializeFirebase, getFirestore } = require('../src/config/firebase');
const { logger } = require('../src/utils/logger');

const backupDatabase = async () => {
  try {
    initializeFirebase();
    const db = getFirestore();
    
    console.log('💾 Starting database backup...');
    
    const collections = ['users', 'jobs', 'payments', 'reviews', 'admins'];
    const backup = {};
    
    for (const collection of collections) {
      const snapshot = await db.collection(collection).get();
      backup[collection] = [];
      snapshot.docs.forEach((doc) => {
        backup[collection].push({
          id: doc.id,
          ...doc.data()
        });
      });
      console.log(`✅ Backed up ${collection}: ${snapshot.docs.length} documents`);
    }
    
    // Save backup to file
    const backupDir = path.join(__dirname, '../backups');
    if (!fs.existsSync(backupDir)) {
      fs.mkdirSync(backupDir, { recursive: true });
    }
    
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const filename = `backup-${timestamp}.json`;
    const filepath = path.join(backupDir, filename);
    
    fs.writeFileSync(filepath, JSON.stringify(backup, null, 2));
    
    console.log(`🎉 Backup saved to: ${filepath}`);
  } catch (error) {
    console.error('❌ Backup failed:', error);
  }
};

backupDatabase();