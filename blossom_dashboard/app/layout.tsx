import type { Metadata } from 'next';
import type { ReactNode } from 'react';

import '@/app/globals.css';
import { AuthProvider } from '@/components/providers/auth-provider';

export const metadata: Metadata = {
  title: 'Blossom Admin Dashboard',
  description: 'Admin dashboard for managing Blossom AI settings and moderation tools.',
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body>
        <AuthProvider>{children}</AuthProvider>
      </body>
    </html>
  );
}
