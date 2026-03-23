# Blossom Dashboard

A Next.js admin dashboard for Blossom2 backed by Supabase Auth and the FastAPI admin API.

## Environment

Create `blossom_dashboard/.env.local` with:

```bash
NEXT_PUBLIC_API_BASE_URL=http://127.0.0.1:8000/api/v1
NEXT_PUBLIC_SUPABASE_URL=https://aophohpfxjnqcxxsqbck.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
```

## Run

```bash
npm install
npm run dev
```

The dashboard signs in with Supabase on the web, reads the user profile via `/profiles/me`, and unlocks admin pages only when the profile role is `admin`.

## Current pages

- `/login`
- `/dashboard`
- `/ai-settings`

## Notes

- The FastAPI backend must allow the dashboard origin through CORS outside local development.
- The signed-in account must resolve to a profile with role `admin`.
