'use client';

import { Bell, Sparkles } from 'lucide-react';

import { StatusBadge } from '@/components/ui/status-badge';
import { useAuth } from '@/components/providers/auth-provider';

export function Topbar({ title, subtitle }: { title: string; subtitle: string }) {
  const { profile } = useAuth();

  return (
    <div className="flex flex-col gap-5 lg:flex-row lg:items-center lg:justify-between">
      <div>
        <div className="inline-flex items-center gap-2 rounded-full border border-emerald-400/20 bg-emerald-500/10 px-3 py-1 text-xs font-semibold uppercase tracking-[0.24em] text-emerald-300">
          <Sparkles className="h-3.5 w-3.5" />
          Blossom Admin Dashboard
        </div>
        <h2 className="mt-4 text-3xl font-semibold text-white">{title}</h2>
        <p className="mt-2 max-w-2xl text-sm text-slate-400">{subtitle}</p>
      </div>

      <div className="flex items-center gap-4 self-start rounded-2xl border border-border bg-slate-950/70 px-4 py-3">
        <div className="hidden text-right sm:block">
          <p className="text-sm font-medium text-white">{profile?.display_name || 'Blossom Admin'}</p>
          <p className="mt-1 text-xs text-slate-400">{profile?.role === 'admin' ? 'Admin access verified' : 'Session active'}</p>
        </div>
        <StatusBadge label={profile?.role === 'admin' ? 'Admin' : 'Signed in'} tone="success" />
        <div className="inline-flex h-10 w-10 items-center justify-center rounded-2xl border border-white/10 bg-slate-900 text-slate-300">
          <Bell className="h-4 w-4" />
        </div>
      </div>
    </div>
  );
}
