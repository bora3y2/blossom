'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { Bot, Leaf, LayoutDashboard, LogOut, MapPin, MessageSquareWarning, ShieldCheck, ClipboardList } from 'lucide-react';

import { useAuth } from '@/components/providers/auth-provider';
import { Panel } from '@/components/ui/panel';
import { clsx } from 'clsx';

const items = [
  {
    href: '/dashboard',
    label: 'Overview',
    icon: LayoutDashboard,
  },
  {
    href: '/plants',
    label: 'Plants',
    icon: Leaf,
  },
  {
    href: '/community',
    label: 'Moderation',
    icon: MessageSquareWarning,
  },
  {
    href: '/audit-log',
    label: 'Audit Log',
    icon: ClipboardList,
  },
  {
    href: '/ai-settings',
    label: 'AI Settings',
    icon: Bot,
  },
  {
    href: '/locations',
    label: 'Locations',
    icon: MapPin,
  },
];

export function Sidebar() {
  const pathname = usePathname();
  const { profile, signOut, loading } = useAuth();

  return (
    <Panel className="flex h-full flex-col justify-between p-5">
      <div className="space-y-8">
        <div className="space-y-3">
          <div className="inline-flex h-12 w-12 items-center justify-center rounded-2xl bg-emerald-500/15 text-emerald-300">
            <ShieldCheck className="h-6 w-6" />
          </div>
          <div>
            <p className="text-xs uppercase tracking-[0.34em] text-slate-400">Blossom Admin</p>
            <h1 className="mt-2 text-xl font-semibold text-white">Control Center</h1>
          </div>
        </div>

        <nav className="space-y-2">
          {items.map((item) => {
            const Icon = item.icon;
            const active = pathname === item.href;
            return (
              <Link
                key={item.href}
                href={item.href}
                className={clsx(
                  'flex items-center gap-3 rounded-2xl border px-4 py-3 text-sm transition',
                  active
                    ? 'border-emerald-400/30 bg-emerald-500/10 text-white'
                    : 'border-transparent bg-slate-900/40 text-slate-300 hover:border-slate-700 hover:bg-slate-900/80 hover:text-white',
                )}
              >
                <Icon className="h-4 w-4" />
                <span>{item.label}</span>
              </Link>
            );
          })}
        </nav>
      </div>

      <div className="space-y-4 rounded-2xl border border-white/5 bg-slate-900/60 p-4">
        <div>
          <p className="text-sm font-semibold text-white">{profile?.display_name || 'Admin user'}</p>
          <p className="mt-1 text-sm text-slate-400">{profile?.email || 'No active session'}</p>
        </div>
        <button
          type="button"
          onClick={() => void signOut()}
          disabled={loading}
          className="inline-flex w-full items-center justify-center gap-2 rounded-2xl border border-slate-700 bg-slate-950 px-4 py-3 text-sm font-medium text-slate-200 transition hover:border-slate-600 hover:bg-slate-900 disabled:cursor-not-allowed disabled:opacity-60"
        >
          <LogOut className="h-4 w-4" />
          Sign out
        </button>
      </div>
    </Panel>
  );
}
