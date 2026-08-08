// src/models/Payment.js
const { getDocumentById, updateDocument, deleteDocument, queryDocuments, createDocument, COLLECTIONS } = require('../config/database');

class Payment {
  constructor(data) {
    this.id = data.id;
    this.jobId = data.jobId;
    this.customerId = data.customerId;
    this.professionalId = data.professionalId;
    this.amount = data.amount;
    this.currency = data.currency || 'XAF';
    this.method = data.method;
    this.status = data.status || 'pending';
    this.transactionId = data.transactionId;
    this.reference = data.reference;
    this.metadata = data.metadata || {};
    this.createdAt = data.createdAt || new Date();
    this.completedAt = data.completedAt;
    this.refundedAt = data.refundedAt;
    this.refundReason = data.refundReason;
  }

  toJSON() {
    return {
      id: this.id,
      jobId: this.jobId,
      customerId: this.customerId,
      professionalId: this.professionalId,
      amount: this.amount,
      currency: this.currency,
      method: this.method,
      status: this.status,
      transactionId: this.transactionId,
      reference: this.reference,
      metadata: this.metadata,
      createdAt: this.createdAt,
      completedAt: this.completedAt,
      refundedAt: this.refundedAt,
      refundReason: this.refundReason,
    };
  }

  static async findById(id) {
    const data = await getDocumentById(COLLECTIONS.PAYMENTS, id);
    if (!data) return null;
    return new Payment(data);
  }

  static async findByCustomer(customerId) {
    const results = await queryDocuments(
      COLLECTIONS.PAYMENTS,
      [{ field: 'customerId', operator: '==', value: customerId }],
      { field: 'createdAt', direction: 'desc' }
    );
    return results.map(data => new Payment(data));
  }

  static async findByProfessional(professionalId) {
    const results = await queryDocuments(
      COLLECTIONS.PAYMENTS,
      [{ field: 'professionalId', operator: '==', value: professionalId }],
      { field: 'createdAt', direction: 'desc' }
    );
    return results.map(data => new Payment(data));
  }

  static async create(data) {
    const result = await createDocument(COLLECTIONS.PAYMENTS, data);
    return new Payment(result);
  }

  async save() {
    const data = this.toJSON();
    delete data.id;
    await updateDocument(COLLECTIONS.PAYMENTS, this.id, data);
    return this;
  }

  async complete() {
    this.status = 'completed';
    this.completedAt = new Date();
    await this.save();
    return this;
  }

  async fail() {
    this.status = 'failed';
    await this.save();
    return this;
  }

  async refund(reason) {
    this.status = 'refunded';
    this.refundedAt = new Date();
    this.refundReason = reason;
    await this.save();
    return this;
  }

  isCompleted() {
    return this.status === 'completed';
  }

  isPending() {
    return this.status === 'pending';
  }

  isRefunded() {
    return this.status === 'refunded';
  }
}

module.exports = Payment;