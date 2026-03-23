import { clsx } from 'clsx';

export function StatusBadge({
  label,
  tone = 'neutral',
}: {
  label: string;
  tone?: 'success' | 'warning' | 'danger' | 'neutral';
}) {
  return (
    <span
      className={clsx(
        'inline-flex items-center rounded-full border px-3 py-1 text-xs font-semibold uppercase tracking-[0.24em]',
        tone === 'success' && 'border-emerald-400/30 bg-emerald-500/10 text-emerald-300',
        tone === 'warning' && 'border-amber-400/30 bg-amber-500/10 text-amber-300',
        tone === 'danger' && 'border-rose-400/30 bg-rose-500/10 text-rose-300',
        tone === 'neutral' && 'border-slate-400/20 bg-slate-500/10 text-slate-300',
      )}
    >
      {label}
    </span>
  );
}
