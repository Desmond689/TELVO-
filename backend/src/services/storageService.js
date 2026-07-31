// src/services/storageService.js
const { getStorage } = require('../config/firebase');
const { logger } = require('../utils/logger');
const sharp = require('sharp');
const { v4: uuidv4 } = require('uuid');

class StorageService {
  constructor() {
    this.storage = getStorage();
    this.bucket = this.storage.bucket();
  }

  async uploadFile(fileBuffer, fileName, folder = 'uploads', metadata = {}) {
    try {
      const uniqueId = uuidv4();
      const path = `${folder}/${uniqueId}-${fileName}`;
      const file = this.bucket.file(path);

      // Compress image if it's an image file
      let buffer = fileBuffer;
      const isImage = /\.(jpg|jpeg|png|gif|webp)$/i.test(fileName);
      if (isImage) {
        buffer = await sharp(fileBuffer)
          .resize(1200, 1200, { fit: 'inside', withoutEnlargement: true })
          .jpeg({ quality: 80 })
          .toBuffer();
      }

      await file.save(buffer, {
        metadata: {
          contentType: isImage ? 'image/jpeg' : 'application/octet-stream',
          ...metadata,
        },
      });

      const [url] = await file.getSignedUrl({
        action: 'read',
        expires: '03-01-2025',
      });

      logger.info(`📁 File uploaded: ${path}`);
      return {
        success: true,
        url,
        path,
        name: fileName,
      };
    } catch (error) {
      logger.error('Upload file error:', error);
      throw error;
    }
  }

  async uploadProfilePhoto(userId, fileBuffer) {
    return this.uploadFile(
      fileBuffer,
      `profile-${userId}.jpg`,
      `users/${userId}/profile`,
      { userId }
    );
  }

  async uploadJobPhotos(jobId, files) {
    const urls = [];
    for (const file of files) {
      const result = await this.uploadFile(
        file.buffer,
        file.originalname,
        `jobs/${jobId}`,
        { jobId }
      );
      urls.push(result.url);
    }
    return urls;
  }

  async uploadPortfolioPhoto(userId, fileBuffer) {
    return this.uploadFile(
      fileBuffer,
      `portfolio-${Date.now()}.jpg`,
      `users/${userId}/portfolio`,
      { userId }
    );
  }

  async uploadCertificate(userId, fileBuffer, originalName) {
    return this.uploadFile(
      fileBuffer,
      originalName,
      `users/${userId}/certificates`,
      { userId }
    );
  }

  async deleteFile(path) {
    try {
      const file = this.bucket.file(path);
      await file.delete();
      logger.info(`📁 File deleted: ${path}`);
      return { success: true };
    } catch (error) {
      logger.error('Delete file error:', error);
      throw error;
    }
  }

  async deleteFolder(prefix) {
    try {
      const [files] = await this.bucket.getFiles({ prefix });
      for (const file of files) {
        await file.delete();
      }
      logger.info(`📁 Folder deleted: ${prefix}`);
      return { success: true };
    } catch (error) {
      logger.error('Delete folder error:', error);
      throw error;
    }
  }

  async getFileUrl(path) {
    try {
      const [url] = await this.bucket.file(path).getSignedUrl({
        action: 'read',
        expires: '03-01-2025',
      });
      return { success: true, url };
    } catch (error) {
      logger.error('Get file URL error:', error);
      throw error;
    }
  }

  async listFiles(prefix) {
    try {
      const [files] = await this.bucket.getFiles({ prefix });
      const fileList = files.map(file => ({
        name: file.name,
        size: file.metadata.size,
        contentType: file.metadata.contentType,
        updated: file.metadata.updated,
      }));
      return { success: true, files: fileList };
    } catch (error) {
      logger.error('List files error:', error);
      throw error;
    }
  }
}

module.exports = StorageService;