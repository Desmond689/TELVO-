// src/models/Review.js
const { getDocumentById, updateDocument, deleteDocument, queryDocuments, createDocument, COLLECTIONS } = require('../config/database');

class Review {
  constructor(data) {
    this.id = data.id;
    this.jobId = data.jobId;
    this.reviewerId = data.reviewerId;
    this.reviewedId = data.reviewedId;
    this.rating = data.rating;
    this.comment = data.comment;
    this.photos = data.photos || [];
    this.videos = data.videos || [];
    this.ratings = data.ratings || {};
    this.isAnonymous = data.isAnonymous || false;
    this.createdAt = data.createdAt || new Date();
    this.updatedAt = data.updatedAt || new Date();
    this.isResponse = data.isResponse || false;
    this.responseText = data.responseText;
    this.responseAt = data.responseAt;
  }

  toJSON() {
    return {
      id: this.id,
      jobId: this.jobId,
      reviewerId: this.reviewerId,
      reviewedId: this.reviewedId,
      rating: this.rating,
      comment: this.comment,
      photos: this.photos,
      videos: this.videos,
      ratings: this.ratings,
      isAnonymous: this.isAnonymous,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      isResponse: this.isResponse,
      responseText: this.responseText,
      responseAt: this.responseAt,
    };
  }

  static async findById(id) {
    const data = await getDocumentById(COLLECTIONS.REVIEWS, id);
    if (!data) return null;
    return new Review(data);
  }

  static async findByReviewed(reviewedId) {
    const results = await queryDocuments(
      COLLECTIONS.REVIEWS,
      [{ field: 'reviewedId', operator: '==', value: reviewedId }],
      { field: 'createdAt', direction: 'desc' }
    );
    return results.map(data => new Review(data));
  }

  static async findByJob(jobId) {
    const results = await queryDocuments(
      COLLECTIONS.REVIEWS,
      [{ field: 'jobId', operator: '==', value: jobId }]
    );
    return results.map(data => new Review(data));
  }

  static async create(data) {
    const result = await createDocument(COLLECTIONS.REVIEWS, data);
    return new Review(result);
  }

  async save() {
    const data = this.toJSON();
    delete data.id;
    this.updatedAt = new Date();
    data.updatedAt = this.updatedAt;
    await updateDocument(COLLECTIONS.REVIEWS, this.id, data);
    return this;
  }

  async delete() {
    await deleteDocument(COLLECTIONS.REVIEWS, this.id);
    return true;
  }

  async addResponse(text) {
    this.isResponse = true;
    this.responseText = text;
    this.responseAt = new Date();
    await this.save();
    return this;
  }
}

module.exports = Review;