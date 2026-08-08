// src/controllers/analyticsController.js
const { logger } = require('../utils/logger');
const { successResponse, errorResponse } = require('../utils/responseHandler');
const { getFirestore } = require('../config/firebase');

const getPlatformAnalytics = async (req, res) => {
  try {
    const db = getFirestore();
    
    // In production, aggregate data from Firestore
    const analytics = {
      overview: {
        totalUsers: 1250,
        activeUsers: 340,
        totalJobs: 845,
        completionRate: 94,
        averageRating: 4.7
      },
      revenue: {
        daily: 450000,
        weekly: 3150000,
        monthly: 12450000,
        yearly: 149400000
      },
      growth: {
        users: { daily: 15, weekly: 45, monthly: 120 },
        jobs: { daily: 8, weekly: 25, monthly: 65 },
        revenue: { daily: 12, weekly: 8, monthly: 5 }
      },
      categories: {
        'Plumber': 150,
        'Electrician': 120,
        'Cleaner': 100,
        'Painter': 80,
        'Carpenter': 60
      },
      locations: {
        'Yaoundé': 45,
        'Douala': 30,
        'Bamenda': 15,
        'Bafoussam': 10
      },
      topProfessionals: [
        { name: 'Emmanuel', rating: 4.8, jobs: 130 },
        { name: 'Franck', rating: 4.7, jobs: 80 },
        { name: 'Junior', rating: 4.8, jobs: 80 }
      ]
    };
    
    return successResponse(res, analytics);
  } catch (error) {
    logger.error('Get analytics error:', error);
    return errorResponse(res, 'Failed to get analytics', 500);
  }
};

const getUserAnalytics = async (req, res) => {
  try {
    const { userId } = req.params;
    
    // In production, get user-specific analytics
    const analytics = {
      user: {
        id: userId,
        name: 'John Doe',
        type: 'professional'
      },
      stats: {
        jobs: 45,
        rating: 4.8,
        responseRate: 95,
        responseTime: 15,
        earnings: 675000,
        completionRate: 98
      },
      trends: {
        jobs: [12, 15, 8, 10, 12, 15, 8],
        earnings: [15000, 25000, 12000, 18000, 15000, 25000, 12000],
        ratings: [4.5, 4.8, 4.7, 4.9, 4.8, 4.7, 4.8]
      },
      recentJobs: [
        { id: '1', category: 'Plumbing', status: 'completed', amount: 15000 },
        { id: '2', category: 'Electrical', status: 'completed', amount: 25000 },
        { id: '3', category: 'Cleaning', status: 'in_progress', amount: 12000 }
      ]
    };
    
    return successResponse(res, analytics);
  } catch (error) {
    logger.error('Get user analytics error:', error);
    return errorResponse(res, 'Failed to get user analytics', 500);
  }
};

const getCategoryAnalytics = async (req, res) => {
  try {
    const { category } = req.params;
    
    // In production, get category-specific analytics
    const analytics = {
      category,
      stats: {
        totalJobs: 150,
        completionRate: 96,
        averageRating: 4.7,
        averagePrice: 15000,
        totalRevenue: 2250000
      },
      trends: {
        demand: [12, 18, 15, 20, 18, 22, 25],
        rating: [4.5, 4.6, 4.7, 4.8, 4.8, 4.7, 4.8],
        revenue: [180000, 270000, 225000, 300000, 270000, 330000, 375000]
      },
      topProfessionals: [
        { name: 'Emmanuel', jobs: 130, rating: 4.8 },
        { name: 'Pierre', jobs: 45, rating: 4.9 }
      ]
    };
    
    return successResponse(res, analytics);
  } catch (error) {
    logger.error('Get category analytics error:', error);
    return errorResponse(res, 'Failed to get category analytics', 500);
  }
};

const getRevenueAnalytics = async (req, res) => {
  try {
    const { period = 'month' } = req.query;
    
    // In production, calculate revenue analytics
    const analytics = {
      total: 12450000,
      breakdown: {
        'Commission': 1245000,
        'Subscriptions': 3000000,
        'Promotions': 500000,
        'Other': 500000
      },
      trends: {
        'Jan': 1000000,
        'Feb': 1100000,
        'Mar': 1200000,
        'Apr': 1150000,
        'May': 1300000,
        'Jun': 1350000,
        'Jul': 1400000,
        'Aug': 1450000,
        'Sep': 1500000,
        'Oct': 1500000,
        'Nov': 1550000,
        'Dec': 1600000
      },
      growth: 15,
      projections: {
        nextMonth: 1650000,
        nextQuarter: 5000000,
        nextYear: 20000000
      }
    };
    
    return successResponse(res, analytics);
  } catch (error) {
    logger.error('Get revenue analytics error:', error);
    return errorResponse(res, 'Failed to get revenue analytics', 500);
  }
};

module.exports = {
  getPlatformAnalytics,
  getUserAnalytics,
  getCategoryAnalytics,
  getRevenueAnalytics,
};