// src/models/Dispute.js
const { getDocumentById, updateDocument, queryDocuments, createDocument, COLLECTIONS } = require('../config/database');

class Dispute {
  constructor(data) {
    this.id = data.id;
    this.jobId = data.jobId;
    this.customerId = data.customerId;
    this.professionalId = data.professionalId;
    this.title = data.title;
    this.description = data.description;
    this.status = data.status || 'open';
    this.priority = data.priority || 'medium';
    this.messages = data.messages || [];
    this.resolution = data.resolution;
    this.resolvedAt = data.resolvedAt;
    this.createdAt = data.createdAt || new Date();
    this.updatedAt = data.updatedAt || new Date();
  }

  toJSON() {
    return {
      id: this.id,
      jobId: this.jobId,
      customerId: this.customerId,
      professionalId: this.professionalId,
      title: this.title,
      description: this.description,
      status: this.status,
      priority: this.priority,
      messages: this.messages,
      resolution: this.resolution,
      resolvedAt: this.resolvedAt,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
    };
  }

  static async findById(id) {
    const data = await getDocumentById(COLLECTIONS.DISPUTES, id);
    if (!data) return null;
    return new Dispute(data);
  }

  static async findByJob(jobId) {
    const results = await queryDocuments(COLLECTIONS.DISPUTES, [
      { field: 'jobId', operator: '==', value: jobId }
    ]);
    return results.map(data => new Dispute(data));
  }

  static async getOpenDisputes() {
    const results = await queryDocuments(COLLECTIONS.DISPUTES, [
      { field: 'status', operator: 'in', value: ['open', 'investigating'] }
    ]);
    return results.map(data => new Dispute(data));
  }

  static async create(data) {
    const result = await createDocument(COLLECTIONS.DISPUTES, data);
    return new Dispute(result);
  }

  async save() {
    const data = this.toJSON();
    delete data.id;
    await updateDocument(COLLECTIONS.DISPUTES, this.id, data);
    return this;
  }

  async addMessage(sender, message) {
    this.messages.push({
      sender,
      message,
      time: new Date()
    });
    this.updatedAt = new Date();
    await this.save();
    return this;
  }

  async resolve(resolution) {
    this.status = 'resolved';
    this.resolution = resolution;
    this.resolvedAt = new Date();
    await this.save();
    return this;
  }

  async close() {
    this.status = 'closed';
    await this.save();
    return this;
  }
}

module.exports = Dispute;