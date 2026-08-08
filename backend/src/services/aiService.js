// src/services/aiService.js
const { logger } = require('../utils/logger');
const axios = require('axios');

class AIService {
  constructor() {
    this.apiKey = process.env.AI_API_KEY;
    this.apiUrl = process.env.AI_API_URL || 'https://api.telvo.ai';
    this.enabled = !!this.apiKey;
  }

  async estimateCost(category, description, urgency) {
    try {
      if (!this.enabled) {
        return this.fallbackEstimate(category, urgency);
      }

      const response = await axios.post(
        `${this.apiUrl}/estimate`,
        {
          category,
          description,
          urgency,
        },
        {
          headers: {
            'Authorization': `Bearer ${this.apiKey}`,
            'Content-Type': 'application/json',
          },
        }
      );

      return {
        success: true,
        estimatedCost: response.data.estimatedCost,
        minCost: response.data.minCost,
        maxCost: response.data.maxCost,
        currency: response.data.currency || 'XAF',
        details: response.data.details,
        confidence: response.data.confidence || 0.85,
      };
    } catch (error) {
      logger.error('AI estimate cost error:', error);
      return this.fallbackEstimate(category, urgency);
    }
  }

  fallbackEstimate(category, urgency) {
    const basePrices = {
      'Plumber': 15000,
      'Electrician': 20000,
      'Cleaner': 10000,
      'Painter': 12000,
      'Carpenter': 18000,
      'Mechanic': 25000,
      'Gardener': 8000,
      'Tutor': 5000,
      'Photographer': 20000,
      'Chef': 15000,
      'Babysitter': 5000,
      'Nanny': 8000,
    };

    let estimatedCost = basePrices[category] || 15000;
    if (urgency === 'emergency') {
      estimatedCost *= 1.5;
    }

    return {
      success: true,
      estimatedCost,
      minCost: estimatedCost * 0.8,
      maxCost: estimatedCost * 1.2,
      currency: 'XAF',
      details: `Estimated cost for ${category} service based on market rates`,
      confidence: 0.7,
      isFallback: true,
    };
  }

  async diagnoseImage(imageBase64) {
    try {
      if (!this.enabled) {
        return this.fallbackDiagnose(imageBase64);
      }

      const response = await axios.post(
        `${this.apiUrl}/diagnose`,
        {
          image: imageBase64,
        },
        {
          headers: {
            'Authorization': `Bearer ${this.apiKey}`,
            'Content-Type': 'application/json',
          },
        }
      );

      return {
        success: true,
        issue: response.data.issue,
        severity: response.data.severity,
        category: response.data.category,
        estimatedRepairTime: response.data.estimatedRepairTime,
        urgency: response.data.urgency,
        recommendations: response.data.recommendations,
        confidence: response.data.confidence || 0.8,
      };
    } catch (error) {
      logger.error('AI diagnose image error:', error);
      return this.fallbackDiagnose(imageBase64);
    }
  }

  fallbackDiagnose(imageBase64) {
    return {
      success: true,
      issue: 'Issue detected',
      severity: 'Medium',
      category: 'General',
      estimatedRepairTime: 2,
      urgency: 'Today',
      recommendations: [
        'Contact a professional for inspection',
        'Take photos of the issue from different angles',
        'Describe the problem in detail',
      ],
      confidence: 0.5,
      isFallback: true,
    };
  }

  async recommendProfessionals(category, location, budget) {
    try {
      if (!this.enabled) {
        return this.fallbackRecommendation(category, location);
      }

      const response = await axios.post(
        `${this.apiUrl}/recommend`,
        {
          category,
          location,
          budget,
        },
        {
          headers: {
            'Authorization': `Bearer ${this.apiKey}`,
            'Content-Type': 'application/json',
          },
        }
      );

      return {
        success: true,
        professionals: response.data.professionals,
        total: response.data.total,
        confidence: response.data.confidence || 0.85,
      };
    } catch (error) {
      logger.error('AI recommend professionals error:', error);
      return this.fallbackRecommendation(category, location);
    }
  }

  fallbackRecommendation(category, location) {
    return {
      success: true,
      professionals: [
        {
          name: 'Top Professional',
          rating: 4.8,
          distance: '1.5km',
          price: 15000,
          availability: 'Today',
          verified: true,
        },
        {
          name: 'Experienced Pro',
          rating: 4.6,
          distance: '2.8km',
          price: 12000,
          availability: 'Tomorrow',
          verified: true,
        },
        {
          name: 'Budget Friendly',
          rating: 4.3,
          distance: '4.2km',
          price: 9000,
          availability: 'Today',
          verified: false,
        },
      ],
      total: 3,
      confidence: 0.6,
      isFallback: true,
    };
  }

  async summarizeChat(messages) {
    try {
      if (!this.enabled) {
        return this.fallbackSummarize(messages);
      }

      const response = await axios.post(
        `${this.apiUrl}/summarize`,
        {
          messages,
        },
        {
          headers: {
            'Authorization': `Bearer ${this.apiKey}`,
            'Content-Type': 'application/json',
          },
        }
      );

      return {
        success: true,
        summary: response.data.summary,
        keyPoints: response.data.keyPoints,
        sentiment: response.data.sentiment,
        actionItems: response.data.actionItems,
      };
    } catch (error) {
      logger.error('AI summarize chat error:', error);
      return this.fallbackSummarize(messages);
    }
  }

  fallbackSummarize(messages) {
    return {
      success: true,
      summary: 'Conversation summary',
      keyPoints: [
        'Customer requested a service',
        'Professional provided information',
        'Details were discussed',
        'Next steps agreed upon',
      ],
      sentiment: 'Positive',
      actionItems: [
        'Follow up on the conversation',
        'Confirm details with the professional',
        'Complete the booking process',
      ],
      isFallback: true,
    };
  }

  async translateMessage(message, targetLanguage) {
    try {
      if (!this.enabled) {
        return this.fallbackTranslate(message, targetLanguage);
      }

      const response = await axios.post(
        `${this.apiUrl}/translate`,
        {
          message,
          targetLanguage,
        },
        {
          headers: {
            'Authorization': `Bearer ${this.apiKey}`,
            'Content-Type': 'application/json',
          },
        }
      );

      return {
        success: true,
        original: message,
        translated: response.data.translated,
        language: targetLanguage,
        confidence: response.data.confidence || 0.9,
      };
    } catch (error) {
      logger.error('AI translate message error:', error);
      return this.fallbackTranslate(message, targetLanguage);
    }
  }

  fallbackTranslate(message, targetLanguage) {
    const translations = {
      'en': message,
      'fr': message,
      'es': message,
      'pt': message,
    };

    return {
      success: true,
      original: message,
      translated: translations[targetLanguage] || message,
      language: targetLanguage,
      confidence: 0.5,
      isFallback: true,
    };
  }
}

module.exports = AIService;