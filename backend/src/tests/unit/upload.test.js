const express = require('express');
const request = require('supertest');

jest.mock('cloudinary', () => ({
  v2: {
    config: jest.fn(),
    uploader: {
      upload: jest.fn().mockResolvedValue({
        secure_url: 'https://example.com/image.jpg',
        public_id: 'test-image',
        format: 'jpg',
      }),
    },
  },
}));

const cloudinary = require('cloudinary').v2;

const app = express();
app.use(express.json());
app.use('/api/uploads', require('../../routes/uploadRoutes'));

describe('upload routes', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    delete process.env.CLOUDINARY_URL;
    delete process.env.CLOUDINARY_CLOUD_NAME;
    delete process.env.CLOUDINARY_API_KEY;
    delete process.env.CLOUDINARY_API_SECRET;
    jest.resetModules();
  });

  it('returns a clear error if Cloudinary is not configured', async () => {
    const testApp = express();
    testApp.use(express.json());
    testApp.use('/api/uploads', require('../../routes/uploadRoutes'));

    const response = await request(testApp)
      .post('/api/uploads/image')
      .attach('file', Buffer.from('test-image'), { filename: 'test.png', contentType: 'image/png' });

    expect(response.status).toBe(500);
    expect(response.body.message).toContain('Cloudinary');
    expect(cloudinary.uploader.upload).not.toHaveBeenCalled();
  });
});
