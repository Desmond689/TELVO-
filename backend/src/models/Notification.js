// src/models/Notification.js
const { getDocumentById, updateDocument, queryDocuments, createDocument, COLLECTIONS } = require('../config/database');

class Notification {
  constructor(data) {
    this.id = data.id;
    this.userId = data.userId;
    this.title = data.title;
    this.body = data.body;
    this.type = data.type || 'system';
    this.data = data.data || {};
    this.actionUrl = data.actionUrl;
    this.isRead = data.isRead || false;
    this.isSent = data.isSent || false;
    this.createdAt = data.createdAt || new Date();
    this.sentAt = data.sentAt;
  }

  toJSON() {
    return {
      id: this.id,
      userId: this.userId,
      title: this.title,
      body: this.body,
      type: this.type,
      data: this.data,
      actionUrl: this.actionUrl,
      isRead: this.isRead,
      isSent: this.isSent,
      createdAt: this.createdAt,
      sentAt: this.sentAt,
    };
  }

  static async findById(id) {
    const data = await getDocumentById(COLLECTIONS.NOTIFICATIONS, id);
    if (!data) return null;
    return new Notification(data);
  }

  static async findByUser(userId, limit = 50) {
    const results = await queryDocuments(
      COLLECTIONS.NOTIFICATIONS,
      [{ field: 'userId', operator: '==', value: userId }],
      { field: 'createdAt', direction: 'desc' }
    );
    return results.slice(0, limit).map(data => new Notification(data));
  }

  static async create(data) {
    const result = await createDocument(COLLECTIONS.NOTIFICATIONS, data);
    return new Notification(result);
  }

  async save() {
    const data = this.toJSON();
    delete data.id;
    await updateDocument(COLLECTIONS.NOTIFICATIONS, this.id, data);
    return this;
  }

  async markAsRead() {
    this.isRead = true;
    await this.save();
    return this;
  }

  async markAsSent() {
    this.isSent = true;
    this.sentAt = new Date();
    await this.save();
    return this;
  }

  static async markAllAsRead(userId) {
    const notifications = await Notification.findByUser(userId, 1000);
    for (const notification of notifications) {
      if (!notification.isRead) {
        await notification.markAsRead();
      }
    }
  }

  static async deleteOldNotifications(days = 30) {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - days);
    
    const results = await queryDocuments(COLLECTIONS.NOTIFICATIONS, [
      { field: 'createdAt', operator: '<', value: cutoff },
      { field: 'isRead', operator: '==', value: true }
    ]);
    
    for (const data of results) {
      await new Notification(data).delete();
    }
    
    return results.length;
  }
}

module.exports = Notification;