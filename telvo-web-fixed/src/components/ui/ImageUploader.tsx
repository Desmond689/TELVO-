import { useCallback, useRef, useState } from 'react';
import { Camera, ImagePlus, X, RefreshCw } from 'lucide-react';
import clsx from 'clsx';
import { uploadImage } from '@/services/storageService';

const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
const MAX_FILE_BYTES = 8 * 1024 * 1024;

interface ImageUploaderProps {
  /** Cloudinary folder/path to store this image under, e.g. `avatars/${userId}`. */
  path: string;
  /** Currently saved image URL, if any. */
  value?: string | null;
  /** Called with the new URL once the upload succeeds. */
  onUploaded: (url: string) => void;
  /** Called with a human-readable message if validation or upload fails. */
  onError?: (message: string) => void;
  /** 'avatar' renders a round preview with a small camera badge; 'card' renders a
   *  bigger square/rectangle dropzone for job photos, ID docs, portfolio, etc. */
  variant?: 'avatar' | 'card';
  size?: number; // px, avatar variant only
  label?: string; // card variant only
  disabled?: boolean;
}

export function ImageUploader({
  path,
  value,
  onUploaded,
  onError,
  variant = 'card',
  size = 88,
  label = 'Upload a photo',
  disabled,
}: ImageUploaderProps) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [preview, setPreview] = useState<string | null>(null);
  const [progress, setProgress] = useState<number | null>(null);
  const [isDragging, setIsDragging] = useState(false);

  const displayed = preview ?? value ?? null;
  const isUploading = progress !== null;

  const runUpload = useCallback(
    async (file: File) => {
      if (!ALLOWED_TYPES.includes(file.type)) {
        onError?.('Only JPG, PNG, or WEBP images are allowed.');
        return;
      }
      if (file.size > MAX_FILE_BYTES) {
        onError?.('Images must be smaller than 8MB.');
        return;
      }

      const objectUrl = URL.createObjectURL(file);
      setPreview(objectUrl);
      setProgress(0);
      try {
        const url = await uploadImage(file, path, (pct) => setProgress(pct));
        onUploaded(url);
      } catch (err) {
        setPreview(null);
        onError?.(err instanceof Error ? err.message : 'Upload failed. Please try again.');
      } finally {
        setProgress(null);
        URL.revokeObjectURL(objectUrl);
      }
    },
    [path, onUploaded, onError]
  );

  const handleFiles = useCallback(
    (files: FileList | null) => {
      const file = files?.[0];
      if (file) runUpload(file);
    },
    [runUpload]
  );

  const dragHandlers = {
    onDragOver: (e: React.DragEvent) => {
      e.preventDefault();
      if (!disabled) setIsDragging(true);
    },
    onDragLeave: () => setIsDragging(false),
    onDrop: (e: React.DragEvent) => {
      e.preventDefault();
      setIsDragging(false);
      if (!disabled) handleFiles(e.dataTransfer.files);
    },
  };

  const hiddenInput = (
    <input
      ref={inputRef}
      type="file"
      accept="image/jpeg,image/png,image/webp"
      className="hidden"
      disabled={disabled}
      onChange={(e) => {
        handleFiles(e.target.files);
        e.target.value = '';
      }}
    />
  );

  if (variant === 'avatar') {
    return (
      <div className="inline-flex flex-col items-center gap-2">
        <button
          type="button"
          disabled={disabled}
          onClick={() => inputRef.current?.click()}
          className="relative rounded-full overflow-hidden group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500 focus-visible:ring-offset-2 disabled:cursor-not-allowed"
          style={{ width: size, height: size }}
        >
          <span className="flex items-center justify-center w-full h-full bg-brand-100 text-brand-700 text-2xl font-bold overflow-hidden">
            {displayed ? (
              <img src={displayed} alt="" className="w-full h-full object-cover" />
            ) : (
              <Camera size={size * 0.32} />
            )}
          </span>
          {!disabled && (
            <span className="absolute inset-0 bg-black/0 group-hover:bg-black/40 transition-colors flex items-center justify-center opacity-0 group-hover:opacity-100">
              <Camera size={18} className="text-white" />
            </span>
          )}
          {isUploading && (
            <span className="absolute inset-0 bg-black/50 flex items-center justify-center">
              <RefreshCw size={18} className="text-white animate-spin" />
            </span>
          )}
        </button>
        {isUploading && (
          <div className="w-full max-w-[6rem] h-1 rounded-full bg-ink-100 overflow-hidden">
            <div className="h-full bg-brand-500 transition-all" style={{ width: `${progress}%` }} />
          </div>
        )}
        {hiddenInput}
      </div>
    );
  }

  return (
    <div className="space-y-2">
      <div
        {...dragHandlers}
        onClick={() => !disabled && !displayed && inputRef.current?.click()}
        className={clsx(
          'relative rounded-xl border-2 border-dashed transition-colors overflow-hidden',
          disabled ? 'cursor-not-allowed opacity-60 border-ink-200' : 'cursor-pointer',
          isDragging ? 'border-brand-500 bg-brand-50' : 'border-ink-200 hover:border-brand-400 hover:bg-ink-50',
          displayed ? 'aspect-video' : 'aspect-[3/1.4]'
        )}
      >
        {displayed ? (
          <>
            <img src={displayed} alt="" className="w-full h-full object-cover" />
            {!disabled && !isUploading && (
              <button
                type="button"
                onClick={(e) => {
                  e.stopPropagation();
                  setPreview(null);
                  onUploaded('');
                }}
                className="absolute top-2 right-2 w-7 h-7 rounded-full bg-black/60 text-white flex items-center justify-center hover:bg-black/80"
                aria-label="Remove photo"
              >
                <X size={14} />
              </button>
            )}
            {!disabled && !isUploading && (
              <button
                type="button"
                onClick={(e) => {
                  e.stopPropagation();
                  inputRef.current?.click();
                }}
                className="absolute bottom-2 right-2 h-8 px-3 rounded-lg bg-white/90 text-ink-800 text-xs font-semibold flex items-center gap-1.5 hover:bg-white shadow-sm"
              >
                <RefreshCw size={12} /> Replace
              </button>
            )}
          </>
        ) : (
          <div className="w-full h-full flex flex-col items-center justify-center gap-1.5 text-ink-400 px-4 text-center">
            <ImagePlus size={22} />
            <span className="text-sm font-medium text-ink-600">{label}</span>
            <span className="text-xs">Drag & drop or click to browse · JPG, PNG, WEBP · up to 8MB</span>
          </div>
        )}

        {isUploading && (
          <div className="absolute inset-0 bg-black/50 flex flex-col items-center justify-center gap-2 text-white">
            <RefreshCw size={20} className="animate-spin" />
            <div className="w-2/3 h-1.5 rounded-full bg-white/30 overflow-hidden">
              <div className="h-full bg-white transition-all" style={{ width: `${progress}%` }} />
            </div>
            <span className="text-xs font-medium">{progress}%</span>
          </div>
        )}
      </div>
      {hiddenInput}
    </div>
  );
}
