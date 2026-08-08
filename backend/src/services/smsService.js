// src/services/smsService.js
const { logger } = require('../utils/logger');
const twilio = require('twilio');

class SMSService {
  constructor() {
    this.client = null;
    this.initializeClient();
  }

  initializeClient() {
    try {
      if (process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN) {
        this.client = twilio(
          process.env.TWILIO_ACCOUNT_SID,
          process.env.TWILIO_AUTH_TOKEN
        );
        logger.info('📱 SMS service initialized');
      } else {
        logger.warn('📱 SMS service not configured - using console mode');
      }
    } catch (error) {
      logger.error('SMS service initialization error:', error);
    }
  }

  async sendSMS(to, message) {
    try {
      if (!this.client) {
        logger.info(`📱 SMS (console mode): to=${to}, message=${message}`);
        return { success: true, sid: `console-${Date.now()}` };
      }

      const response = await this.client.messages.create({
        body: message,
        to: to,
        from: process.env.TWILIO_PHONE_NUMBER,
      });

      logger.info(`📱 SMS sent to ${to}: ${response.sid}`);
      return { success: true, sid: response.sid };
    } catch (error) {
      logger.error('SMS sending error:', error);
      throw error;
    }
  }

  async sendOTP(to, otp) {
    const message = `Your Telvo verification code is: ${otp}. This code will expire in 10 minutes.`;
    return this.sendSMS(to, message);
  }

  async sendJobNotification(to, jobData) {
    const message = `New job available: ${jobData.category} - XAF ${jobData.budget}. View at https://telvo.app/jobs/${jobData.id}`;
    return this.sendSMS(to, message);
  }

  async sendQuoteAccepted(to, jobData) {
    const message = `Your quote has been accepted for job: ${jobData.category}. Please check the app for details.`;
    return this.sendSMS(to, message);
  }

  async sendPaymentConfirmation(to, amount) {
    const message = `Payment of XAF ${amount} received. Thank you for using Telvo!`;
    return this.sendSMS(to, message);
  }

  async sendEmergencyAlert(to, jobData) {
    const message = `URGENT: Emergency job request - ${jobData.category}. Please respond immediately.`;
    return this.sendSMS(to, message);
  }

  async validatePhoneNumber(phoneNumber) {
    // Basic validation
    const cleaned = phoneNumber.replace(/\D/g, '');
    return cleaned.length >= 8 && cleaned.length <= 15;
  }
}

module.exports = SMSService;