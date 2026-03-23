import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './app/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './lib/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        surface: '#08111f',
        surfaceAlt: '#101b2d',
        border: 'rgba(148, 163, 184, 0.14)',
        accent: '#7dd3fc',
        accentStrong: '#22c55e',
      },
      boxShadow: {
        panel: '0 24px 80px rgba(8, 17, 31, 0.36)',
      },
      backgroundImage: {
        spotlight:
          'radial-gradient(circle at top, rgba(34, 197, 94, 0.16), transparent 28%), radial-gradient(circle at 20% 20%, rgba(125, 211, 252, 0.14), transparent 30%)',
      },
    },
  },
  plugins: [],
};

export default config;
