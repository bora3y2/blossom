export const apiBaseUrl =
  process.env.NEXT_PUBLIC_API_BASE_URL?.trim() || 'http://127.0.0.1:8000/api/v1';

export const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL?.trim() || '';
export const supabaseAnonKey =
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY?.trim() || '';

export const hasSupabaseConfig =
  supabaseUrl.length > 0 && supabaseAnonKey.length > 0;
