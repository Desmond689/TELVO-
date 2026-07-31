// src/controllers/disputeController.js
const Dispute = require('../models/Dispute');
const Job = require('../models/Job');
const { logger } = require('../utils/logger');
const { successResponse, errorResponse } = require('../utils/responseHandler');

const createDispute = async (req, res) => {
  try {
    const { jobId, title, description, priority = 'medium' } = req.body;
    
    const job = await Job.findById(jobId);
    if (!job) {
      return errorResponse(res, 'Job not found', 404);
    }
    
    if (job.customerId !== req.userId && job.professionalId !== req.userId) {
      return errorResponse(res, 'Unauthorized to create dispute', 403);
    }
    
    const dispute = await Dispute.create({
      jobId,
      customerId: job.customerId,
      professionalId: job.professionalId,
      title,
      description,
      priority,
      status: 'open'
    });
    
    return successResponse(res, dispute.toJSON(), 'Dispute created successfully', 201);
  } catch (error) {
    logger.error('Create dispute error:', error);
    return errorResponse(res, 'Failed to create dispute', 500);
  }
};

const getDisputes = async (req, res) => {
  try {
    const disputes = await Dispute.getOpenDisputes();
    return successResponse(res, disputes);
  } catch (error) {
    logger.error('Get disputes error:', error);
    return errorResponse(res, 'Failed to get disputes', 500);
  }
};

const getDisputeById = async (req, res) => {
  try {
    const { id } = req.params;
    const dispute = await Dispute.findById(id);
    if (!dispute) {
      return errorResponse(res, 'Dispute not found', 404);
    }
    
    if (dispute.customerId !== req.userId && 
        dispute.professionalId !== req.userId && 
        !req.user.isAdmin()) {
      return errorResponse(res, 'Unauthorized to view dispute', 403);
    }
    
    return successResponse(res, dispute.toJSON());
  } catch (error) {
    logger.error('Get dispute error:', error);
    return errorResponse(res, 'Failed to get dispute', 500);
  }
};

const addDisputeMessage = async (req, res) => {
  try {
    const { id } = req.params;
    const { message } = req.body;
    
    const dispute = await Dispute.findById(id);
    if (!dispute) {
      return errorResponse(res, 'Dispute not found', 404);
    }
    
    if (dispute.customerId !== req.userId && 
        dispute.professionalId !== req.userId && 
        !req.user.isAdmin()) {
      return errorResponse(res, 'Unauthorized to add message', 403);
    }
    
    const sender = req.user.isAdmin() ? 'Admin' : 
                   req.userId === dispute.customerId ? 'Customer' : 'Professional';
    
    await dispute.addMessage(sender, message);
    return successResponse(res, dispute.toJSON(), 'Message added successfully');
  } catch (error) {
    logger.error('Add dispute message error:', error);
    return errorResponse(res, 'Failed to add message', 500);
  }
};

const resolveDispute = async (req, res) => {
  try {
    const { id } = req.params;
    const { resolution } = req.body;
    
    const dispute = await Dispute.findById(id);
    if (!dispute) {
      return errorResponse(res, 'Dispute not found', 404);
    }
    
    if (!req.user.isAdmin()) {
      return errorResponse(res, 'Only admins can resolve disputes', 403);
    }
    
    await dispute.resolve(resolution);
    return successResponse(res, dispute.toJSON(), 'Dispute resolved successfully');
  } catch (error) {
    logger.error('Resolve dispute error:', error);
    return errorResponse(res, 'Failed to resolve dispute', 500);
  }
};

const closeDispute = async (req, res) => {
  try {
    const { id } = req.params;
    const dispute = await Dispute.findById(id);
    if (!dispute) {
      return errorResponse(res, 'Dispute not found', 404);
    }
    
    if (!req.user.isAdmin() && dispute.customerId !== req.userId && 
        dispute.professionalId !== req.userId) {
      return errorResponse(res, 'Unauthorized to close dispute', 403);
    }
    
    await dispute.close();
    return successResponse(res, dispute.toJSON(), 'Dispute closed successfully');
  } catch (error) {
    logger.error('Close dispute error:', error);
    return errorResponse(res, 'Failed to close dispute', 500);
  }
};

module.exports = {
  createDispute,
  getDisputes,
  getDisputeById,
  addDisputeMessage,
  resolveDispute,
  closeDispute,
};