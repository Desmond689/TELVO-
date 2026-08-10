import { useState } from 'react';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Select } from '@/components/ui/Select';
import { Toast } from '@/components/ui/Toast';
import { ImageUploader } from '@/components/ui/ImageUploader';
import { useAuth } from '@/contexts/AuthContext';
import { db, COLLECTIONS } from '@/lib/firebase';
import { doc, updateDoc } from 'firebase/firestore';
import { CAMEROON_CITIES } from '@/types';

export function CustomerProfile() {
  const { profile } = useAuth();
  const [fullName, setFullName] = useState(profile?.fullName || '');
  const [city, setCity] = useState(profile?.city || '');
  const [neighborhood, setNeighborhood] = useState(profile?.neighborhood || '');
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [toast, setToast] = useState<{ message: string; tone: 'success' | 'error' } | null>(null);

  if (!profile) return null;

  const handleSave = async () => {
    setSaving(true);
    try {
      await updateDoc(doc(db, COLLECTIONS.USERS, profile.id), { fullName, city, neighborhood });
      setSaved(true);
      setTimeout(() => setSaved(false), 2000);
    } catch {
      setToast({ message: 'Could not save your changes. Please try again.', tone: 'error' });
    } finally {
      setSaving(false);
    }
  };

  const handlePhotoUploaded = async (url: string) => {
    try {
      await updateDoc(doc(db, COLLECTIONS.USERS, profile.id), { profilePhoto: url });
      setToast({ message: 'Profile photo updated.', tone: 'success' });
    } catch {
      setToast({ message: 'Photo uploaded but could not be saved to your profile. Try again.', tone: 'error' });
    }
  };

  return (
    <div className="max-w-xl">
      <h1 className="text-2xl font-bold text-ink-900 mb-6">Profile</h1>
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
        <Input label="Full name" value={fullName} onChange={(e) => setFullName(e.target.value)} />
        <Input label="Email" value={profile.email || ''} disabled hint="Contact support to change your email" />
        <Select label="City" value={city} onChange={(e) => setCity(e.target.value)}>
          <option value="">Select city</option>
          {CAMEROON_CITIES.map((c) => <option key={c} value={c}>{c}</option>)}
        </Select>
        <Input label="Neighborhood" value={neighborhood} onChange={(e) => setNeighborhood(e.target.value)} />
        <div className="flex items-center gap-3">
          <Button onClick={handleSave} loading={saving}>Save changes</Button>
          {saved && <span className="text-sm text-brand-600">Saved ✓</span>}
        </div>
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
