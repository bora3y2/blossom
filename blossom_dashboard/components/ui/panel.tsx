import type { ReactNode } from 'react';

import { clsx } from 'clsx';

export function Panel({
  children,
  className,
}: {
  children: ReactNode;
  className?: string;
}) {
  return (
    <div
      className={clsx(
        'rounded-3xl border border-border bg-slate-950/70 shadow-panel backdrop-blur',
        className,
      )}
    >
      {children}
    </div>
  );
}
