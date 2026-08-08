// src/services/momoService.js
const { logger } = require('../utils/logger');
const axios = require('axios');

class MomoService {
  constructor() {
    this.apiKey = process.env.MTN_MOMO_API_KEY;
    this.apiSecret = process.env.MTN_MOMO_API_SECRET;
    this.baseUrl = process.env.MTN_MOMO_API_URL || 'https://sandbox.mtn.com';
    this.accessToken = null;
    this.tokenExpiry = null;
  }

  async getAccessToken() {
    try {
      if (this.accessToken && this.tokenExpiry && new Date() < this.tokenExpiry) {
        return this.accessToken;
      }

      const response = await axios.post(
        `${this.baseUrl}/oauth/token`,
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
      logger.error('MTN MoMo getAccessToken error:', error);
      throw error;
    }
  }

  async requestPayment(phoneNumber, amount, reference) {
    try {
      const token = await this.getAccessToken();
      
      const response = await axios.post(
        `${this.baseUrl}/payment/request`,
        {
          amount,
          currency: 'XAF',
          externalId: reference,
          payer: {
            partyIdType: 'MSISDN',
            partyId: phoneNumber.replace('+', ''),
          },
          payerMessage: `Payment for job ${reference}`,
          payeeNote: 'Thank you for using Telvo',
        },
        {
          headers: {
            'Authorization': `Bearer ${token}`,
            'X-Reference-Id': reference,
            'Content-Type': 'application/json',
          }
        }
      );

      return {
        success: true,
        transactionId: response.headers['x-reference-id'],
        status: 'pending',
        message: 'Payment request sent'
      };
    } catch (error) {
      logger.error('MTN MoMo requestPayment error:', error);
      throw error;
    }
  }

  async checkPaymentStatus(reference) {
    try {
      const token = await this.getAccessToken();
      
      const response = await axios.get(
        `${this.baseUrl}/payment/request/${reference}`,
        {
          headers: {
            'Authorization': `Bearer ${token}`,
            'X-Reference-Id': reference,
          }
        }
      );

      return {
        success: true,
        status: response.data.status,
        message: response.data.message || 'Status retrieved'
      };
    } catch (error) {
      logger.error('MTN MoMo checkPaymentStatus error:', error);
      throw error;
    }
  }

  async validatePhoneNumber(phoneNumber) {
    const cleaned = phoneNumber.replace(/\D/g, '');
    // MTN Cameroon numbers start with 6 or 7 and are 9 digits
    return /^[67][0-9]{8}$/.test(cleaned);
  }
}

module.exports = MomoService;