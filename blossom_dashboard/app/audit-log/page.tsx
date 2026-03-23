'use client';

import { useEffect, useState } from 'react';
import { LoaderCircle, ClipboardList } from 'lucide-react';

import { ProtectedShell } from '@/components/dashboard/protected-shell';
import { Topbar } from '@/components/dashboard/topbar';
import { Panel } from '@/components/ui/panel';
import { useAuth } from '@/components/providers/auth-provider';
import { getAdminAuditLog } from '@/lib/api';
import type { AuditLogEntry } from '@/lib/types';

function formatRelativeDate(dateString: string) {
  const date = new Date(dateString);
  const now = new Date();
  const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000);
  
  if (diffInSeconds < 60) return `${diffInSeconds}s ago`;
  const diffInMinutes = Math.floor(diffInSeconds / 60);
  if (diffInMinutes < 60) return `${diffInMinutes}m ago`;
  const diffInHours = Math.floor(diffInMinutes / 60);
  if (diffInHours < 24) return `${diffInHours}h ago`;
  const diffInDays = Math.floor(diffInHours / 24);
  if (diffInDays < 7) return `${diffInDays}d ago`;
  
  return date.toLocaleDateString();
}

function formatAction(action: string) {
  return action
    .split('_')
    .map(word => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
}

export default function AuditLogPage() {
  const { session } = useAuth();
  const accessToken = session?.access_token ?? null;
  const [logs, setLogs] = useState<AuditLogEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!accessToken) return;
    
    let active = true;
    setLoading(true);
    setError(null);

    getAdminAuditLog(accessToken)
      .then((payload) => {
        if (active) setLogs(payload.items);
      })
      .catch((err) => {
        if (active) setError(err instanceof Error ? err.message : 'Unable to load audit log.');
      })
      .finally(() => {
        if (active) setLoading(false);
      });

    return () => {
      active = false;
    };
  }, [accessToken]);

  return (
    <ProtectedShell>
      <div className="space-y-4">
        <Panel className="p-6 sm:p-8">
          <Topbar
            title="Audit Log"
            subtitle="An immutable timeline of all administrative moderation actions across the platform."
          />
        </Panel>

        {error ? (
          <Panel className="border-rose-400/20 bg-rose-500/10 p-5 text-sm text-rose-100">{error}</Panel>
        ) : null}

        <Panel className="p-6 sm:p-8">
          <div className="flex items-center gap-3 border-b border-white/5 pb-4">
            <ClipboardList className="h-5 w-5 text-emerald-400" />
            <h3 className="text-lg font-semibold text-white">Recent Activity</h3>
          </div>

          <div className="mt-6 space-y-4">
            {loading ? (
              <div className="flex items-center gap-3 rounded-2xl border border-slate-800 bg-slate-950/70 p-4 text-sm text-slate-300">
                <LoaderCircle className="h-4 w-4 animate-spin" />
                Loading audit log...
              </div>
            ) : null}

            {!loading && logs.length === 0 ? (
              <div className="rounded-2xl border border-slate-800 bg-slate-950/70 p-6 text-sm text-slate-400">
                No administrative actions have been recorded yet.
              </div>
            ) : null}

            {!loading && logs.length > 0 && (
              <div className="overflow-x-auto">
                <table className="w-full text-left text-sm text-slate-400">
                  <thead className="border-b border-slate-800 text-xs uppercase text-slate-500">
                    <tr>
                      <th className="px-4 py-3">Timestamp</th>
                      <th className="px-4 py-3">Administrator</th>
                      <th className="px-4 py-3">Action</th>
                      <th className="px-4 py-3">Target Entity</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-800">
                    {logs.map((log) => (
                      <tr key={log.id} className="hover:bg-slate-900/50 transition-colors">
                        <td className="whitespace-nowrap px-4 py-4 text-slate-300">
                          <span title={new Date(log.created_at).toLocaleString()}>
                            {formatRelativeDate(log.created_at)}
                          </span>
                        </td>
                        <td className="px-4 py-4 font-medium text-white">
                          {log.admin_display_name || 'Admin'}
                          <div className="text-[10px] text-slate-500 font-mono mt-0.5">{log.admin_user_id.split('-')[0]}</div>
                        </td>
                        <td className="px-4 py-4">
                          <span className="rounded-md bg-emerald-900/30 px-2.5 py-1 text-xs font-semibold text-emerald-400 border border-emerald-900/50">
                            {formatAction(log.action)}
                          </span>
                        </td>
                        <td className="px-4 py-4">
                          <span className="text-slate-300 capitalize">{log.entity_type.replace('_', ' ')}</span>
                          {log.entity_id && (
                            <div className="text-[10px] text-slate-500 font-mono mt-0.5" title={log.entity_id}>
                              ...{log.entity_id.slice(-8)}
                            </div>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </Panel>
      </div>
    </ProtectedShell>
  );
}
