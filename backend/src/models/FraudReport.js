// src/models/FraudReport.js
const { getDocumentById, updateDocument, queryDocuments, createDocument, COLLECTIONS } = require('../config/database');

class FraudReport {
  constructor(data) {
    this.id = data.id;
    this.reportedUserId = data.reportedUserId;
    this.reportedBy = data.reportedBy;
    this.reason = data.reason;
    this.description = data.description;
    this.evidence = data.evidence || [];
    this.status = data.status || 'pending';
    this.riskLevel = data.riskLevel || 'medium';
    this.aiAnalysis = data.aiAnalysis || {};
    this.isVerified = data.isVerified || false;
    this.verifiedAt = data.verifiedAt;
    this.createdAt = data.createdAt || new Date();
    this.updatedAt = data.updatedAt || new Date();
  }

  toJSON() {
    return {
      id: this.id,
      reportedUserId: this.reportedUserId,
      reportedBy: this.reportedBy,
      reason: this.reason,
      description: this.description,
      evidence: this.evidence,
      status: this.status,
      riskLevel: this.riskLevel,
      aiAnalysis: this.aiAnalysis,
      isVerified: this.isVerified,
      verifiedAt: this.verifiedAt,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
    };
  }

  static async findById(id) {
    const data = await getDocumentById(COLLECTIONS.FRAUD_REPORTS, id);
    if (!data) return null;
    return new FraudReport(data);
  }

  static async findByUser(userId) {
    const results = await queryDocuments(COLLECTIONS.FRAUD_REPORTS, [
      { field: 'reportedUserId', operator: '==', value: userId }
    ]);
    return results.map(data => new FraudReport(data));
  }

  static async getPendingReports() {
    const results = await queryDocuments(COLLECTIONS.FRAUD_REPORTS, [
      { field: 'status', operator: '==', value: 'pending' }
    ]);
    return results.map(data => new FraudReport(data));
  }

  static async create(data) {
    const result = await createDocument(COLLECTIONS.FRAUD_REPORTS, data);
    return new FraudReport(result);
  }

  async save() {
    const data = this.toJSON();
    delete data.id;
    await updateDocument(COLLECTIONS.FRAUD_REPORTS, this.id, data);
    return this;
  }

  async verify() {
    this.isVerified = true;
    this.verifiedAt = new Date();
    this.status = 'verified';
    await this.save();
    return this;
  }

  async dismiss() {
    this.status = 'dismissed';
    await this.save();
    return this;
  }

  async analyze() {
    // AI analysis logic
    this.aiAnalysis = {
      confidence: 0.85,
      flags: ['Suspicious Activity', 'Pattern Match'],
      analyzedAt: new Date()
    };
    await this.save();
    return this;
  }
}

module.exports = FraudReport;