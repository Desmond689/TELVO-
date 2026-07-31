// src/models/Promotion.js
const { getDocumentById, updateDocument, queryDocuments, createDocument, COLLECTIONS } = require('../config/database');

class Promotion {
  constructor(data) {
    this.id = data.id;
    this.title = data.title;
    this.description = data.description;
    this.code = data.code;
    this.discount = data.discount;
    this.type = data.type || 'percentage';
    this.startDate = data.startDate || new Date();
    this.endDate = data.endDate;
    this.isActive = data.isActive || true;
    this.usageLimit = data.usageLimit || 100;
    this.usedCount = data.usedCount || 0;
    this.createdAt = data.createdAt || new Date();
    this.updatedAt = data.updatedAt || new Date();
  }

  toJSON() {
    return {
      id: this.id,
      title: this.title,
      description: this.description,
      code: this.code,
      discount: this.discount,
      type: this.type,
      startDate: this.startDate,
      endDate: this.endDate,
      isActive: this.isActive,
      usageLimit: this.usageLimit,
      usedCount: this.usedCount,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
    };
  }

  static async findById(id) {
    const data = await getDocumentById(COLLECTIONS.PROMOTIONS, id);
    if (!data) return null;
    return new Promotion(data);
  }

  static async findByCode(code) {
    const results = await queryDocuments(COLLECTIONS.PROMOTIONS, [
      { field: 'code', operator: '==', value: code }
    ]);
    if (results.length === 0) return null;
    return new Promotion(results[0]);
  }

  static async getActivePromotions() {
    const now = new Date();
    const results = await queryDocuments(COLLECTIONS.PROMOTIONS, [
      { field: 'isActive', operator: '==', value: true },
      { field: 'startDate', operator: '<=', value: now },
      { field: 'endDate', operator: '>=', value: now }
    ]);
    return results.map(data => new Promotion(data));
  }

  async save() {
    const data = this.toJSON();
    delete data.id;
    await updateDocument(COLLECTIONS.PROMOTIONS, this.id, data);
    return this;
  }

  async usePromotion() {
    if (this.usedCount >= this.usageLimit) {
      throw new Error('Promotion usage limit exceeded');
    }
    this.usedCount++;
    this.updatedAt = new Date();
    await this.save();
    return this;
  }

  calculateDiscount(amount) {
    if (this.type === 'percentage') {
      return (amount * this.discount) / 100;
    } else {
      return Math.min(this.discount, amount);
    }
  }

  isValid() {
    const now = new Date();
    return this.isActive && 
           now >= this.startDate && 
           now <= this.endDate &&
           this.usedCount < this.usageLimit;
  }
}

module.exports = Promotion;