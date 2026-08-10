// src/controllers/walletController.js
const Wallet = require('../models/Wallet');
const { logger } = require('../utils/logger');
const { successResponse, errorResponse } = require('../utils/responseHandler');

const getWallet = async (req, res) => {
  try {
    let wallet = await Wallet.findByUserId(req.userId);
    if (!wallet) {
      wallet = await Wallet.create(req.userId);
    }
    return successResponse(res, wallet.toJSON());
  } catch (error) {
    logger.error('Get wallet error:', error);
    return errorResponse(res, 'Failed to get wallet', 500);
  }
};

const getTransactions = async (req, res) => {
  try {
    const wallet = await Wallet.findByUserId(req.userId);
    if (!wallet) {
      return errorResponse(res, 'Wallet not found', 404);
    }
    return successResponse(res, wallet.transactions || []);
  } catch (error) {
    logger.error('Get transactions error:', error);
    return errorResponse(res, 'Failed to get transactions', 500);
  }
};

const withdrawFunds = async (req, res) => {
  try {
    const { amount, method, accountDetails } = req.body;
    
    const wallet = await Wallet.findByUserId(req.userId);
    if (!wallet) {
      return errorResponse(res, 'Wallet not found', 404);
    }
    
    if (wallet.balance < amount) {
      return errorResponse(res, 'Insufficient balance', 400);
    }
    
    await wallet.deductFunds(amount, `Withdrawal via ${method}`);
    
    // Process withdrawal (in production, integrate with payment provider)
    
    return successResponse(res, {
      amount,
      method,
      status: 'processing',
      reference: `WTH-${Date.now()}`
    }, 'Withdrawal initiated successfully');
  } catch (error) {
    logger.error('Withdraw funds error:', error);
    return errorResponse(res, 'Failed to process withdrawal', 500);
  }
};

module.exports = {
  getWallet,
  getTransactions,
  withdrawFunds,
};