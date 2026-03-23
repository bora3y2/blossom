'use client';

import { useEffect, useMemo, useState } from 'react';
import { CheckCircle2, LoaderCircle, PlugZap, Save } from 'lucide-react';

import { ProtectedShell } from '@/components/dashboard/protected-shell';
import { Topbar } from '@/components/dashboard/topbar';
import { useAuth } from '@/components/providers/auth-provider';
import { Panel } from '@/components/ui/panel';
import { StatusBadge } from '@/components/ui/status-badge';
import { getAiSettings, testAiConnection, updateAiSettings } from '@/lib/api';
import type { AiConnectionTestResult, AiSettings } from '@/lib/types';

type FormState = {
  model: string;
  systemPrompt: string;
  temperature: string;
  maxTokens: string;
  isEnabled: boolean;
  apiKey: string;
};

function toFormState(settings: AiSettings): FormState {
  return {
    model: settings.model,
    systemPrompt: settings.system_prompt,
    temperature: String(settings.temperature),
    maxTokens: String(settings.max_tokens),
    isEnabled: settings.is_enabled,
    apiKey: '',
  };
}

export default function AiSettingsPage() {
  const { session } = useAuth();
  const accessToken = session?.access_token ?? null;
  const [settings, setSettings] = useState<AiSettings | null>(null);
  const [form, setForm] = useState<FormState | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [testing, setTesting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [testResult, setTestResult] = useState<AiConnectionTestResult | null>(null);

  useEffect(() => {
    if (!accessToken) {
      return;
    }

    let active = true;
    setLoading(true);
    setError(null);

    getAiSettings(accessToken)
      .then((payload) => {
        if (!active) {
          return;
        }
        setSettings(payload);
        setForm(toFormState(payload));
      })
      .catch((nextError) => {
        if (!active) {
          return;
        }
        setError(nextError instanceof Error ? nextError.message : 'Unable to load AI settings.');
      })
      .finally(() => {
        if (active) {
          setLoading(false);
        }
      });

    return () => {
      active = false;
    };
  }, [accessToken]);

  const statusTone = useMemo<'success' | 'warning' | 'danger'>(() => {
    if (settings?.connection_last_status === 'success') {
      return 'success';
    }
    if (settings?.connection_last_status === 'failed') {
      return 'danger';
    }
    return 'warning';
  }, [settings?.connection_last_status]);

  const handleSave = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!accessToken || !form) {
      return;
    }

    setSaving(true);
    setError(null);
    setSuccessMessage(null);

    try {
      const payload = await updateAiSettings(accessToken, {
        model: form.model.trim(),
        system_prompt: form.systemPrompt.trim(),
        temperature: Number(form.temperature),
        max_tokens: Number(form.maxTokens),
        is_enabled: form.isEnabled,
        api_key: form.apiKey.trim() ? form.apiKey.trim() : undefined,
      });
      setSettings(payload);
      setForm(toFormState(payload));
      setSuccessMessage('AI settings saved successfully.');
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : 'Unable to save AI settings.');
    } finally {
      setSaving(false);
    }
  };

  const handleTestConnection = async () => {
    if (!accessToken) {
      return;
    }

    setTesting(true);
    setError(null);
    setSuccessMessage(null);

    try {
      const result = await testAiConnection(accessToken);
      setTestResult(result);
      const refreshed = await getAiSettings(accessToken);
      setSettings(refreshed);
      setForm((current) => current ?? toFormState(refreshed));
      setSuccessMessage(result.message);
    } catch (testError) {
      setError(testError instanceof Error ? testError.message : 'Unable to test AI connection.');
    } finally {
      setTesting(false);
    }
  };

  return (
    <ProtectedShell>
      <div className="space-y-4">
        <Panel className="p-6 sm:p-8">
          <Topbar
            title="AI settings"
            subtitle="Manage the production AI assistant configuration that powers plant identification and future agentic flows."
          />
        </Panel>

        {loading ? (
          <Panel className="p-8">
            <div className="flex items-center gap-3 text-slate-300">
              <LoaderCircle className="h-5 w-5 animate-spin" />
              Loading AI configuration...
            </div>
          </Panel>
        ) : null}

        {error ? (
          <Panel className="border-rose-400/20 bg-rose-500/10 p-5 text-sm text-rose-100">{error}</Panel>
        ) : null}
        {successMessage ? (
          <Panel className="border-emerald-400/20 bg-emerald-500/10 p-5 text-sm text-emerald-100">
            {successMessage}
          </Panel>
        ) : null}

        {settings && form ? (
          <div className="grid gap-4 xl:grid-cols-[1.4fr_0.8fr]">
            <Panel className="p-6 sm:p-8">
              <form className="space-y-6" onSubmit={handleSave}>
                <div className="grid gap-6 md:grid-cols-2">
                  <label className="block">
                    <span className="mb-2 block text-sm font-medium text-slate-200">Provider</span>
                    <input
                      value={settings.provider}
                      disabled
                      className="w-full rounded-2xl border border-slate-700 bg-slate-950 px-4 py-3 text-slate-500 outline-none"
                    />
                  </label>
                  <label className="block">
                    <span className="mb-2 block text-sm font-medium text-slate-200">Model</span>
                    <input
                      value={form.model}
                      onChange={(event) => setForm((current) => current ? { ...current, model: event.target.value } : current)}
                      className="w-full rounded-2xl border border-slate-700 bg-slate-950 px-4 py-3 outline-none transition focus:border-emerald-400"
                      required
                    />
                  </label>
                </div>

                <label className="block">
                  <span className="mb-2 block text-sm font-medium text-slate-200">System prompt</span>
                  <textarea
                    value={form.systemPrompt}
                    onChange={(event) => setForm((current) => current ? { ...current, systemPrompt: event.target.value } : current)}
                    rows={10}
                    className="w-full rounded-3xl border border-slate-700 bg-slate-950 px-4 py-4 outline-none transition focus:border-emerald-400"
                    required
                  />
                </label>

                <div className="grid gap-6 md:grid-cols-2">
                  <label className="block">
                    <span className="mb-2 block text-sm font-medium text-slate-200">Temperature</span>
                    <input
                      type="number"
                      min="0"
                      max="2"
                      step="0.1"
                      value={form.temperature}
                      onChange={(event) => setForm((current) => current ? { ...current, temperature: event.target.value } : current)}
                      className="w-full rounded-2xl border border-slate-700 bg-slate-950 px-4 py-3 outline-none transition focus:border-emerald-400"
                      required
                    />
                  </label>
                  <label className="block">
                    <span className="mb-2 block text-sm font-medium text-slate-200">Max tokens</span>
                    <input
                      type="number"
                      min="1"
                      step="1"
                      value={form.maxTokens}
                      onChange={(event) => setForm((current) => current ? { ...current, maxTokens: event.target.value } : current)}
                      className="w-full rounded-2xl border border-slate-700 bg-slate-950 px-4 py-3 outline-none transition focus:border-emerald-400"
                      required
                    />
                  </label>
                </div>

                <label className="block">
                  <span className="mb-2 block text-sm font-medium text-slate-200">Replace API key</span>
                  <input
                    type="password"
                    value={form.apiKey}
                    onChange={(event) => setForm((current) => current ? { ...current, apiKey: event.target.value } : current)}
                    placeholder={settings.has_api_key ? 'API key already stored. Enter a new one to replace it.' : 'Paste a Gemini API key'}
                    className="w-full rounded-2xl border border-slate-700 bg-slate-950 px-4 py-3 outline-none transition focus:border-emerald-400"
                  />
                  <p className="mt-2 text-xs text-slate-500">
                    Leave this blank to keep the existing encrypted key untouched.
                  </p>
                </label>

                <label className="flex items-center justify-between gap-4 rounded-2xl border border-slate-800 bg-slate-950/80 px-4 py-4">
                  <div>
                    <p className="text-sm font-medium text-white">Enable AI assistant</p>
                    <p className="mt-1 text-sm text-slate-500">Controls whether AI identification can run in production.</p>
                  </div>
                  <input
                    type="checkbox"
                    checked={form.isEnabled}
                    onChange={(event) => setForm((current) => current ? { ...current, isEnabled: event.target.checked } : current)}
                    className="h-5 w-5 rounded border-slate-600 bg-slate-950 text-emerald-500"
                  />
                </label>

                <div className="flex flex-col gap-3 sm:flex-row">
                  <button
                    type="submit"
                    disabled={saving}
                    className="inline-flex items-center justify-center gap-2 rounded-2xl bg-emerald-500 px-5 py-3 font-semibold text-slate-950 transition hover:bg-emerald-400 disabled:cursor-not-allowed disabled:opacity-60"
                  >
                    <Save className="h-4 w-4" />
                    {saving ? 'Saving...' : 'Save settings'}
                  </button>
                  <button
                    type="button"
                    onClick={() => void handleTestConnection()}
                    disabled={testing}
                    className="inline-flex items-center justify-center gap-2 rounded-2xl border border-slate-700 bg-slate-950 px-5 py-3 font-semibold text-slate-200 transition hover:border-slate-600 hover:bg-slate-900 disabled:cursor-not-allowed disabled:opacity-60"
                  >
                    <PlugZap className="h-4 w-4" />
                    {testing ? 'Testing...' : 'Test connection'}
                  </button>
                </div>
              </form>
            </Panel>

            <div className="space-y-4">
              <Panel className="p-6">
                <p className="text-xs uppercase tracking-[0.28em] text-sky-300">Connection health</p>
                <div className="mt-4 flex items-center gap-3">
                  <StatusBadge
                    label={settings.connection_last_status || 'Not tested'}
                    tone={statusTone}
                  />
                  <StatusBadge
                    label={settings.is_enabled ? 'Enabled' : 'Disabled'}
                    tone={settings.is_enabled ? 'success' : 'warning'}
                  />
                </div>
                <dl className="mt-6 space-y-4 text-sm text-slate-300">
                  <div>
                    <dt className="text-slate-500">API key</dt>
                    <dd className="mt-1">{settings.has_api_key ? 'Configured' : 'Missing'}</dd>
                  </div>
                  <div>
                    <dt className="text-slate-500">Last tested</dt>
                    <dd className="mt-1">{settings.connection_last_tested_at || 'Never'}</dd>
                  </div>
                  <div>
                    <dt className="text-slate-500">Last updated</dt>
                    <dd className="mt-1">{settings.updated_at}</dd>
                  </div>
                </dl>
              </Panel>

              <Panel className="p-6">
                <p className="text-xs uppercase tracking-[0.28em] text-emerald-300">Why this page first</p>
                <p className="mt-4 text-sm leading-7 text-slate-400">
                  AI configuration is the highest-value admin slice already supported by the backend. This page gives you a safe operational surface for model changes, prompt tuning, feature enablement, and connection checks before expanding into moderation and catalog tools.
                </p>
              </Panel>

              {testResult ? (
                <Panel className="border-emerald-400/20 bg-emerald-500/10 p-6">
                  <div className="flex items-start gap-3">
                    <CheckCircle2 className="mt-0.5 h-5 w-5 text-emerald-300" />
                    <div>
                      <p className="font-semibold text-emerald-100">Latest test result</p>
                      <p className="mt-2 text-sm text-emerald-50/90">{testResult.message}</p>
                      <p className="mt-2 text-xs uppercase tracking-[0.24em] text-emerald-200/80">
                        {testResult.model} · {testResult.tested_at}
                      </p>
                    </div>
                  </div>
                </Panel>
              ) : null}
            </div>
          </div>
        ) : null}
      </div>
    </ProtectedShell>
  );
}
