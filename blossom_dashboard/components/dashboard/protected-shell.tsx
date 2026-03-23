'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import type { ReactNode } from 'react';

import { Sidebar } from '@/components/dashboard/sidebar';
import { useAuth } from '@/components/providers/auth-provider';
import { Panel } from '@/components/ui/panel';
import { hasSupabaseConfig } from '@/lib/config';

export function ProtectedShell({ children }: { children: ReactNode }) {
  const router = useRouter();
  const { initialized, session, profile, error } = useAuth();

  useEffect(() => {
    if (!initialized) {
      return;
    }
    if (!session) {
      router.replace('/login');
      return;
    }
    if (profile && profile.role !== 'admin') {
      router.replace('/login?reason=admin');
    }
  }, [initialized, profile, router, session]);

  if (!hasSupabaseConfig) {
    return (
      <div className="flex min-h-screen items-center justify-center p-6">
        <Panel className="max-w-xl p-8">
          <h1 className="text-2xl font-semibold text-white">Missing dashboard environment</h1>
          <p className="mt-3 text-sm text-slate-400">
            Add the Supabase and API values to <code>.env.local</code> before starting the admin dashboard.
          </p>
        </Panel>
      </div>
    );
  }

  if (!initialized || (session && !profile && !error)) {
    return (
      <div className="flex min-h-screen items-center justify-center p-6">
        <Panel className="max-w-md p-8 text-center">
          <p className="text-sm uppercase tracking-[0.28em] text-emerald-300">Loading</p>
          <h1 className="mt-4 text-2xl font-semibold text-white">Preparing your admin workspace</h1>
          <p className="mt-3 text-sm text-slate-400">Validating session, loading role permissions, and connecting to the Blossom API.</p>
        </Panel>
      </div>
    );
  }

  if (!session) {
    return null;
  }

  if (error && !profile) {
    return (
      <div className="flex min-h-screen items-center justify-center p-6">
        <Panel className="max-w-lg p-8">
          <h1 className="text-2xl font-semibold text-white">Unable to open the dashboard</h1>
          <p className="mt-3 text-sm text-slate-400">
            The dashboard could not load your admin profile from the Blossom API.
          </p>
          <p className="mt-4 rounded-2xl border border-rose-400/20 bg-rose-500/10 p-4 text-sm text-rose-100">
            {error}
          </p>
        </Panel>
      </div>
    );
  }

  if (profile?.role !== 'admin') {
    return (
      <div className="flex min-h-screen items-center justify-center p-6">
        <Panel className="max-w-lg p-8">
          <h1 className="text-2xl font-semibold text-white">Admin access required</h1>
          <p className="mt-3 text-sm text-slate-400">
            This dashboard only opens for profiles with the <code>admin</code> role. Sign in with your bootstrap admin account or update the role in the backend first.
          </p>
        </Panel>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-spotlight px-4 py-4 sm:px-6 lg:px-8">
      <div className="mx-auto grid min-h-[calc(100vh-2rem)] max-w-7xl gap-4 lg:grid-cols-[280px_minmax(0,1fr)]">
        <aside className="min-h-full">
          <Sidebar />
        </aside>
        <main className="min-w-0">{children}</main>
      </div>
    </div>
  );
}
