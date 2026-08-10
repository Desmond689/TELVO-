// src/services/storageService.ts
const MAX_FILE_BYTES = 8 * 1024 * 1024; // 8MB
const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp'];

const CLOUDINARY_CLOUD_NAME = import.meta.env.VITE_CLOUDINARY_CLOUD_NAME || 'rxtcnv16';
const CLOUDINARY_UPLOAD_PRESET = import.meta.env.VITE_CLOUDINARY_UPLOAD_PRESET || '';

function getCloudinaryUploadUrl() {
  return `https://api.cloudinary.com/v1_1/${CLOUDINARY_CLOUD_NAME}/image/upload`;
}

export async function uploadImage(
  file: File,
  path: string,
  onProgress?: (pct: number) => void
): Promise<string> {
  if (!ALLOWED_TYPES.includes(file.type)) {
    throw new Error('Only JPG, PNG, or WEBP images are allowed.');
  }
  if (file.size > MAX_FILE_BYTES) {
    throw new Error('Images must be smaller than 8MB.');
  }
  if (!CLOUDINARY_UPLOAD_PRESET) {
    throw new Error('Cloudinary upload preset is not configured.');
  }

  const formData = new FormData();
  formData.append('file', file);
  formData.append('upload_preset', CLOUDINARY_UPLOAD_PRESET);
  formData.append('folder', path);

  // Use XHR (not fetch) so we can report real upload progress to the UI.
  return new Promise<string>((resolve, reject) => {
    const xhr = new XMLHttpRequest();
    xhr.open('POST', getCloudinaryUploadUrl());

    xhr.upload.onprogress = (event) => {
      if (event.lengthComputable && onProgress) {
        onProgress(Math.round((event.loaded / event.total) * 100));
      }
    };

    xhr.onload = () => {
      if (xhr.status < 200 || xhr.status >= 300) {
        reject(new Error(`Cloudinary upload failed: ${xhr.responseText || xhr.status}`));
        return;
      }
      try {
        const result = JSON.parse(xhr.responseText);
        if (!result.secure_url) {
          reject(new Error('Cloudinary upload succeeded but no URL was returned.'));
          return;
        }
        onProgress?.(100);
        resolve(result.secure_url as string);
      } catch {
        reject(new Error('Cloudinary returned an unexpected response.'));
      }
    };

    xhr.onerror = () => reject(new Error('Network error while uploading the image. Check your connection and try again.'));
    xhr.ontimeout = () => reject(new Error('The upload timed out. Try again on a stronger connection.'));
    xhr.timeout = 60000;

    xhr.send(formData);
  });
}

const MAX_APK_BYTES = 150 * 1024 * 1024; // 150MB

export async function uploadApk(file: File, versionCode: number, onProgress?: (pct: number) => void): Promise<{ url: string; sizeBytes: number }> {
  if (!file.name.toLowerCase().endsWith('.apk')) {
    throw new Error('Please choose a .apk file.');
  }
  if (file.size > MAX_APK_BYTES) {
    throw new Error('APK must be smaller than 150MB.');
  }

  // GitHub Releases is the recommended source for APK distribution; if the admin
  // wants to upload an APK from the site, it is uploaded via Cloudinary instead of
  // Firebase Storage.
  if (!CLOUDINARY_UPLOAD_PRESET) {
    throw new Error('Cloudinary upload preset is not configured.');
  }

  const formData = new FormData();
  formData.append('file', file);
  formData.append('upload_preset', CLOUDINARY_UPLOAD_PRESET);
  formData.append('folder', `app_releases/${versionCode}`);

  onProgress?.(10);
  const response = await fetch(getCloudinaryUploadUrl(), {
    method: 'POST',
    body: formData,
  });
  onProgress?.(100);

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Cloudinary APK upload failed: ${text}`);
  }

  const result = await response.json();
  if (!result.secure_url) {
    throw new Error('Cloudinary APK upload succeeded but no download URL was returned.');
  }

  return { url: result.secure_url as string, sizeBytes: file.size };
}
