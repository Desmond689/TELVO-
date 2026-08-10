import { useState } from 'react';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Textarea } from '@/components/ui/Textarea';
import { Badge } from '@/components/ui/Badge';
import { Toast } from '@/components/ui/Toast';
import { ImageUploader } from '@/components/ui/ImageUploader';
import { useAuth } from '@/contexts/AuthContext';
import { db, COLLECTIONS } from '@/lib/firebase';
import { doc, updateDoc } from 'firebase/firestore';

export function ProfessionalProfileEdit() {
  const { profile } = useAuth();
  const [description, setDescription] = useState(profile?.description || '');
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [idUrl, setIdUrl] = useState<string | null>(null);
  const [selfieUrl, setSelfieUrl] = useState<string | null>(null);
  const [submittingVerification, setSubmittingVerification] = useState(false);
  const [toast, setToast] = useState<{ message: string; tone: 'success' | 'error' } | null>(null);

  if (!profile) return null;

  const handlePhotoUploaded = async (url: string) => {
    try {
      await updateDoc(doc(db, COLLECTIONS.USERS, profile.id), { profilePhoto: url });
      setToast({ message: 'Profile photo updated.', tone: 'success' });
    } catch {
      setToast({ message: 'Photo uploaded but could not be saved to your profile. Try again.', tone: 'error' });
    }
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      await updateDoc(doc(db, COLLECTIONS.USERS, profile.id), { description });
      setSaved(true);
      setTimeout(() => setSaved(false), 2000);
    } catch {
      setToast({ message: 'Could not save your changes. Please try again.', tone: 'error' });
    } finally {
      setSaving(false);
    }
  };

  const submitVerification = async () => {
    if (!idUrl || !selfieUrl) return;
    setSubmittingVerification(true);
    try {
      // Documents are uploaded to a private storage path only readable by
      // the user and admins (see storage.rules in the main repo). They are
      // never exposed on the public profile.
      await updateDoc(doc(db, COLLECTIONS.USERS, profile.id), {
        verificationStatus: 'pending',
        verificationIdUrl: idUrl,
        verificationSelfieUrl: selfieUrl,
      });
      setToast({ message: 'Submitted for verification. We\u2019ll review it shortly.', tone: 'success' });
    } catch {
      setToast({ message: 'Could not submit for verification. Please try again.', tone: 'error' });
    } finally {
      setSubmittingVerification(false);
    }
  };

  const verificationLabel = profile.isVerified ? 'Verified' : (profile as any).verificationStatus === 'pending' ? 'Pending review' : 'Not verified';

  return (
    <div className="max-w-xl space-y-6">
      <h1 className="text-2xl font-bold text-ink-900">Profile</h1>
      <Card className="p-6 space-y-5">
        <div className="flex items-center gap-4">
          <ImageUploader
            variant="avatar"
            size={80}
            path={`avatars/${profile.id}`}
            value={profile.profilePhoto}
            onUploaded={handlePhotoUploaded}
            onError={(message) => setToast({ message, tone: 'error' })}
          />
          <div className="text-sm text-ink-500">
            <p className="font-medium text-ink-800">{profile.fullName}</p>
            <p>Click your photo to change it</p>
          </div>
        </div>
        <Textarea label="About you" value={description} onChange={(e) => setDescription(e.target.value)} />
        <div className="flex items-center gap-3">
          <Button onClick={handleSave} loading={saving}>Save changes</Button>
          {saved && <span className="text-sm text-brand-600">Saved ✓</span>}
        </div>
      </Card>

      <Card className="p-6">
        <div className="flex items-center justify-between mb-4">
          <h2 className="font-semibold text-ink-900">Verification</h2>
          <Badge tone={profile.isVerified ? 'green' : 'amber'}>{verificationLabel}</Badge>
        </div>
        {!profile.isVerified && (
          <div className="space-y-4">
            <p className="text-sm text-ink-500">Submit an ID and a selfie to get your verified badge. Documents are private and only visible to TELVO's verification team.</p>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-sm font-medium text-ink-700 mb-1.5">Government ID</label>
                <ImageUploader
                  path={`verification/${profile.id}/id`}
                  value={idUrl}
                  onUploaded={setIdUrl}
                  onError={(message) => setToast({ message, tone: 'error' })}
                  label="Upload your ID"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-ink-700 mb-1.5">Selfie</label>
                <ImageUploader
                  path={`verification/${profile.id}/selfie`}
                  value={selfieUrl}
                  onUploaded={setSelfieUrl}
                  onError={(message) => setToast({ message, tone: 'error' })}
                  label="Upload a selfie"
                />
              </div>
            </div>
            <Button disabled={!idUrl || !selfieUrl} loading={submittingVerification} onClick={submitVerification}>Submit for verification</Button>
          </div>
        )}
      </Card>
      <Toast
        open={!!toast}
        message={toast?.message || ''}
        tone={toast?.tone || 'info'}
        onClose={() => setToast(null)}
      />
    </div>
  );
}
