// src/config/redis.js
const redis = require('redis');
const { logger } = require('../utils/logger');

let redisClient = null;

const initializeRedis = async () => {
  try {
    if (process.env.REDIS_URL) {
      redisClient = redis.createClient({
        url: process.env.REDIS_URL,
        password: process.env.REDIS_PASSWORD,
      });

      redisClient.on('error', (error) => {
        logger.error('Redis Client Error:', error);
      });

      redisClient.on('connect', () => {
        logger.info('🔴 Redis connected successfully');
      });

      await redisClient.connect();
    } else {
      logger.info('📝 Redis not configured - using memory cache fallback');
    }
  } catch (error) {
    logger.error('Redis initialization error:', error);
  }
};

const getRedisClient = () => {
  return redisClient;
};

const cacheSet = async (key, value, expireSeconds = 3600) => {
  try {
    if (redisClient) {
      await redisClient.set(key, JSON.stringify(value), {
        EX: expireSeconds,
      });
      return true;
    }
    return false;
  } catch (error) {
    logger.error('Redis set error:', error);
    return false;
  }
};

const cacheGet = async (key) => {
  try {
    if (redisClient) {
      const value = await redisClient.get(key);
      if (value) {
        return JSON.parse(value);
      }
    }
    return null;
  } catch (error) {
    logger.error('Redis get error:', error);
    return null;
  }
};

const cacheDelete = async (key) => {
  try {
    if (redisClient) {
      await redisClient.del(key);
      return true;
    }
    return false;
  } catch (error) {
    logger.error('Redis delete error:', error);
    return false;
  }
};

module.exports = {
  initializeRedis,
  getRedisClient,
  cacheSet,
  cacheGet,
  cacheDelete,
};