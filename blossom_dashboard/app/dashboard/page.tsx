'use client';

import { Bot, Lock, MessageSquareWarning, Sparkles } from 'lucide-react';

import { MetricCard } from '@/components/dashboard/metric-card';
import { ProtectedShell } from '@/components/dashboard/protected-shell';
import { Topbar } from '@/components/dashboard/topbar';
import { Panel } from '@/components/ui/panel';
import { useAuth } from '@/components/providers/auth-provider';

export default function DashboardPage() {
  const { profile } = useAuth();

  return (
    <ProtectedShell>
      <div className="space-y-4">
        <Panel className="p-6 sm:p-8">
          <Topbar
            title="Operations overview"
            subtitle="A clean starting point for the Blossom admin dashboard. AI controls are live first, with moderation and catalog management ready to land next."
          />
        </Panel>

        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
          <MetricCard
            label="Admin role"
            value={profile?.role === 'admin' ? 'Verified' : 'Pending'}
            description="Role is resolved from /profiles/me using your Supabase access token."
            icon={Lock}
          />
          <MetricCard
            label="AI controls"
            value="Live"
            description="Settings are wired to the FastAPI admin API and ready for real edits."
            icon={Bot}
          />
          <MetricCard
            label="Plant catalog"
            value="Live"
            description="Admin plant CRUD is now wired to /admin/plants from the dashboard."
            icon={Sparkles}
          />
          <MetricCard
            label="Moderation"
            value="Live"
            description="Posts and comments can now be hidden or restored from the dashboard."
            icon={MessageSquareWarning}
          />
        </div>

        <div className="grid gap-4 xl:grid-cols-[1.4fr_1fr]">
          <Panel className="p-6 sm:p-8">
            <p className="text-xs uppercase tracking-[0.28em] text-emerald-300">Current scope</p>
            <h3 className="mt-4 text-2xl font-semibold text-white">Dashboard foundation is ready</h3>
            <div className="mt-5 space-y-4 text-sm leading-7 text-slate-400">
              <p>
                The admin dashboard now has three live operational surfaces: AI configuration, plant catalog management, and community moderation. Each one is backed by real FastAPI admin endpoints and uses Supabase-authenticated bearer tokens from the web client.
              </p>
              <p>
                The next dashboard milestones should focus on deeper moderation tooling, richer plant review workflows for AI-created records, or additional operational views like notification health and activity auditing.
              </p>
            </div>
          </Panel>

          <Panel className="p-6 sm:p-8">
            <p className="text-xs uppercase tracking-[0.28em] text-sky-300">Session details</p>
            <dl className="mt-5 space-y-4 text-sm text-slate-300">
              <div>
                <dt className="text-slate-500">Signed in as</dt>
                <dd className="mt-1 font-medium text-white">{profile?.display_name || 'Admin user'}</dd>
              </div>
              <div>
                <dt className="text-slate-500">Email</dt>
                <dd className="mt-1">{profile?.email || 'Unavailable'}</dd>
              </div>
              <div>
                <dt className="text-slate-500">Role</dt>
                <dd className="mt-1 capitalize">{profile?.role || 'Unknown'}</dd>
              </div>
              <div>
                <dt className="text-slate-500">Recommended next page</dt>
                <dd className="mt-1 text-white">Community Moderation</dd>
              </div>
            </dl>
          </Panel>
        </div>
      </div>
    </ProtectedShell>
  );
}
