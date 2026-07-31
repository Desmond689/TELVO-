// src/models/Admin.js
const {
  getDocumentById,
  createDocument,
  updateDocument,
  queryDocuments,
  COLLECTIONS,
} = require('../config/database');

class Admin {
  constructor(data) {
    this.id = data.id;
    this.userId = data.userId; // Firebase Auth uid of the admin account
    this.email = data.email;
    this.fullName = data.fullName;
    this.role = data.role || 'admin'; // 'admin' | 'super_admin'
    this.permissions = data.permissions || [];
    this.isActive = data.isActive !== undefined ? data.isActive : true;
    this.createdAt = data.createdAt || new Date();
    this.lastLogin = data.lastLogin || null;
  }

  static async findById(id) {
    const data = await getDocumentById(COLLECTIONS.ADMINS, id);
    return data ? new Admin(data) : null;
  }

  static async findByUserId(userId) {
    const results = await queryDocuments(COLLECTIONS.ADMINS, [
      { field: 'userId', operator: '==', value: userId },
    ]);
    return results.length > 0 ? new Admin(results[0]) : null;
  }

  static async findByEmail(email) {
    const results = await queryDocuments(COLLECTIONS.ADMINS, [
      { field: 'email', operator: '==', value: email },
    ]);
    return results.length > 0 ? new Admin(results[0]) : null;
  }

  static async create(data) {
    const doc = await createDocument(COLLECTIONS.ADMINS, data);
    return new Admin(doc);
  }

  async recordLogin() {
    this.lastLogin = new Date();
    await updateDocument(COLLECTIONS.ADMINS, this.id, { lastLogin: this.lastLogin });
  }

  toJSON() {
    return {
      id: this.id,
      userId: this.userId,
      email: this.email,
      fullName: this.fullName,
      role: this.role,
      permissions: this.permissions,
      isActive: this.isActive,
      createdAt: this.createdAt,
      lastLogin: this.lastLogin,
    };
  }
}

module.exports = Admin;
