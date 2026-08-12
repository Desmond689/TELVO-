import { useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/Button';
import { useAuth } from '@/contexts/AuthContext';

export function Suspended() {
  const { profile, loading } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    if (!loading && profile?.isSuspended !== true) {
      navigate('/', { replace: true });
    }
  }, [loading, profile, navigate]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-ink-50 px-4 py-12">
      <div className="max-w-xl w-full text-center px-6 py-12 bg-white border border-ink-100 rounded-3xl shadow-card">
        <p className="text-brand-500 font-extrabold text-6xl">🚫</p>
        <h1 className="text-3xl font-bold text-ink-900 mt-6">Account suspended</h1>
        <p className="text-sm text-ink-500 mt-4 leading-relaxed">
          Your TELVO account has been suspended and you can no longer access the dashboard.
          If you believe this is a mistake, please contact support for assistance.
        </p>
        <div className="mt-8 flex flex-col sm:flex-row justify-center gap-3">
          <Link to="/">
            <Button variant="outline">Back to home</Button>
          </Link>
          <a href="mailto:support@telvo.com">
            <Button>Contact support</Button>
          </a>
        </div>
      </div>
    </div>
  );
}
