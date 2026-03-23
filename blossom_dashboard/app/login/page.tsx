'use client';

import { Suspense, useEffect, useMemo, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { ShieldCheck } from 'lucide-react';

import { useAuth } from '@/components/providers/auth-provider';
import { Panel } from '@/components/ui/panel';
import { hasSupabaseConfig } from '@/lib/config';

function LoginContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { initialized, session, profile, signIn, loading, error } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [localError, setLocalError] = useState<string | null>(null);

  useEffect(() => {
    if (!initialized) {
      return;
    }
    if (session && profile?.role === 'admin') {
      router.replace('/dashboard');
    }
  }, [initialized, profile, router, session]);

  const reasonMessage = useMemo(() => {
    const reason = searchParams.get('reason');
    if (reason === 'admin') {
      return 'Your account is signed in, but it does not currently have admin access.';
    }
    return null;
  }, [searchParams]);

  const handleSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setLocalError(null);

    try {
      await signIn(email.trim(), password);
      router.replace('/dashboard');
    } catch (submitError) {
      setLocalError(submitError instanceof Error ? submitError.message : 'Unable to sign in.');
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center px-4 py-10 sm:px-6 lg:px-8">
      <Panel className="w-full max-w-md p-8 sm:p-10">
        <div className="inline-flex h-14 w-14 items-center justify-center rounded-2xl bg-emerald-500/15 text-emerald-300">
          <ShieldCheck className="h-7 w-7" />
        </div>
        <p className="mt-6 text-xs uppercase tracking-[0.34em] text-emerald-300">Blossom Admin</p>
        <h1 className="mt-3 text-3xl font-semibold text-white">Sign in to the dashboard</h1>
        <p className="mt-3 text-sm text-slate-400">
          Use your Supabase account. The dashboard unlocks automatically when your profile role is <code>admin</code>.
        </p>

        {!hasSupabaseConfig ? (
          <div className="mt-6 rounded-2xl border border-rose-400/20 bg-rose-500/10 p-4 text-sm text-rose-200">
            Missing Supabase dashboard environment variables. Add them to <code>.env.local</code> first.
          </div>
        ) : null}
        {reasonMessage ? (
          <div className="mt-6 rounded-2xl border border-amber-400/20 bg-amber-500/10 p-4 text-sm text-amber-100">
            {reasonMessage}
          </div>
        ) : null}
        {error ? (
          <div className="mt-6 rounded-2xl border border-rose-400/20 bg-rose-500/10 p-4 text-sm text-rose-200">
            {error}
          </div>
        ) : null}
        {localError ? (
          <div className="mt-6 rounded-2xl border border-rose-400/20 bg-rose-500/10 p-4 text-sm text-rose-200">
            {localError}
          </div>
        ) : null}

        <form className="mt-8 space-y-5" onSubmit={handleSubmit}>
          <label className="block">
            <span className="mb-2 block text-sm font-medium text-slate-200">Email</span>
            <input
              type="email"
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              placeholder="admin@blossom.app"
              className="w-full rounded-2xl border border-slate-700 bg-slate-950 px-4 py-3 outline-none transition focus:border-emerald-400"
              required
            />
          </label>

          <label className="block">
            <span className="mb-2 block text-sm font-medium text-slate-200">Password</span>
            <input
              type="password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              placeholder="••••••••"
              className="w-full rounded-2xl border border-slate-700 bg-slate-950 px-4 py-3 outline-none transition focus:border-emerald-400"
              required
            />
          </label>

          <button
            type="submit"
            disabled={loading || !hasSupabaseConfig}
            className="inline-flex w-full items-center justify-center rounded-2xl bg-emerald-500 px-4 py-3 font-semibold text-slate-950 transition hover:bg-emerald-400 disabled:cursor-not-allowed disabled:opacity-60"
          >
            {loading ? 'Signing in...' : 'Sign in'}
          </button>
        </form>
      </Panel>
    </div>
  );
}

export default function LoginPage() {
  return (
    <Suspense
      fallback={
        <div className="flex min-h-screen items-center justify-center px-4 py-10 sm:px-6 lg:px-8">
          <Panel className="w-full max-w-md p-8 sm:p-10">
            <p className="text-sm uppercase tracking-[0.34em] text-emerald-300">Loading</p>
            <h1 className="mt-4 text-2xl font-semibold text-white">Preparing sign-in</h1>
            <p className="mt-3 text-sm text-slate-400">
              Loading the admin dashboard session state.
            </p>
          </Panel>
        </div>
      }
    >
      <LoginContent />
    </Suspense>
  );
}
