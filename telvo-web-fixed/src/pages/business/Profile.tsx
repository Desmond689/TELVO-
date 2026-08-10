import { useState } from 'react';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Textarea } from '@/components/ui/Textarea';
import { Select } from '@/components/ui/Select';
import { Toast } from '@/components/ui/Toast';
import { ImageUploader } from '@/components/ui/ImageUploader';
import { useAuth } from '@/contexts/AuthContext';
import { db, COLLECTIONS } from '@/lib/firebase';
import { doc, updateDoc } from 'firebase/firestore';
import { CAMEROON_CITIES } from '@/types';

export function BusinessProfileEdit() {
  const { profile } = useAuth();
  const [businessName, setBusinessName] = useState(profile?.businessName || '');
  const [businessDescription, setBusinessDescription] = useState(profile?.businessDescription || '');
  const [city, setCity] = useState(profile?.city || '');
  const [website, setWebsite] = useState(profile?.website || '');
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [toast, setToast] = useState<{ message: string; tone: 'success' | 'error' } | null>(null);

  if (!profile) return null;

  const handleLogoUploaded = async (url: string) => {
    try {
      await updateDoc(doc(db, COLLECTIONS.USERS, profile.id), { businessLogo: url });
      setToast({ message: 'Logo updated.', tone: 'success' });
    } catch {
      setToast({ message: 'Logo uploaded but could not be saved to your profile. Try again.', tone: 'error' });
    }
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      await updateDoc(doc(db, COLLECTIONS.USERS, profile.id), { businessName, businessDescription, city, website });
      setSaved(true);
      setTimeout(() => setSaved(false), 2000);
    } catch {
      setToast({ message: 'Could not save your changes. Please try again.', tone: 'error' });
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="max-w-xl">
      <h1 className="text-2xl font-bold text-ink-900 mb-6">Business Profile</h1>
      <Card className="p-6 space-y-5">
        <div className="flex items-center gap-4">
          <ImageUploader
            variant="avatar"
            size={80}
            path={`business-logos/${profile.id}`}
            value={profile.businessLogo}
            onUploaded={handleLogoUploaded}
            onError={(message) => setToast({ message, tone: 'error' })}
          />
          <div className="text-sm text-ink-500">
            <p className="font-medium text-ink-800">{businessName || 'Your business'}</p>
            <p>Click your logo to change it</p>
          </div>
        </div>
        <Input label="Business name" value={businessName} onChange={(e) => setBusinessName(e.target.value)} />
        <Textarea label="Description" value={businessDescription} onChange={(e) => setBusinessDescription(e.target.value)} />
        <Select label="City" value={city} onChange={(e) => setCity(e.target.value)}>
          <option value="">Select city</option>
          {CAMEROON_CITIES.map((c) => <option key={c} value={c}>{c}</option>)}
        </Select>
        <Input label="Website" value={website} onChange={(e) => setWebsite(e.target.value)} placeholder="https://" />
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
