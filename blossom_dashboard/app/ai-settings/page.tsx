'use client';

import { useEffect, useState } from 'react';
import { CheckCircle2, LoaderCircle, PlugZap, Save, XCircle } from 'lucide-react';

import { ProtectedShell } from '@/components/dashboard/protected-shell';
import { Topbar } from '@/components/dashboard/topbar';
import { useAuth } from '@/components/providers/auth-provider';
import { Panel } from '@/components/ui/panel';
import { StatusBadge } from '@/components/ui/status-badge';
import { getAiSettings, testAiConnection, updateAiSettings } from '@/lib/api';
import type { AiConnectionTestResult, AiSettings } from '@/lib/types';

// ── Form ──────────────────────────────────────────────────────────────────────

type FormState = {
  model: string;
  systemPrompt: string;
  temperature: string;
  maxTokens: string;
  isEnabled: boolean;
  apiKey: string;
};

function toFormState(s: AiSettings): FormState {
  return {
    model: s.model,
    systemPrompt: s.system_prompt,
    temperature: String(s.temperature),
    maxTokens: String(s.max_tokens),
    isEnabled: s.is_enabled,
    apiKey: '',
  };
}

function formatDate(value: string | null | undefined): string {
  if (!value) return 'Never';
  try {
    return new Intl.DateTimeFormat('en-GB', {
      day: '2-digit', month: 'short', year: 'numeric',
      hour: '2-digit', minute: '2-digit',
    }).format(new Date(value));
  } catch {
    return value;
  }
}

// ── Page ──────────────────────────────────────────────────────────────────────

