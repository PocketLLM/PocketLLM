import '../styles/globals.css';
import type { Metadata } from 'next';
import { ReactNode } from 'react';

export const metadata: Metadata = {
  title: 'Language Test App',
  description: 'Configure and deliver adaptive language proficiency assessments.',
  icons: {
    icon: '/favicon.svg'
  }
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body>
        {children}
      </body>
    </html>
  );
}
