// src/controllers/reviewController.js
const Review = require('../models/Review');
const Job = require('../models/Job');
const User = require('../models/User');
const { logger } = require('../utils/logger');
const { successResponse, errorResponse } = require('../utils/responseHandler');

const createReview = async (req, res) => {
  try {
    const { jobId, rating, comment, photos, isAnonymous } = req.body;
    
    const job = await Job.findById(jobId);
    if (!job) {
      return errorResponse(res, 'Job not found', 404);
    }
    
    if (job.customerId !== req.userId) {
      return errorResponse(res, 'Unauthorized to review this job', 403);
    }
    
    if (!job.isCompleted()) {
      return errorResponse(res, 'Cannot review incomplete job', 400);
    }
    
    if (job.review) {
      return errorResponse(res, 'Job already reviewed', 400);
    }
    
    const review = await Review.create({
      jobId,
      reviewerId: req.userId,
      reviewedId: job.professionalId,
      rating,
      comment,
      photos: photos || [],
      isAnonymous: isAnonymous || false,
    });
    
    // Update job with review
    await job.addReview(review.toJSON());
    
    // Update professional rating
    const professional = await User.findById(job.professionalId);
    if (professional) {
      await professional.updateRating();
    }
    
    return successResponse(res, review.toJSON(), 'Review submitted successfully', 201);
  } catch (error) {
    logger.error('Create review error:', error);
    return errorResponse(res, 'Failed to submit review', 500);
  }
};

const getReviews = async (req, res) => {
  try {
    const { userId } = req.params;
    const reviews = await Review.findByReviewed(userId);
    return successResponse(res, reviews);
  } catch (error) {
    logger.error('Get reviews error:', error);
    return errorResponse(res, 'Failed to get reviews', 500);
  }
};

const getReviewById = async (req, res) => {
  try {
    const { id } = req.params;
    const review = await Review.findById(id);
    if (!review) {
      return errorResponse(res, 'Review not found', 404);
    }
    return successResponse(res, review.toJSON());
  } catch (error) {
    logger.error('Get review error:', error);
    return errorResponse(res, 'Failed to get review', 500);
  }
};

const updateReview = async (req, res) => {
  try {
    const { id } = req.params;
    const { comment, photos } = req.body;
    
    const review = await Review.findById(id);
    if (!review) {
      return errorResponse(res, 'Review not found', 404);
    }
    
    if (review.reviewerId !== req.userId && !req.user.isAdmin()) {
      return errorResponse(res, 'Unauthorized to update review', 403);
    }
    
    if (comment !== undefined) review.comment = comment;
    if (photos !== undefined) review.photos = photos;
    
    await review.save();
    return successResponse(res, review.toJSON(), 'Review updated successfully');
  } catch (error) {
    logger.error('Update review error:', error);
    return errorResponse(res, 'Failed to update review', 500);
  }
};

const deleteReview = async (req, res) => {
  try {
    const { id } = req.params;
    const review = await Review.findById(id);
    if (!review) {
      return errorResponse(res, 'Review not found', 404);
    }
    
    if (review.reviewerId !== req.userId && !req.user.isAdmin()) {
      return errorResponse(res, 'Unauthorized to delete review', 403);
    }
    
    await review.delete();
    return successResponse(res, null, 'Review deleted successfully');
  } catch (error) {
    logger.error('Delete review error:', error);
    return errorResponse(res, 'Failed to delete review', 500);
  }
};

const addResponseToReview = async (req, res) => {
  try {
    const { id } = req.params;
    const { response } = req.body;
    
    const review = await Review.findById(id);
    if (!review) {
      return errorResponse(res, 'Review not found', 404);
    }
    
    if (review.reviewedId !== req.userId && !req.user.isAdmin()) {
      return errorResponse(res, 'Unauthorized to respond to review', 403);
    }
    
    await review.addResponse(response);
    return successResponse(res, review.toJSON(), 'Response added successfully');
  } catch (error) {
    logger.error('Add response error:', error);
    return errorResponse(res, 'Failed to add response', 500);
  }
};

module.exports = {
  createReview,
  getReviews,
  getReviewById,
  updateReview,
  deleteReview,
  addResponseToReview,
};