export default function AiSettingsPage() {
  const { session } = useAuth();
  const accessToken = session?.access_token ?? null;

  const [ai, setAi] = useState<AiSettings | null>(null);
  const [form, setForm] = useState<FormState | null>(null);
  const [loading, setLoading] = useState(true);
  const [pageError, setPageError] = useState<string | null>(null);

  const [saving, setSaving] = useState(false);
  const [saveError, setSaveError] = useState<string | null>(null);
  const [saveSuccess, setSaveSuccess] = useState(false);

  const [testing, setTesting] = useState(false);
  const [testError, setTestError] = useState<string | null>(null);
  const [testResult, setTestResult] = useState<AiConnectionTestResult | null>(null);

  // ── Load ────────────────────────────────────────────────────────────────────
  useEffect(() => {
    if (!accessToken) return;
    let active = true;
    setLoading(true);
    setPageError(null);
    getAiSettings(accessToken)
      .then((data) => {
        if (!active) return;
        setAi(data);
        setForm(toFormState(data));
      })
      .catch((err) => {
        if (!active) return;
        setPageError(err instanceof Error ? err.message : 'Unable to load AI settings.');
      })
      .finally(() => { if (active) setLoading(false); });
    return () => { active = false; };
  }, [accessToken]);

  // ── Save ────────────────────────────────────────────────────────────────────
  async function handleSave(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (!accessToken || !form) return;
    setSaving(true);
    setSaveError(null);
    setSaveSuccess(false);
    try {
      const updated = await updateAiSettings(accessToken, {
        model: form.model.trim(),
        system_prompt: form.systemPrompt.trim(),
        temperature: Number(form.temperature),
        max_tokens: Number(form.maxTokens),
        is_enabled: form.isEnabled,
        api_key: form.apiKey.trim() || undefined,
      });
      setAi(updated);
      setForm(toFormState(updated));
      setSaveSuccess(true);
      setTimeout(() => setSaveSuccess(false), 3000);
    } catch (err) {
      setSaveError(err instanceof Error ? err.message : 'Unable to save settings.');
    } finally {
      setSaving(false);
    }
  }

  // ── Test ────────────────────────────────────────────────────────────────────
  async function handleTest() {
    if (!accessToken) return;
    setTesting(true);
    setTestError(null);
    setTestResult(null);
    try {
      const result = await testAiConnection(accessToken);
      setTestResult(result);
      const refreshed = await getAiSettings(accessToken);
      setAi(refreshed);
      setForm((f) => f ?? toFormState(refreshed));
    } catch (err) {
      setTestError(err instanceof Error ? err.message : 'Connection test failed.');
      // still refresh to update the stored status
      try {
        const refreshed = await getAiSettings(accessToken);
        setAi(refreshed);
      } catch {}
    } finally {
      setTesting(false);
    }
  }

  // ── Derived ─────────────────────────────────────────────────────────────────
  const statusTone =
    ai?.connection_last_status === 'success' ? 'success'
    : ai?.connection_last_status === 'failed' ? 'danger'
    : 'warning';

  // ── Render ──────────────────────────────────────────────────────────────────
  return (
    <ProtectedShell>
      <div className="space-y-6">
        {/* Header */}
        <Panel className="p-6 sm:p-8">
          <Topbar
            title="AI settings"
            subtitle="Manage the production AI assistant — model, prompt, API key, and connection health."
          />
        </Panel>

        {/* Stat cards */}
        {ai ? (
          <div className="grid gap-4 sm:grid-cols-3">
            <Panel className="p-5">
              <p className="text-sm text-slate-400">Provider</p>
              <p className="mt-2 text-xl font-semibold capitalize text-white">{ai.provider}</p>
              <p className="mt-0.5 text-sm text-slate-500">{ai.model}</p>
            </Panel>
            <Panel className="p-5">
              <p className="text-sm text-slate-400">Connection</p>
              <div className="mt-2">
                <StatusBadge
                  label={ai.connection_last_status ?? 'Not tested'}
                  tone={statusTone}
                />
              </div>
              <p className="mt-1.5 text-xs text-slate-500">{formatDate(ai.connection_last_tested_at)}</p>
            </Panel>
            <Panel className="p-5">
              <p className="text-sm text-slate-400">AI assistant</p>
              <div className="mt-2">
                <StatusBadge
                  label={ai.is_enabled ? 'Enabled' : 'Disabled'}
                  tone={ai.is_enabled ? 'success' : 'warning'}
                />
              </div>
              <p className="mt-1.5 text-xs text-slate-500">
                API key: {ai.has_api_key ? 'Configured' : 'Missing'}
              </p>
            </Panel>
          </div>
        ) : null}

        {/* Page-level error */}
        {pageError ? (
          <Panel className="border-rose-400/20 bg-rose-500/10 p-5 text-sm text-rose-100">
            {pageError}
          </Panel>
        ) : null}

        {loading ? (
          <Panel className="p-8">
            <div className="flex items-center gap-3 text-slate-400">
              <LoaderCircle className="h-5 w-5 animate-spin" />
              Loading AI configuration…
            </div>
          </Panel>
        ) : null}

        {/* Main content */}
        {ai && form ? (
          <div className="grid gap-6 xl:grid-cols-[1fr_360px]">
            {/* ── Settings form ─────────────────────────────────────────────── */}
            <Panel className="overflow-hidden p-0">
              {/* Panel header */}
              <div className="border-b border-emerald-500/20 bg-emerald-600/10 px-6 py-5">
                <p className="text-xs uppercase tracking-widest text-emerald-400">Configuration</p>
                <h2 className="mt-1 text-lg font-semibold text-white">Model &amp; prompt settings</h2>
              </div>

              <form onSubmit={(e) => void handleSave(e)} className="space-y-6 p-6">
                {/* Provider + Model */}
                <div className="grid gap-4 sm:grid-cols-2">
                  <div>
                    <label className="mb-1.5 block text-sm font-medium text-slate-200">Provider</label>
                    <input
                      value={ai.provider}
                      disabled
                      className="w-full rounded-2xl border border-slate-700 bg-slate-950 px-4 py-3 text-sm text-slate-500 outline-none"
                    />
                  </div>
                  <div>
                    <label className="mb-1.5 block text-sm font-medium text-slate-200">Model</label>
                    <select
                      value={form.model}
                      onChange={(e) => setForm((f) => f && { ...f, model: e.target.value })}
                      required
                      className="w-full rounded-2xl border border-slate-700 bg-slate-950 px-4 py-3 text-sm outline-none transition focus:border-emerald-400"
                    >
                      <optgroup label="Flash (fast & efficient)">
                        <option value="gemini-flash-latest">gemini-flash-latest (recommended)</option>
                        <option value="gemini-2.0-flash">gemini-2.0-flash</option>
                        <option value="gemini-2.0-flash-lite">gemini-2.0-flash-lite</option>
                        <option value="gemini-1.5-flash">gemini-1.5-flash</option>
                      </optgroup>
                      <optgroup label="Pro (higher quality)">
                        <option value="gemini-2.0-pro-exp">gemini-2.0-pro-exp</option>
                        <option value="gemini-1.5-pro">gemini-1.5-pro</option>
                      </optgroup>
                    </select>
                  </div>
                </div>

                {/* System prompt */}
                <div>
                  <label className="mb-1.5 block text-sm font-medium text-slate-200">System prompt</label>
                  <textarea
                    value={form.systemPrompt}
                    onChange={(e) => setForm((f) => f && { ...f, systemPrompt: e.target.value })}
                    rows={10}
                    required
                    className="w-full resize-y rounded-3xl border border-slate-700 bg-slate-950 px-4 py-4 text-sm outline-none transition focus:border-emerald-400"
                  />
                </div>

                {/* Temperature + Max tokens */}
                <div className="grid gap-4 sm:grid-cols-2">
                  <div>
                    <label className="mb-1.5 block text-sm font-medium text-slate-200">Temperature</label>
                    <input
                      type="number"
                      min="0" max="2" step="0.1"
                      value={form.temperature}
                      onChange={(e) => setForm((f) => f && { ...f, temperature: e.target.value })}
                      required
                      className="w-full rounded-2xl border border-slate-700 bg-slate-950 px-4 py-3 text-sm outline-none transition focus:border-emerald-400"
                    />
                  </div>
                  <div>
                    <label className="mb-1.5 block text-sm font-medium text-slate-200">Max tokens</label>
                    <input
                      type="number"
                      min="1" step="1"
                      value={form.maxTokens}
                      onChange={(e) => setForm((f) => f && { ...f, maxTokens: e.target.value })}
                      required
                      className="w-full rounded-2xl border border-slate-700 bg-slate-950 px-4 py-3 text-sm outline-none transition focus:border-emerald-400"
                    />
                  </div>
                </div>

                {/* API key */}
                <div>
                  <label className="mb-1.5 block text-sm font-medium text-slate-200">Replace API key</label>
                  <input
                    type="password"
                    value={form.apiKey}
                    onChange={(e) => setForm((f) => f && { ...f, apiKey: e.target.value })}
                    placeholder={
                      ai.has_api_key
                        ? 'Key stored — enter a new one to replace it'
                        : 'Paste your Gemini API key'
                    }
                    className="w-full rounded-2xl border border-slate-700 bg-slate-950 px-4 py-3 text-sm outline-none transition focus:border-emerald-400"
                  />
                  <p className="mt-1.5 text-xs text-slate-500">
                    Leave blank to keep the existing encrypted key.
                  </p>
                </div>

                {/* Enable toggle */}
                <label className="flex cursor-pointer items-center justify-between gap-4 rounded-2xl border border-slate-800 bg-slate-950/80 px-4 py-4">
                  <div>
                    <p className="text-sm font-medium text-white">Enable AI assistant</p>
                    <p className="mt-0.5 text-xs text-slate-500">
                      Controls whether AI identification runs in production.
                    </p>
                  </div>
                  <input
                    type="checkbox"
                    checked={form.isEnabled}
                    onChange={(e) => setForm((f) => f && { ...f, isEnabled: e.target.checked })}
                    className="h-5 w-5 rounded border-slate-600 bg-slate-950 text-emerald-500"
                  />
                </label>

                {/* Inline save feedback */}
                {saveError ? (
                  <div className="flex items-center gap-2 rounded-2xl border border-rose-400/20 bg-rose-500/10 px-4 py-3 text-sm text-rose-100">
                    <XCircle className="h-4 w-4 shrink-0" />
                    {saveError}
                  </div>
                ) : null}
                {saveSuccess ? (
                  <div className="flex items-center gap-2 rounded-2xl border border-emerald-400/20 bg-emerald-500/10 px-4 py-3 text-sm text-emerald-100">
                    <CheckCircle2 className="h-4 w-4 shrink-0" />
                    Settings saved successfully.
                  </div>
                ) : null}

                {/* Footer buttons */}
                <div className="flex flex-wrap gap-3 border-t border-border pt-4">
                  <button
                    type="submit"
                    disabled={saving}
                    className="inline-flex items-center gap-2 rounded-2xl bg-emerald-500 px-5 py-2.5 text-sm font-semibold text-slate-950 transition hover:bg-emerald-400 disabled:cursor-not-allowed disabled:opacity-60"
                  >
                    {saving ? <LoaderCircle className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
                    {saving ? 'Saving…' : 'Save settings'}
                  </button>
                  <button
                    type="button"
                    onClick={() => void handleTest()}
                    disabled={testing}
                    className="inline-flex items-center gap-2 rounded-2xl border border-slate-700 bg-slate-800 px-5 py-2.5 text-sm font-semibold text-slate-200 transition hover:bg-slate-700 disabled:cursor-not-allowed disabled:opacity-60"
                  >
                    {testing ? <LoaderCircle className="h-4 w-4 animate-spin" /> : <PlugZap className="h-4 w-4" />}
                    {testing ? 'Testing…' : 'Test connection'}
                  </button>
                </div>
              </form>
            </Panel>

            {/* ── Right sidebar ─────────────────────────────────────────────── */}
            <div className="space-y-4">
              {/* Test result */}
              {testResult ? (
                <Panel className="border-emerald-400/20 bg-emerald-500/10 p-5">
                  <div className="flex items-start gap-3">
                    <CheckCircle2 className="mt-0.5 h-5 w-5 shrink-0 text-emerald-300" />
                    <div>
                      <p className="font-semibold text-emerald-100">Connection successful</p>
                      <p className="mt-1 text-sm text-emerald-50/80">{testResult.message}</p>
                      <p className="mt-2 text-xs uppercase tracking-widest text-emerald-300/70">
                        {testResult.model}
                      </p>
                      <p className="text-xs text-emerald-300/50">{formatDate(testResult.tested_at)}</p>
                    </div>
                  </div>
                </Panel>
              ) : null}

              {testError ? (
                <Panel className="border-rose-400/20 bg-rose-500/10 p-5">
                  <div className="flex items-start gap-2">
                    <XCircle className="mt-0.5 h-4 w-4 shrink-0 text-rose-300" />
                    <p className="text-sm text-rose-100">{testError}</p>
                  </div>
                </Panel>
              ) : null}

              {/* Connection detail */}
              <Panel className="p-5">
                <p className="text-xs uppercase tracking-widest text-sky-300">Connection detail</p>
                <dl className="mt-4 space-y-3 text-sm">
                  <div className="flex items-center justify-between">
                    <dt className="text-slate-500">API key</dt>
                    <dd className={ai.has_api_key ? 'text-emerald-400' : 'text-rose-400'}>
                      {ai.has_api_key ? 'Configured' : 'Missing'}
                    </dd>
                  </div>
                  <div className="flex items-center justify-between">
                    <dt className="text-slate-500">Last status</dt>
                    <dd>
                      <StatusBadge
                        label={ai.connection_last_status ?? 'Not tested'}
                        tone={statusTone}
                      />
                    </dd>
                  </div>
                  <div>
                    <dt className="text-slate-500">Last tested</dt>
                    <dd className="mt-1 text-slate-300">{formatDate(ai.connection_last_tested_at)}</dd>
                  </div>
                  <div>
                    <dt className="text-slate-500">Last updated</dt>
                    <dd className="mt-1 text-slate-300">{formatDate(ai.updated_at)}</dd>
                  </div>
                </dl>
              </Panel>

              {/* Tips */}
              <Panel className="p-5">
                <p className="text-xs uppercase tracking-widest text-slate-500">Tips</p>
                <ul className="mt-3 space-y-2 text-xs text-slate-400">
                  <li>• Temperature 0.0–0.4 produces more deterministic plant IDs.</li>
                  <li>• Keep max tokens ≥ 512 to avoid truncated JSON responses.</li>
                  <li>• The API key is encrypted at rest with AES-256 (Fernet).</li>
                  <li>• Disable AI here to block all identification requests in production.</li>
                </ul>
              </Panel>
            </div>
          </div>
        ) : null}
      </div>
    </ProtectedShell>
  );
}
