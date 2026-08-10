// scripts/seedDatabase.js
require('dotenv').config();
const { initializeFirebase, getFirestore } = require('../src/config/firebase');
const { logger } = require('../src/utils/logger');

const seedDatabase = async () => {
  try {
    initializeFirebase();
    const db = getFirestore();
    
    console.log('🌱 Seeding database...');
    
    // Create sample categories
    const categories = [
      'Plumber', 'Electrician', 'Cleaner', 'Painter', 
      'Carpenter', 'Mechanic', 'Gardener', 'Tutor',
      'Photographer', 'Chef', 'Babysitter', 'Nanny'
    ];
    
    for (const category of categories) {
      await db.collection('categories').add({
        name: category,
        createdAt: new Date(),
        updatedAt: new Date(),
        isActive: true
      });
      console.log(`✅ Created category: ${category}`);
    }
    
    // Create sample admin
    await db.collection('admins').add({
      email: 'admin@telvo.com',
      fullName: 'Super Admin',
      role: 'super_admin',
      permissions: ['*'],
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date()
    });
    
    console.log('✅ Created admin user');
    
    // Create sample user
    await db.collection('users').add({
      phoneNumber: '+237670123456',
      email: 'user@telvo.com',
      fullName: 'John Doe',
      userType: 'customer',
      isVerified: true,
      isPhoneVerified: true,
      createdAt: new Date(),
      updatedAt: new Date()
    });
    
    console.log('✅ Created sample user');
    
    console.log('🎉 Database seeded successfully!');
  } catch (error) {
    console.error('❌ Seeding failed:', error);
  }
};

seedDatabase();