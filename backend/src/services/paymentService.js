// src/services/paymentService.js
const { logger } = require('../utils/logger');
const axios = require('axios');

class PaymentService {
  constructor() {
    this.commissionRate = 0.10; // 10%
    this.minCommission = 500;
  }

  calculateCommission(amount) {
    const commission = amount * this.commissionRate;
    return Math.max(commission, this.minCommission);
  }

  calculateProfessionalAmount(amount) {
    const commission = this.calculateCommission(amount);
    return amount - commission;
  }

  async processCashPayment(paymentData) {
    try {
      logger.info(`Processing cash payment: ${paymentData.jobId}`);
      
      // In production, integrate with cash payment provider
      return {
        success: true,
        transactionId: `CASH-${Date.now()}`,
        status: 'completed',
        message: 'Cash payment processed successfully'
      };
    } catch (error) {
      logger.error('Cash payment error:', error);
      throw error;
    }
  }

  async processMomoPayment(paymentData) {
    try {
      logger.info(`Processing MTN MoMo payment: ${paymentData.jobId}`);
      
      // In production, integrate with MTN MoMo API
      const response = await axios.post(
        `${process.env.MTN_MOMO_API_URL}/payment`,
        {
          amount: paymentData.amount,
          phone: paymentData.phone,
          reference: paymentData.reference,
        },
        {
          headers: {
            'Authorization': `Bearer ${process.env.MTN_MOMO_API_KEY}`,
            'Content-Type': 'application/json',
          }
        }
      );
      
      return {
        success: true,
        transactionId: response.data.transactionId,
        status: 'processing',
        message: 'MTN MoMo payment initiated'
      };
    } catch (error) {
      logger.error('MTN MoMo payment error:', error);
      throw error;
    }
  }

  async processOrangePayment(paymentData) {
    try {
      logger.info(`Processing Orange Money payment: ${paymentData.jobId}`);
      
      // In production, integrate with Orange Money API
      const response = await axios.post(
        `${process.env.ORANGE_MONEY_API_URL}/payment`,
        {
          amount: paymentData.amount,
          phone: paymentData.phone,
          reference: paymentData.reference,
        },
        {
          headers: {
            'Authorization': `Bearer ${process.env.ORANGE_MONEY_API_KEY}`,
            'Content-Type': 'application/json',
          }
        }
      );
      
      return {
        success: true,
        transactionId: response.data.transactionId,
        status: 'processing',
        message: 'Orange Money payment initiated'
      };
    } catch (error) {
      logger.error('Orange Money payment error:', error);
      throw error;
    }
  }

  async processCardPayment(paymentData) {
    try {
      logger.info(`Processing card payment: ${paymentData.jobId}`);
      
      // In production, integrate with Stripe or other card provider
      return {
        success: true,
        transactionId: `CARD-${Date.now()}`,
        status: 'processing',
        message: 'Card payment initiated'
      };
    } catch (error) {
      logger.error('Card payment error:', error);
      throw error;
    }
  }

  async processPayment(method, paymentData) {
    switch (method) {
      case 'cash':
        return this.processCashPayment(paymentData);
      case 'momo':
        return this.processMomoPayment(paymentData);
      case 'orange':
        return this.processOrangePayment(paymentData);
      case 'card':
        return this.processCardPayment(paymentData);
      default:
        throw new Error(`Unsupported payment method: ${method}`);
    }
  }

  async verifyPayment(transactionId) {
    try {
      logger.info(`Verifying payment: ${transactionId}`);
      
      // In production, verify with payment provider
      return {
        success: true,
        status: 'completed',
        verified: true
      };
    } catch (error) {
      logger.error('Payment verification error:', error);
      throw error;
    }
  }

  async refundPayment(transactionId, reason) {
    try {
      logger.info(`Refunding payment: ${transactionId} - ${reason}`);
      
      // In production, process refund with payment provider
      return {
        success: true,
        refundId: `REF-${Date.now()}`,
        status: 'processing',
        message: 'Refund initiated'
      };
    } catch (error) {
      logger.error('Refund payment error:', error);
      throw error;
    }
  }
}

module.exports = PaymentService;