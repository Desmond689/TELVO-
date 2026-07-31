// src/services/emailService.js
const { logger } = require('../utils/logger');
const nodemailer = require('nodemailer');

class EmailService {
  constructor() {
    this.transporter = null;
    this.initializeTransporter();
  }

  initializeTransporter() {
    try {
      if (process.env.EMAIL_HOST && process.env.EMAIL_USER && process.env.EMAIL_PASS) {
        this.transporter = nodemailer.createTransport({
          host: process.env.EMAIL_HOST,
          port: process.env.EMAIL_PORT || 587,
          secure: process.env.EMAIL_SECURE === 'true',
          auth: {
            user: process.env.EMAIL_USER,
            pass: process.env.EMAIL_PASS,
          },
        });
        logger.info('📧 Email service initialized');
      } else {
        logger.warn('📧 Email service not configured - using console mode');
      }
    } catch (error) {
      logger.error('Email service initialization error:', error);
    }
  }

  async sendEmail(to, subject, htmlContent, textContent = null) {
    try {
      if (!this.transporter) {
        logger.info(`📧 Email (console mode): to=${to}, subject=${subject}`);
        return { success: true, messageId: `console-${Date.now()}` };
      }

      const mailOptions = {
        from: process.env.EMAIL_FROM || process.env.EMAIL_USER,
        to,
        subject,
        html: htmlContent,
        text: textContent || htmlContent.replace(/<[^>]*>/g, ''),
      };

      const info = await this.transporter.sendMail(mailOptions);
      logger.info(`📧 Email sent to ${to}: ${info.messageId}`);
      return { success: true, messageId: info.messageId };
    } catch (error) {
      logger.error('Email sending error:', error);
      throw error;
    }
  }

  async sendVerificationEmail(email, name, verificationLink) {
    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #00C853; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; background: #f9f9f9; }
          .button { display: inline-block; padding: 12px 24px; background: #00C853; color: white; text-decoration: none; border-radius: 4px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Telvo</h1>
            <p>Trusted workers. Real solutions.</p>
          </div>
          <div class="content">
            <h2>Welcome to Telvo, ${name}!</h2>
            <p>Thank you for signing up. Please verify your email address to get started.</p>
            <p><a href="${verificationLink}" class="button">Verify Email</a></p>
            <p>If the button doesn't work, copy and paste this link into your browser:</p>
            <p><a href="${verificationLink}">${verificationLink}</a></p>
          </div>
        </div>
      </body>
      </html>
    `;

    return this.sendEmail(email, 'Welcome to Telvo - Verify Your Email', html);
  }

  async sendPasswordResetEmail(email, name, resetLink) {
    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #00C853; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; background: #f9f9f9; }
          .button { display: inline-block; padding: 12px 24px; background: #00C853; color: white; text-decoration: none; border-radius: 4px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Telvo</h1>
            <p>Trusted workers. Real solutions.</p>
          </div>
          <div class="content">
            <h2>Reset Your Password</h2>
            <p>Hello ${name},</p>
            <p>We received a request to reset your password. Click the button below to create a new password.</p>
            <p><a href="${resetLink}" class="button">Reset Password</a></p>
            <p>If you didn't request this, please ignore this email.</p>
            <p>This link will expire in 1 hour.</p>
          </div>
        </div>
      </body>
      </html>
    `;

    return this.sendEmail(email, 'Telvo - Reset Your Password', html);
  }

  async sendJobNotificationEmail(email, name, jobData) {
    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #00C853; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; background: #f9f9f9; }
          .job-detail { background: white; padding: 15px; border-radius: 4px; margin: 10px 0; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Telvo</h1>
            <p>Trusted workers. Real solutions.</p>
          </div>
          <div class="content">
            <h2>New Job Available, ${name}!</h2>
            <div class="job-detail">
              <p><strong>Category:</strong> ${jobData.category}</p>
              <p><strong>Budget:</strong> XAF ${jobData.budget}</p>
              <p><strong>Location:</strong> ${jobData.address || 'Not specified'}</p>
              <p><strong>Urgency:</strong> ${jobData.urgency}</p>
            </div>
            <p><a href="https://telvo.app/jobs/${jobData.id}" class="button">View Job</a></p>
          </div>
        </div>
      </body>
      </html>
    `;

    return this.sendEmail(email, 'New Job Available on Telvo', html);
  }

  async sendPaymentConfirmationEmail(email, name, paymentData) {
    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #00C853; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; background: #f9f9f9; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Telvo</h1>
            <p>Trusted workers. Real solutions.</p>
          </div>
          <div class="content">
            <h2>Payment Confirmed, ${name}!</h2>
            <p>Your payment of <strong>XAF ${paymentData.amount}</strong> has been processed successfully.</p>
            <p>Transaction ID: ${paymentData.transactionId}</p>
            <p>Job: ${paymentData.jobId}</p>
            <p>Thank you for using Telvo!</p>
          </div>
        </div>
      </body>
      </html>
    `;

    return this.sendEmail(email, 'Telvo - Payment Confirmation', html);
  }
}

module.exports = EmailService;