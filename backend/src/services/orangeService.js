// src/services/orangeService.js
const { logger } = require('../utils/logger');
const axios = require('axios');

class OrangeService {
  constructor() {
    this.apiKey = process.env.ORANGE_MONEY_API_KEY;
    this.apiSecret = process.env.ORANGE_MONEY_API_SECRET;
    this.baseUrl = process.env.ORANGE_MONEY_API_URL || 'https://api.orange.com';
    this.accessToken = null;
    this.tokenExpiry = null;
  }

  async getAccessToken() {
    try {
      if (this.accessToken && this.tokenExpiry && new Date() < this.tokenExpiry) {
        return this.accessToken;
      }

      const response = await axios.post(
        `${this.baseUrl}/oauth/v2/token`,
        new URLSearchParams({
          grant_type: 'client_credentials',
        }),
        {
          headers: {
            'Authorization': `Basic ${Buffer.from(`${this.apiKey}:${this.apiSecret}`).toString('base64')}`,
            'Content-Type': 'application/x-www-form-urlencoded',
          }
        }
      );

      this.accessToken = response.data.access_token;
      this.tokenExpiry = new Date(Date.now() + response.data.expires_in * 1000);
      
      return this.accessToken;
    } catch (error) {
      logger.error('Orange Money getAccessToken error:', error);
      throw error;
    }
  }

  async requestPayment(phoneNumber, amount, reference) {
    try {
      const token = await this.getAccessToken();
      
      const response = await axios.post(
        `${this.baseUrl}/orange-money/api/v1/payments`,
        {
          amount,
          currency: 'XAF',
          orderId: reference,
          payer: {
            phoneNumber: phoneNumber.replace('+', ''),
          },
          description: `Payment for job ${reference}`,
        },
        {
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json',
          }
        }
      );

      return {
        success: true,
        transactionId: response.data.transactionId,
        status: 'pending',
        message: 'Payment request sent'
      };
    } catch (error) {
      logger.error('Orange Money requestPayment error:', error);
      throw error;
    }
  }

  async checkPaymentStatus(reference) {
    try {
      const token = await this.getAccessToken();
      
      const response = await axios.get(
        `${this.baseUrl}/orange-money/api/v1/payments/${reference}`,
        {
          headers: {
            'Authorization': `Bearer ${token}`,
          }
        }
      );

      return {
        success: true,
        status: response.data.status,
        message: response.data.message || 'Status retrieved'
      };
    } catch (error) {
      logger.error('Orange Money checkPaymentStatus error:', error);
      throw error;
    }
  }

  async validatePhoneNumber(phoneNumber) {
    const cleaned = phoneNumber.replace(/\D/g, '');
    // Orange Cameroon numbers start with 6 and are 9 digits
    return /^6[0-9]{8}$/.test(cleaned);
  }
}

module.exports = OrangeService;