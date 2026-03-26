'use client';

import Link from 'next/link';
import { Bot, Leaf, MessageSquareWarning } from 'lucide-react';

import { ProtectedShell } from '@/components/dashboard/protected-shell';
import { Panel } from '@/components/ui/panel';
import { useAuth } from '@/components/providers/auth-provider';

const sections = [
  {
    href: '/plants',
    label: 'Plants',
    description: 'Add, edit, or remove plants in the catalog.',
    icon: Leaf,
    accent: 'text-emerald-300',
    bg: 'bg-emerald-500/10',
  },
  {
    href: '/community',
    label: 'Moderation',
    description: 'Review and manage community posts.',
    icon: MessageSquareWarning,
    accent: 'text-amber-300',
    bg: 'bg-amber-500/10',
  },
  {
    href: '/ai-settings',
    label: 'AI Settings',
    description: 'Configure the Gemini model and API key.',
    icon: Bot,
    accent: 'text-sky-300',
    bg: 'bg-sky-500/10',
  },
];

export default function DashboardPage() {
  const { profile } = useAuth();

  return (
    <ProtectedShell>
      <div className="space-y-6">
        {/* Header */}
        <Panel className="p-6 sm:p-8">
          <p className="text-sm text-slate-400">Welcome back</p>
          <h2 className="mt-1 text-2xl font-semibold text-white">
            {profile?.display_name || 'Admin'}
          </h2>
          <p className="mt-1 text-sm text-slate-500">{profile?.email}</p>
        </Panel>

        {/* Quick navigation */}
        <div className="grid gap-4 sm:grid-cols-3">
          {sections.map(({ href, label, description, icon: Icon, accent, bg }) => (
            <Link key={href} href={href} className="group">
              <Panel className="flex h-full flex-col gap-4 p-6 transition hover:border-slate-600">
                <div className={`inline-flex h-11 w-11 items-center justify-center rounded-2xl ${bg} ${accent}`}>
                  <Icon className="h-5 w-5" />
                </div>
                <div>
                  <p className="font-semibold text-white">{label}</p>
                  <p className="mt-1 text-sm text-slate-400">{description}</p>
                </div>
              </Panel>
            </Link>
          ))}
        </div>
      </div>
    </ProtectedShell>
  );
}
