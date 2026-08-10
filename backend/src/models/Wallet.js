// src/models/Wallet.js
const { getDocumentById, updateDocument, createDocument, COLLECTIONS } = require('../config/database');

class Wallet {
  constructor(data) {
    this.id = data.id;
    this.userId = data.userId;
    this.balance = data.balance || 0;
    this.totalEarned = data.totalEarned || 0;
    this.totalSpent = data.totalSpent || 0;
    this.transactions = data.transactions || [];
    this.createdAt = data.createdAt || new Date();
    this.updatedAt = data.updatedAt || new Date();
  }

  toJSON() {
    return {
      id: this.id,
      userId: this.userId,
      balance: this.balance,
      totalEarned: this.totalEarned,
      totalSpent: this.totalSpent,
      transactions: this.transactions,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
    };
  }

  static async findByUserId(userId) {
    const data = await getDocumentById(COLLECTIONS.WALLETS, userId);
    if (!data) return null;
    return new Wallet(data);
  }

  static async create(userId) {
    const data = {
      userId,
      balance: 0,
      totalEarned: 0,
      totalSpent: 0,
      transactions: [],
    };
    const result = await createDocument(COLLECTIONS.WALLETS, data);
    return new Wallet(result);
  }

  async addFunds(amount, description) {
    this.balance += amount;
    this.totalEarned += amount;
    this.transactions.push({
      type: 'credit',
      amount,
      description,
      date: new Date(),
    });
    this.updatedAt = new Date();
    await this.save();
    return this;
  }

  async deductFunds(amount, description) {
    if (this.balance < amount) {
      throw new Error('Insufficient balance');
    }
    this.balance -= amount;
    this.totalSpent += amount;
    this.transactions.push({
      type: 'debit',
      amount,
      description,
      date: new Date(),
    });
    this.updatedAt = new Date();
    await this.save();
    return this;
  }

  async save() {
    const data = this.toJSON();
    delete data.id;
    await updateDocument(COLLECTIONS.WALLETS, this.id, data);
    return this;
  }
}

module.exports = Wallet;