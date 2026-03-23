'use client';

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import type { Session } from '@supabase/supabase-js';

import { getMyProfile } from '@/lib/api';
import { hasSupabaseConfig } from '@/lib/config';
import { getSupabaseBrowserClient } from '@/lib/supabase';
import type { Profile } from '@/lib/types';

type AuthContextValue = {
  initialized: boolean;
  session: Session | null;
  profile: Profile | null;
  loading: boolean;
  error: string | null;
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
  refreshProfile: () => Promise<void>;
};

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

async function fetchProfile(session: Session | null): Promise<Profile | null> {
  if (!session?.access_token) {
    return null;
  }
  return getMyProfile(session.access_token);
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [initialized, setInitialized] = useState(false);
  const [session, setSession] = useState<Session | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const refreshProfile = useCallback(async () => {
    if (!session) {
      setProfile(null);
      return;
    }

    setLoading(true);
    setError(null);
    try {
      const nextProfile = await fetchProfile(session);
      setProfile(nextProfile);
    } catch (nextError) {
      setProfile(null);
      setError(nextError instanceof Error ? nextError.message : 'Unable to load your profile.');
    } finally {
      setLoading(false);
    }
  }, [session]);

  useEffect(() => {
    const client = getSupabaseBrowserClient();

    if (!hasSupabaseConfig || !client) {
      setInitialized(true);
      setError('Supabase dashboard environment variables are missing.');
      return;
    }

    let active = true;

    client.auth.getSession().then(async ({ data, error: sessionError }) => {
      if (!active) {
        return;
      }

      if (sessionError) {
        setError(sessionError.message);
      }

      const nextSession = data.session;
      setSession(nextSession);
      try {
        const nextProfile = await fetchProfile(nextSession);
        if (active) {
          setProfile(nextProfile);
        }
      } catch (profileError) {
        if (active) {
          setError(profileError instanceof Error ? profileError.message : 'Unable to load your profile.');
        }
      } finally {
        if (active) {
          setInitialized(true);
        }
      }
    });

    const { data: listener } = client.auth.onAuthStateChange(async (_event, nextSession) => {
      if (!active) {
        return;
      }
      setSession(nextSession);
      setError(null);
      if (!nextSession) {
        setProfile(null);
        setInitialized(true);
        return;
      }
      try {
        const nextProfile = await fetchProfile(nextSession);
        if (active) {
          setProfile(nextProfile);
        }
      } catch (profileError) {
        if (active) {
          setProfile(null);
          setError(profileError instanceof Error ? profileError.message : 'Unable to load your profile.');
        }
      } finally {
        if (active) {
          setInitialized(true);
        }
      }
    });

    return () => {
      active = false;
      listener.subscription.unsubscribe();
    };
  }, []);

  const signIn = useCallback(async (email: string, password: string) => {
    const client = getSupabaseBrowserClient();
    if (!client) {
      throw new Error('Supabase dashboard environment variables are missing.');
    }
    setLoading(true);
    setError(null);
    try {
      const { error: signInError } = await client.auth.signInWithPassword({ email, password });
      if (signInError) {
        throw signInError;
      }
    } catch (signInError) {
      const message = signInError instanceof Error ? signInError.message : 'Unable to sign in.';
      setError(message);
      throw signInError;
    } finally {
      setLoading(false);
    }
  }, []);

  const signOut = useCallback(async () => {
    const client = getSupabaseBrowserClient();
    if (!client) {
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const { error: signOutError } = await client.auth.signOut();
      if (signOutError) {
        throw signOutError;
      }
      setProfile(null);
      setSession(null);
    } catch (signOutError) {
      const message = signOutError instanceof Error ? signOutError.message : 'Unable to sign out.';
      setError(message);
      throw signOutError;
    } finally {
      setLoading(false);
    }
  }, []);

  const value = useMemo<AuthContextValue>(
    () => ({
      initialized,
      session,
      profile,
      loading,
      error,
      signIn,
      signOut,
      refreshProfile,
    }),
    [error, initialized, loading, profile, refreshProfile, session, signIn, signOut],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider.');
  }
  return context;
}
