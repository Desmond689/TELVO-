import { useEffect, useState } from 'react';
import { collection, getDocs, query, where, doc, updateDoc } from 'firebase/firestore';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { EmptyState } from '@/components/ui/EmptyState';
import { db, COLLECTIONS } from '@/lib/firebase';
import type { TelvoUser } from '@/types';
import { ShieldCheck, IdCard } from 'lucide-react';

export function AdminVerifications() {
  const [pending, setPending] = useState<TelvoUser[] | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [preview, setPreview] = useState<string | null>(null);

  const load = () => {
    getDocs(query(collection(db, COLLECTIONS.USERS), where('verificationStatus', '==', 'pending'))).then((snap) =>
      setPending(snap.docs.map((d) => ({ id: d.id, ...d.data() } as TelvoUser)))
    );
  };
  useEffect(load, []);

  const decide = async (u: TelvoUser, approve: boolean) => {
    setBusyId(u.id);
    try {
      await updateDoc(doc(db, COLLECTIONS.USERS, u.id), {
        isVerified: approve,
        verificationStatus: approve ? 'verified' : 'rejected',
      });
      load();
    } finally {
      setBusyId(null);
    }
  };

  return (
    <div>
      <h1 className="text-2xl font-bold text-ink-900 mb-6">Verification Requests</h1>
      {pending === null && <p className="text-sm text-ink-400">Loading...</p>}
      {pending?.length === 0 && <EmptyState icon={<ShieldCheck size={36} />} title="No pending verifications" description="New verification submissions will appear here for review." />}
      <div className="space-y-3">
        {pending?.map((u) => {
          const idUrl = (u as any).verificationIdUrl as string | undefined;
          const selfieUrl = (u as any).verificationSelfieUrl as string | undefined;
          return (
            <Card key={u.id} className="p-5 flex flex-col gap-4">
              <div className="flex items-center justify-between gap-4 flex-wrap">
                <div className="flex items-center gap-3">
                  <span className="w-11 h-11 rounded-full bg-brand-100 text-brand-700 flex items-center justify-center font-bold overflow-hidden">
                    {u.profilePhoto ? <img src={u.profilePhoto} className="w-full h-full object-cover" alt="" /> : u.fullName?.[0]}
                  </span>
                  <div>
                    <p className="font-medium text-ink-900">{u.fullName}</p>
                    <p className="text-sm text-ink-500">{u.category || u.userType} · {u.city}</p>
                  </div>
                </div>
                <div className="flex gap-2">
                  <Button size="sm" variant="outline" loading={busyId === u.id} onClick={() => decide(u, false)}>Reject</Button>
                  <Button size="sm" loading={busyId === u.id} onClick={() => decide(u, true)}>Approve</Button>
                </div>
              </div>

              {idUrl || selfieUrl ? (
                <div className="flex gap-3 flex-wrap">
                  {idUrl && (
                    <button type="button" onClick={() => setPreview(idUrl)} className="group">
                      <div className="w-28 h-20 rounded-lg overflow-hidden border border-ink-200">
                        <img src={idUrl} alt="Government ID" className="w-full h-full object-cover group-hover:opacity-80" />
                      </div>
                      <p className="text-xs text-ink-500 mt-1">Government ID</p>
                    </button>
                  )}
                  {selfieUrl && (
                    <button type="button" onClick={() => setPreview(selfieUrl)} className="group">
                      <div className="w-28 h-20 rounded-lg overflow-hidden border border-ink-200">
                        <img src={selfieUrl} alt="Selfie" className="w-full h-full object-cover group-hover:opacity-80" />
                      </div>
                      <p className="text-xs text-ink-500 mt-1">Selfie</p>
                    </button>
                  )}
                </div>
              ) : (
                <div className="flex items-center gap-2 text-xs text-amber-700 bg-amber-50 border border-amber-200 rounded-lg px-3 py-2">
                  <IdCard size={14} /> No documents attached to this request yet.
                </div>
              )}
            </Card>
          );
        })}
      </div>

      {preview && (
        <div
          className="fixed inset-0 z-50 bg-black/80 flex items-center justify-center p-6"
          onClick={() => setPreview(null)}
        >
          <img src={preview} alt="" className="max-w-full max-h-full rounded-lg" />
        </div>
      )}
    </div>
  );
}
