// src/models/Chat.js
const { getDocumentById, updateDocument, deleteDocument, queryDocuments, createDocument, COLLECTIONS } = require('../config/database');

class ChatMessage {
  constructor(data) {
    this.id = data.id;
    this.chatId = data.chatId;
    this.senderId = data.senderId;
    this.receiverId = data.receiverId;
    this.message = data.message;
    this.type = data.type || 'text';
    this.mediaUrl = data.mediaUrl;
    this.timestamp = data.timestamp || new Date();
    this.isRead = data.isRead || false;
    this.isDelivered = data.isDelivered || false;
    this.isSeen = data.isSeen || false;
  }

  toJSON() {
    return {
      id: this.id,
      chatId: this.chatId,
      senderId: this.senderId,
      receiverId: this.receiverId,
      message: this.message,
      type: this.type,
      mediaUrl: this.mediaUrl,
      timestamp: this.timestamp,
      isRead: this.isRead,
      isDelivered: this.isDelivered,
      isSeen: this.isSeen,
    };
  }

  static async create(data) {
    const result = await createDocument(COLLECTIONS.MESSAGES, data);
    return new ChatMessage(result);
  }

  async save() {
    const data = this.toJSON();
    delete data.id;
    await updateDocument(COLLECTIONS.MESSAGES, this.id, data);
    return this;
  }

  async markAsRead() {
    this.isRead = true;
    this.isSeen = true;
    await this.save();
    return this;
  }

  async markAsDelivered() {
    this.isDelivered = true;
    await this.save();
    return this;
  }

  async delete() {
    await deleteDocument(COLLECTIONS.MESSAGES, this.id);
    return true;
  }
}

class ChatThread {
  constructor(data) {
    this.id = data.id;
    this.user1Id = data.user1Id;
    this.user2Id = data.user2Id;
    this.user1Name = data.user1Name;
    this.user1Photo = data.user1Photo;
    this.user2Name = data.user2Name;
    this.user2Photo = data.user2Photo;
    this.lastMessage = data.lastMessage;
    this.lastMessageTime = data.lastMessageTime || new Date();
    this.unreadCount = data.unreadCount || 0;
    this.isActive = data.isActive || true;
  }

  toJSON() {
    return {
      id: this.id,
      user1Id: this.user1Id,
      user2Id: this.user2Id,
      user1Name: this.user1Name,
      user1Photo: this.user1Photo,
      user2Name: this.user2Name,
      user2Photo: this.user2Photo,
      lastMessage: this.lastMessage,
      lastMessageTime: this.lastMessageTime,
      unreadCount: this.unreadCount,
      isActive: this.isActive,
    };
  }

  static async findById(id) {
    const data = await getDocumentById(COLLECTIONS.CHATS, id);
    if (!data) return null;
    return new ChatThread(data);
  }

  static async findByUsers(user1Id, user2Id) {
    const results = await queryDocuments(COLLECTIONS.CHATS, [
      { field: 'user1Id', operator: '==', value: user1Id },
      { field: 'user2Id', operator: '==', value: user2Id }
    ]);
    if (results.length === 0) {
      const results2 = await queryDocuments(COLLECTIONS.CHATS, [
        { field: 'user1Id', operator: '==', value: user2Id },
        { field: 'user2Id', operator: '==', value: user1Id }
      ]);
      if (results2.length === 0) return null;
      return new ChatThread(results2[0]);
    }
    return new ChatThread(results[0]);
  }

  static async findByUser(userId) {
    const results1 = await queryDocuments(COLLECTIONS.CHATS, [
      { field: 'user1Id', operator: '==', value: userId }
    ]);
    const results2 = await queryDocuments(COLLECTIONS.CHATS, [
      { field: 'user2Id', operator: '==', value: userId }
    ]);
    
    const allResults = [...results1, ...results2];
    const uniqueResults = [];
    const seen = new Set();
    
    for (const result of allResults) {
      if (!seen.has(result.id)) {
        seen.add(result.id);
        uniqueResults.push(result);
      }
    }
    
    uniqueResults.sort((a, b) => {
      const timeA = a.lastMessageTime || new Date(0);
      const timeB = b.lastMessageTime || new Date(0);
      return timeB - timeA;
    });
    
    return uniqueResults.map(data => new ChatThread(data));
  }

  static async create(data) {
    const result = await createDocument(COLLECTIONS.CHATS, data);
    return new ChatThread(result);
  }

  async save() {
    const data = this.toJSON();
    delete data.id;
    await updateDocument(COLLECTIONS.CHATS, this.id, data);
    return this;
  }

  async getMessages(limit = 50) {
    const results = await queryDocuments(
      COLLECTIONS.MESSAGES,
      [{ field: 'chatId', operator: '==', value: this.id }],
      { field: 'timestamp', direction: 'desc' }
    );
    return results.slice(0, limit).map(data => new ChatMessage(data));
  }

  async addMessage(message) {
    const msg = await ChatMessage.create({
      ...message,
      chatId: this.id,
    });
    
    this.lastMessage = message.message;
    this.lastMessageTime = new Date();
    if (message.receiverId === this.user1Id) {
      this.unreadCount += 1;
    }
    await this.save();
    return msg;
  }

  async markAllRead(userId) {
    if (userId === this.user1Id || userId === this.user2Id) {
      this.unreadCount = 0;
      await this.save();
      
      // Mark all messages as read
      const messages = await this.getMessages(100);
      for (const msg of messages) {
        if (msg.receiverId === userId && !msg.isRead) {
          await msg.markAsRead();
        }
      }
    }
    return this;
  }
}

module.exports = { ChatMessage, ChatThread };