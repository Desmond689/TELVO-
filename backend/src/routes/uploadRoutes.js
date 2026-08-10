const express = require('express');
const fs = require('fs');
const path = require('path');
const cloudinary = require('cloudinary').v2;
const router = express.Router();
const { upload, handleUploadError } = require('../middleware/upload');
const { successResponse, errorResponse } = require('../utils/responseHandler');
const { logger } = require('../utils/logger');

const isCloudinaryConfigured = Boolean(
  process.env.CLOUDINARY_URL || (
    process.env.CLOUDINARY_CLOUD_NAME &&
    process.env.CLOUDINARY_API_KEY &&
    process.env.CLOUDINARY_API_SECRET
  )
);

if (isCloudinaryConfigured) {
  if (process.env.CLOUDINARY_URL) {
    cloudinary.config({ secure: true });
  } else {
    cloudinary.config({
      cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
      api_key: process.env.CLOUDINARY_API_KEY,
      api_secret: process.env.CLOUDINARY_API_SECRET,
      secure: true,
    });
  }
} else {
  logger.warn('Cloudinary is not configured; uploads will fail until environment variables are set.');
}

router.post('/image', upload.single('file'), async (req, res, next) => {
  try {
    if (!req.file) {
      return errorResponse(res, 'No file uploaded', 400);
    }

    if (!isCloudinaryConfigured) {
      return errorResponse(res, 'Image upload failed because Cloudinary is not configured', 500);
    }

    fs.mkdirSync('uploads', { recursive: true });

    const uploadResult = await cloudinary.uploader.upload(req.file.path, {
      folder: req.body.folder || 'telvo/uploads',
      resource_type: 'auto',
      transformation: [{ quality: 'auto', fetch_format: 'auto' }],
    });

    try {
      fs.unlinkSync(req.file.path);
    } catch (cleanupError) {
      logger.warn(`Upload cleanup failed for ${req.file.path}: ${cleanupError.message}`);
    }

    return successResponse(
      res,
      {
        url: uploadResult.secure_url,
        publicId: uploadResult.public_id,
        format: uploadResult.format,
      },
      'Image uploaded successfully'
    );
  } catch (error) {
    logger.error('Upload route error:', error);
    return errorResponse(res, 'Image upload failed', 500);
  }
}, handleUploadError);

module.exports = router;
