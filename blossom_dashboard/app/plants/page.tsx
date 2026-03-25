'use client';

import { useEffect, useMemo, useState } from 'react';
import { ImageIcon, LoaderCircle, Pencil, Plus, Trash2, X } from 'lucide-react';

import { ProtectedShell } from '@/components/dashboard/protected-shell';
import { Topbar } from '@/components/dashboard/topbar';
import { useAuth } from '@/components/providers/auth-provider';
import { Panel } from '@/components/ui/panel';
import { StatusBadge } from '@/components/ui/status-badge';
import {
  archiveAdminPlant,
  createAdminPlant,
  listAdminPlants,
  updateAdminPlant,
} from '@/lib/api';
import { getSupabaseBrowserClient } from '@/lib/supabase';
import type { Plant, PlantMutationPayload } from '@/lib/types';

// ── Types ─────────────────────────────────────────────────────────────────────

type DayKey = 'mon' | 'tue' | 'wed' | 'thu' | 'fri' | 'sat' | 'sun';
type WeeklyDay = { day: DayKey; times: number };
type MonthlyDate = { date: number; times: number };

type WaterSchedule =
  | { type: 'daily'; times_per_day: number }
  | { type: 'weekly'; days: WeeklyDay[] }
  | { type: 'monthly'; dates: MonthlyDate[] };

// ── Constants ─────────────────────────────────────────────────────────────────

const LIGHT_OPTIONS = [
  'Full Sun',
  'Bright Direct Light',
  'Bright Indirect Light',
  'Indirect Light',
  'Low Light',
  'Deep Shade',
];

const DAYS_CONFIG: { key: DayKey; label: string }[] = [
  { key: 'mon', label: 'Monday' },
  { key: 'tue', label: 'Tuesday' },
  { key: 'wed', label: 'Wednesday' },
  { key: 'thu', label: 'Thursday' },
  { key: 'fri', label: 'Friday' },
  { key: 'sat', label: 'Saturday' },
  { key: 'sun', label: 'Sunday' },
];

// ── Water schedule helpers ────────────────────────────────────────────────────

function parseWaterSchedule(value: string): WaterSchedule {
  try {
    const parsed = JSON.parse(value) as WaterSchedule;
    if (parsed.type === 'daily' || parsed.type === 'weekly' || parsed.type === 'monthly') {
      return parsed;
    }
  } catch {}
  // Legacy: numeric string (days or fractional days)
  const n = parseFloat(value);
  if (!isNaN(n) && n > 0 && n < 1) {
    return { type: 'daily', times_per_day: Math.max(1, Math.round(1 / n)) };
  }
  if (!isNaN(n) && n >= 1) {
    if (n % 7 === 0) {
      const weeks = n / 7;
      // Build a simple weekly schedule
      const days: WeeklyDay[] = [{ day: 'mon', times: 1 }];
      if (weeks <= 1) return { type: 'weekly', days };
    }
    return { type: 'daily', times_per_day: 1 };
  }
  return { type: 'daily', times_per_day: 1 };
}

function formatWaterForDisplay(value: string): string {
  try {
    const s = JSON.parse(value) as WaterSchedule;
    if (s.type === 'daily') {
      return s.times_per_day === 1 ? 'Daily' : `${s.times_per_day}× / day`;
    }
    if (s.type === 'weekly') {
      const total = s.days.reduce((sum, d) => sum + d.times, 0);
      return `${total}× / week`;
    }
    if (s.type === 'monthly') {
      const total = s.dates.reduce((sum, d) => sum + d.times, 0);
      return `${total}× / month`;
    }
  } catch {}
  // Legacy numeric
  const n = parseFloat(value);
  if (isNaN(n) || n <= 0) return value;
  if (n < 1) return `${Math.round(1 / n)}× / day`;
  if (n === 1) return 'Daily';
  if (n % 7 === 0) return `Every ${n / 7} week${n / 7 > 1 ? 's' : ''}`;
  return `Every ${n} days`;
}

function scheduleToText(s: WaterSchedule): string {
  if (s.type === 'daily') {
    const t = s.times_per_day;
    if (t === 1) return 'Once per day (daily)';
    const hours = Math.round((24 / t) * 10) / 10;
    return `${t}× per day — every ${hours}h`;
  }
  if (s.type === 'weekly') {
    if (s.days.length === 0) return 'No days selected';
    const total = s.days.reduce((sum, d) => sum + d.times, 0);
    const sorted = [...s.days].sort(
      (a, b) => DAYS_CONFIG.findIndex((d) => d.key === a.day) - DAYS_CONFIG.findIndex((d) => d.key === b.day),
    );
    const summary = sorted.map((d) => `${d.day}×${d.times}`).join(', ');
    return `${total} watering${total !== 1 ? 's' : ''}/week — ${summary}`;
  }
  if (s.type === 'monthly') {
    if (s.dates.length === 0) return 'No dates selected';
    const total = s.dates.reduce((sum, d) => sum + d.times, 0);
    return `${total} watering${total !== 1 ? 's' : ''}/month on ${s.dates.length} date${s.dates.length !== 1 ? 's' : ''}`;
  }
  return '';
}

function validateSchedule(s: WaterSchedule): string | null {
  if (s.type === 'weekly' && s.days.length === 0) return 'Select at least one watering day.';
  if (s.type === 'monthly' && s.dates.length === 0) return 'Select at least one watering date.';
  return null;
}

function ordinal(n: number): string {
  if (n >= 11 && n <= 13) return `${n}th`;
  switch (n % 10) {
    case 1: return `${n}st`;
    case 2: return `${n}nd`;
    case 3: return `${n}rd`;
    default: return `${n}th`;
  }
}

// ── Form ──────────────────────────────────────────────────────────────────────

type PlantFormState = {
  commonName: string;
  shortDescription: string;
  imagePath: string;
  temperatureFrom: string;
  temperatureTo: string;
  lightRequirements: string;
  locationType: string;
  caringDifficulty: string;
  waterSchedule: WaterSchedule;
};

function emptyForm(): PlantFormState {
  return {
    commonName: '',
    shortDescription: '',
    imagePath: '',
    temperatureFrom: '15',
    temperatureTo: '25',
    lightRequirements: 'Indirect Light',
    locationType: 'Both',
    caringDifficulty: 'low',
    waterSchedule: { type: 'daily', times_per_day: 1 },
  };
}

function parseTemperature(temp: string): { from: string; to: string } {
  const match = temp.match(/(\d+(?:\.\d+)?)\s*°?C?\s*[-–]\s*(\d+(?:\.\d+)?)/);
  if (match) return { from: match[1], to: match[2] };
  const single = temp.match(/(\d+(?:\.\d+)?)/);
  return single ? { from: single[1], to: '' } : { from: '', to: '' };
}

function toFormState(plant: Plant): PlantFormState {
  const { from: tempFrom, to: tempTo } = parseTemperature(plant.temperature);
  return {
    commonName: plant.common_name,
    shortDescription: plant.short_description,
    imagePath: plant.image_path ?? '',
    temperatureFrom: tempFrom,
    temperatureTo: tempTo,
    lightRequirements: plant.light_requirements,
    locationType: plant.location_type ?? 'Both',
    caringDifficulty: plant.caring_difficulty ?? 'low',
    waterSchedule: parseWaterSchedule(plant.water_requirements),
  };
}

function toPayload(
  form: PlantFormState,
  opts?: { existingPlant?: Plant; imagePath?: string },
): PlantMutationPayload {
  const existing = opts?.existingPlant;
  const finalImagePath = opts?.imagePath ?? form.imagePath;
  const temp = form.temperatureTo
    ? `${form.temperatureFrom}°C - ${form.temperatureTo}°C`
    : `${form.temperatureFrom}°C`;
  return {
    common_name: form.commonName.trim(),
    scientific_name: existing?.scientific_name ?? null,
    short_description: form.shortDescription.trim(),
    image_path: finalImagePath.trim() || null,
    water_requirements: JSON.stringify(form.waterSchedule),
    light_requirements: form.lightRequirements,
    temperature: temp,
    pet_safe: existing?.pet_safe ?? false,
    location_type: form.locationType,
    caring_difficulty: form.caringDifficulty,
    source: existing?.source ?? 'admin',
    ai_confidence: existing?.ai_confidence ?? null,
    reviewed_by_admin: existing?.reviewed_by_admin ?? true,
    is_active: existing?.is_active ?? true,
  };
}

async function uploadPlantImage(file: File): Promise<string> {
  const supabase = getSupabaseBrowserClient();
  if (!supabase) throw new Error('Supabase is not configured. Cannot upload image.');
  const extension = file.name.split('.').pop() ?? 'jpg';
  const fileName = `${crypto.randomUUID()}.${extension}`;
  const { error } = await supabase.storage
    .from('plant-images')
    .upload(fileName, file, { upsert: false });
  if (error) throw new Error(`Image upload failed: ${error.message}`);
  const { data } = supabase.storage.from('plant-images').getPublicUrl(fileName);
  return data.publicUrl;
}

function upsertPlant(plants: Plant[], plant: Plant): Plant[] {
  const next = plants.some((p) => p.id === plant.id)
    ? plants.map((p) => (p.id === plant.id ? plant : p))
    : [plant, ...plants];
  return next.sort((a, b) => a.common_name.localeCompare(b.common_name));
}

// ── WaterScheduleBuilder ──────────────────────────────────────────────────────

function WaterScheduleBuilder({
  value,
  onChange,
}: {
  value: WaterSchedule;
  onChange: (s: WaterSchedule) => void;
}) {
  function switchType(type: WaterSchedule['type']) {
    if (type === 'daily') onChange({ type: 'daily', times_per_day: 1 });
    else if (type === 'weekly') onChange({ type: 'weekly', days: [{ day: 'mon', times: 1 }] });
    else onChange({ type: 'monthly', dates: [{ date: 1, times: 1 }] });
  }

  return (
    <div className="space-y-3">
      <label className="block text-sm font-medium text-slate-200">Watering schedule</label>

      {/* Mode tabs */}
      <div className="flex gap-1.5 rounded-2xl border border-slate-700 bg-slate-950 p-1">
        {(['daily', 'weekly', 'monthly'] as const).map((t) => (
          <button
            key={t}
            type="button"
            onClick={() => switchType(t)}
            className={`flex-1 rounded-xl py-2 text-sm font-medium capitalize transition ${
              value.type === t
                ? 'bg-emerald-500 text-slate-950 shadow'
                : 'text-slate-400 hover:text-white'
            }`}
          >
            {t}
          </button>
        ))}
      </div>

      {/* ── Daily ── */}
      {value.type === 'daily' && (
        <div className="rounded-2xl border border-slate-700 bg-slate-950 p-4">
          <div className="flex items-center gap-4">
            <span className="text-sm text-slate-300">Times per day</span>
            <input
              type="number"
              min="1"
              max="24"
              value={value.times_per_day}
              onChange={(e) => {
                const n = Math.max(1, Math.min(24, parseInt(e.target.value, 10) || 1));
                onChange({ ...value, times_per_day: n });
              }}
              className="w-20 rounded-xl border border-slate-700 bg-slate-900 px-3 py-2 text-center text-sm outline-none focus:border-emerald-400"
            />
            {value.times_per_day > 1 && (
              <span className="text-xs text-slate-500">
                every{' '}
                <span className="font-medium text-emerald-400">
                  {Math.round((24 / value.times_per_day) * 10) / 10}h
                </span>
              </span>
            )}
          </div>
        </div>
      )}

      {/* ── Weekly ── */}
      {value.type === 'weekly' && (
        <div className="rounded-2xl border border-slate-700 bg-slate-950 p-4 space-y-2.5">
          {DAYS_CONFIG.map(({ key, label }) => {
            const entry = value.days.find((d) => d.day === key);
            const checked = !!entry;
            return (
              <div key={key} className="flex items-center gap-3">
                <label className="flex w-28 cursor-pointer items-center gap-2.5">
                  <input
                    type="checkbox"
                    checked={checked}
                    onChange={(e) => {
                      if (e.target.checked) {
                        onChange({ ...value, days: [...value.days, { day: key, times: 1 }] });
                      } else {
                        onChange({ ...value, days: value.days.filter((d) => d.day !== key) });
                      }
                    }}
                    className="h-4 w-4 rounded border-slate-600 bg-slate-900 text-emerald-500"
                  />
                  <span className={`text-sm ${checked ? 'text-white' : 'text-slate-500'}`}>
                    {label}
                  </span>
                </label>
                {checked && (
                  <div className="flex items-center gap-2">
                    <input
                      type="number"
                      min="1"
                      max="24"
                      value={entry!.times}
                      onChange={(e) => {
                        const n = Math.max(1, Math.min(24, parseInt(e.target.value, 10) || 1));
                        onChange({
                          ...value,
                          days: value.days.map((d) => (d.day === key ? { ...d, times: n } : d)),
                        });
                      }}
                      className="w-16 rounded-xl border border-slate-700 bg-slate-900 px-3 py-1.5 text-center text-sm outline-none focus:border-emerald-400"
                    />
                    <span className="text-xs text-slate-500">
                      {entry!.times === 1 ? 'time' : 'times'}
                    </span>
                  </div>
                )}
              </div>
            );
          })}
          {value.days.length > 0 ? (
            <p className="border-t border-slate-800 pt-2 text-xs text-slate-500">
              <span className="font-medium text-emerald-400">
                {value.days.reduce((s, d) => s + d.times, 0)} waterings/week
              </span>
            </p>
          ) : (
            <p className="text-xs text-rose-400">Select at least one day.</p>
          )}
        </div>
      )}

      {/* ── Monthly ── */}
      {value.type === 'monthly' && (
        <div className="rounded-2xl border border-slate-700 bg-slate-950 p-4 space-y-3">
          <p className="text-xs text-slate-400">Select which dates to water:</p>
          {/* Date grid */}
          <div className="grid grid-cols-7 gap-1">
            {Array.from({ length: 31 }, (_, i) => i + 1).map((date) => {
              const selected = value.dates.some((d) => d.date === date);
              return (
                <button
                  key={date}
                  type="button"
                  onClick={() => {
                    if (selected) {
                      onChange({ ...value, dates: value.dates.filter((d) => d.date !== date) });
                    } else {
                      const next = [...value.dates, { date, times: 1 }].sort(
                        (a, b) => a.date - b.date,
                      );
                      onChange({ ...value, dates: next });
                    }
                  }}
                  className={`rounded-lg py-1.5 text-xs font-medium transition ${
                    selected
                      ? 'bg-emerald-500 text-slate-950'
                      : 'border border-slate-700 bg-slate-900 text-slate-400 hover:border-emerald-500/40 hover:text-slate-200'
                  }`}
                >
                  {date}
                </button>
              );
            })}
          </div>
          {/* Times per selected date */}
          {value.dates.length > 0 ? (
            <div className="space-y-2 border-t border-slate-800 pt-3">
              {value.dates.map((entry) => (
                <div key={entry.date} className="flex items-center gap-3">
                  <span className="w-12 text-sm text-slate-300">{ordinal(entry.date)}</span>
                  <input
                    type="number"
                    min="1"
                    max="24"
                    value={entry.times}
                    onChange={(e) => {
                      const n = Math.max(1, Math.min(24, parseInt(e.target.value, 10) || 1));
                      onChange({
                        ...value,
                        dates: value.dates.map((d) =>
                          d.date === entry.date ? { ...d, times: n } : d,
                        ),
                      });
                    }}
                    className="w-16 rounded-xl border border-slate-700 bg-slate-900 px-3 py-1.5 text-center text-sm outline-none focus:border-emerald-400"
                  />
                  <span className="text-xs text-slate-500">
                    {entry.times === 1 ? 'time' : 'times'}
                  </span>
                </div>
              ))}
              <p className="pt-1 text-xs text-slate-500">
                <span className="font-medium text-emerald-400">
                  {value.dates.reduce((s, d) => s + d.times, 0)} waterings/month
                </span>
              </p>
            </div>
          ) : (
            <p className="text-xs text-rose-400">Select at least one date.</p>
          )}
        </div>
      )}

      {/* Summary */}
      <p className="text-xs text-slate-500">
        <span className="font-medium text-emerald-400">{scheduleToText(value)}</span>
        {' — '}users receive a push notification for each watering.
      </p>
    </div>
  );
}

// ── Page ──────────────────────────────────────────────────────────────────────

export default function PlantsPage() {
  const { session } = useAuth();
  const accessToken = session?.access_token ?? null;

  const [plants, setPlants] = useState<Plant[]>([]);
  const [loading, setLoading] = useState(true);
  const [pageError, setPageError] = useState<string | null>(null);

  // filters
  const [query, setQuery] = useState('');
  const [filterLight, setFilterLight] = useState('');
  const [filterDifficulty, setFilterDifficulty] = useState('');
  const [showArchived, setShowArchived] = useState(false);

  // modal
  const [modalOpen, setModalOpen] = useState(false);
  const [editingPlant, setEditingPlant] = useState<Plant | null>(null);
  const [form, setForm] = useState<PlantFormState>(emptyForm());
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [imagePreviewUrl, setImagePreviewUrl] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [uploadingImage, setUploadingImage] = useState(false);
  const [modalError, setModalError] = useState<string | null>(null);

  const [archivingId, setArchivingId] = useState<string | null>(null);

  // ── Load ──────────────────────────────────────────────────────────────────
  useEffect(() => {
    if (!accessToken) return;
    let active = true;
    setLoading(true);
    setPageError(null);
    listAdminPlants(accessToken)
      .then((payload) => { if (active) setPlants(payload); })
      .catch((err) => { if (active) setPageError(err instanceof Error ? err.message : 'Unable to load plants.'); })
      .finally(() => { if (active) setLoading(false); });
    return () => { active = false; };
  }, [accessToken]);

  // ── Derived ───────────────────────────────────────────────────────────────
  const filteredPlants = useMemo(() => {
    const needle = query.trim().toLowerCase();
    return plants.filter((p) => {
      if (!showArchived && !p.is_active) return false;
      if (filterLight && !p.light_requirements.toLowerCase().includes(filterLight.toLowerCase()))
        return false;
      if (filterDifficulty && (p.caring_difficulty ?? '') !== filterDifficulty) return false;
      if (!needle) return true;
      return (
        p.common_name.toLowerCase().includes(needle) ||
        (p.scientific_name ?? '').toLowerCase().includes(needle)
      );
    });
  }, [plants, query, filterLight, filterDifficulty, showArchived]);

  const activeCount = useMemo(() => plants.filter((p) => p.is_active).length, [plants]);

  // ── Modal ─────────────────────────────────────────────────────────────────
  function openCreate() {
    setEditingPlant(null);
    setForm(emptyForm());
    setImageFile(null);
    setImagePreviewUrl(null);
    setModalError(null);
    setModalOpen(true);
  }

  function openEdit(plant: Plant) {
    setEditingPlant(plant);
    setForm(toFormState(plant));
    setImageFile(null);
    setImagePreviewUrl(null);
    setModalError(null);
    setModalOpen(true);
  }

  function closeModal() {
    if (saving) return;
    setModalOpen(false);
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  async function handleSave(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!accessToken) return;

    const scheduleError = validateSchedule(form.waterSchedule);
    if (scheduleError) { setModalError(scheduleError); return; }

    setSaving(true);
    setModalError(null);
    try {
      let imagePath = form.imagePath;
      if (imageFile) {
        setUploadingImage(true);
        imagePath = await uploadPlantImage(imageFile);
        setUploadingImage(false);
      }
      const payload = toPayload(form, { existingPlant: editingPlant ?? undefined, imagePath });
      if (!payload.common_name) throw new Error('Plant name is required.');
      const saved = editingPlant
        ? await updateAdminPlant(accessToken, editingPlant.id, payload)
        : await createAdminPlant(accessToken, payload);
      setPlants((curr) => upsertPlant(curr, saved));
      setModalOpen(false);
    } catch (err) {
      setModalError(err instanceof Error ? err.message : 'Unable to save plant.');
    } finally {
      setSaving(false);
      setUploadingImage(false);
    }
  }

  // ── Archive ───────────────────────────────────────────────────────────────
  async function handleArchive(plant: Plant) {
    if (!accessToken) return;
    setArchivingId(plant.id);
    try {
      const archived = await archiveAdminPlant(accessToken, plant.id);
      setPlants((curr) => upsertPlant(curr, archived));
    } catch {
      // silently fail — user can retry
    } finally {
      setArchivingId(null);
    }
  }

  // ── Render ────────────────────────────────────────────────────────────────
  return (
    <ProtectedShell>
      <div className="space-y-6">
        <Panel className="p-6 sm:p-8">
          <Topbar
            title="Plant catalog"
            subtitle="Manage the plants available in the Blossom app. Add, edit, or archive entries from the catalog."
          />
        </Panel>

        {/* Stats */}
        <div className="grid gap-4 sm:grid-cols-3">
          <Panel className="p-5">
            <p className="text-sm text-slate-400">Total plants</p>
            <p className="mt-2 text-3xl font-semibold text-white">{plants.length}</p>
          </Panel>
          <Panel className="p-5">
            <p className="text-sm text-slate-400">Active</p>
            <p className="mt-2 text-3xl font-semibold text-emerald-400">{activeCount}</p>
          </Panel>
          <Panel className="p-5">
            <p className="text-sm text-slate-400">Archived</p>
            <p className="mt-2 text-3xl font-semibold text-slate-500">
              {plants.length - activeCount}
            </p>
          </Panel>
        </div>

        {pageError ? (
          <Panel className="border-rose-400/20 bg-rose-500/10 p-5 text-sm text-rose-100">
            {pageError}
          </Panel>
        ) : null}

        {/* Table */}
        <Panel className="overflow-hidden p-0">
          {/* Toolbar */}
          <div className="flex flex-wrap items-center gap-3 border-b border-border px-5 py-4">
            <input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Search plants…"
              className="min-w-0 flex-1 rounded-xl border border-slate-700 bg-slate-950 px-4 py-2.5 text-sm outline-none transition focus:border-emerald-400"
            />
            <select
              value={filterLight}
              onChange={(e) => setFilterLight(e.target.value)}
              className="rounded-xl border border-slate-700 bg-slate-950 px-3 py-2.5 text-sm outline-none transition focus:border-emerald-400"
            >
              <option value="">All light types</option>
              {LIGHT_OPTIONS.map((opt) => (
                <option key={opt} value={opt}>{opt}</option>
              ))}
            </select>
            <select
              value={filterDifficulty}
              onChange={(e) => setFilterDifficulty(e.target.value)}
              className="rounded-xl border border-slate-700 bg-slate-950 px-3 py-2.5 text-sm outline-none transition focus:border-emerald-400"
            >
              <option value="">All difficulties</option>
              <option value="low">Easy</option>
              <option value="high">Demanding</option>
            </select>
            <label className="flex cursor-pointer items-center gap-2 text-sm text-slate-300">
              <input
                type="checkbox"
                checked={showArchived}
                onChange={(e) => setShowArchived(e.target.checked)}
                className="h-4 w-4 rounded border-slate-600 bg-slate-950 text-emerald-500"
              />
              Show archived
            </label>
            <button
              type="button"
              onClick={openCreate}
              className="inline-flex items-center gap-2 rounded-xl bg-emerald-500 px-4 py-2.5 text-sm font-semibold text-slate-950 transition hover:bg-emerald-400"
            >
              <Plus className="h-4 w-4" />
              Add plant
            </button>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border text-left text-xs uppercase tracking-wider text-slate-500">
                  <th className="w-14 px-4 py-3" />
                  <th className="px-4 py-3">Name</th>
                  <th className="px-4 py-3">Light</th>
                  <th className="px-4 py-3">Temperature</th>
                  <th className="px-4 py-3">Water</th>
                  <th className="px-4 py-3">Difficulty</th>
                  <th className="px-4 py-3">Status</th>
                  <th className="px-4 py-3 text-right">Actions</th>
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  <tr>
                    <td colSpan={8} className="px-4 py-14 text-center">
                      <LoaderCircle className="mx-auto h-5 w-5 animate-spin text-slate-500" />
                    </td>
                  </tr>
                ) : filteredPlants.length === 0 ? (
                  <tr>
                    <td colSpan={8} className="px-4 py-14 text-center text-slate-500">
                      No plants match your filters.
                    </td>
                  </tr>
                ) : (
                  filteredPlants.map((plant) => (
                    <tr
                      key={plant.id}
                      className="border-b border-border/50 transition hover:bg-slate-900/40"
                    >
                      <td className="px-4 py-3">
                        {plant.image_path ? (
                          <img
                            src={plant.image_path}
                            alt={plant.common_name}
                            className="h-10 w-10 rounded-lg object-cover"
                          />
                        ) : (
                          <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-slate-800">
                            <ImageIcon className="h-4 w-4 text-slate-600" />
                          </div>
                        )}
                      </td>
                      <td className="px-4 py-3">
                        <p className="font-medium text-white">{plant.common_name}</p>
                        {plant.scientific_name ? (
                          <p className="text-xs italic text-slate-500">{plant.scientific_name}</p>
                        ) : null}
                      </td>
                      <td className="px-4 py-3 text-slate-300">{plant.light_requirements}</td>
                      <td className="px-4 py-3 text-slate-300">{plant.temperature}</td>
                      <td className="px-4 py-3 text-slate-300">
                        {formatWaterForDisplay(plant.water_requirements)}
                      </td>
                      <td className="px-4 py-3">
                        <StatusBadge
                          label={plant.caring_difficulty === 'high' ? 'Demanding' : 'Easy'}
                          tone={plant.caring_difficulty === 'high' ? 'warning' : 'success'}
                        />
                      </td>
                      <td className="px-4 py-3">
                        <StatusBadge
                          label={plant.is_active ? 'Active' : 'Archived'}
                          tone={plant.is_active ? 'success' : 'neutral'}
                        />
                      </td>
                      <td className="px-4 py-3 text-right">
                        <div className="inline-flex gap-2">
                          <button
                            type="button"
                            onClick={() => openEdit(plant)}
                            title="Edit"
                            className="rounded-lg border border-slate-700 bg-slate-900 p-2 text-slate-400 transition hover:border-emerald-500/50 hover:text-emerald-300"
                          >
                            <Pencil className="h-3.5 w-3.5" />
                          </button>
                          <button
                            type="button"
                            onClick={() => void handleArchive(plant)}
                            disabled={!plant.is_active || archivingId === plant.id}
                            title={plant.is_active ? 'Archive' : 'Already archived'}
                            className="rounded-lg border border-slate-700 bg-slate-900 p-2 text-slate-400 transition hover:border-rose-500/50 hover:text-rose-300 disabled:cursor-not-allowed disabled:opacity-40"
                          >
                            {archivingId === plant.id ? (
                              <LoaderCircle className="h-3.5 w-3.5 animate-spin" />
                            ) : (
                              <Trash2 className="h-3.5 w-3.5" />
                            )}
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </Panel>
      </div>

      {/* Modal */}
      {modalOpen ? (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-slate-950/80 backdrop-blur-sm" onClick={closeModal} />
          <div className="relative z-10 w-full max-w-2xl rounded-3xl border border-border bg-slate-900 shadow-2xl">
            {/* Header */}
            <div className="flex items-center justify-between rounded-t-3xl border-b border-emerald-500/20 bg-emerald-600/10 px-6 py-5">
              <div>
                <p className="text-xs uppercase tracking-widest text-emerald-400">
                  {editingPlant ? 'Edit plant' : 'New plant'}
                </p>
                <h2 className="mt-1 text-xl font-semibold text-white">
                  {editingPlant ? editingPlant.common_name : 'Add to catalog'}
                </h2>
              </div>
              <button
                type="button"
                onClick={closeModal}
                className="rounded-xl border border-slate-700 bg-slate-800 p-2 text-slate-400 transition hover:text-white"
              >
                <X className="h-4 w-4" />
              </button>
            </div>

            {/* Body */}
            <form onSubmit={(e) => void handleSave(e)}>
              <div className="max-h-[66vh] space-y-5 overflow-y-auto px-6 py-6">
                {modalError ? (
                  <div className="rounded-2xl border border-rose-400/20 bg-rose-500/10 px-4 py-3 text-sm text-rose-100">
                    {modalError}
                  </div>
                ) : null}

                {/* Name */}
                <div>
                  <label className="mb-1.5 block text-sm font-medium text-slate-200">
                    Plant name <span className="text-rose-400">*</span>
                  </label>
                  <input
                    value={form.commonName}
                    onChange={(e) => setForm((f) => ({ ...f, commonName: e.target.value }))}
                    placeholder="e.g. Peace Lily"
                    required
                    className="w-full rounded-2xl border border-slate-700 bg-slate-950 px-4 py-3 text-sm outline-none transition focus:border-emerald-400"
                  />
                </div>

                {/* Description */}
                <div>
                  <label className="mb-1.5 block text-sm font-medium text-slate-200">
                    Short description
                  </label>
                  <textarea
                    rows={3}
                    value={form.shortDescription}
                    onChange={(e) => setForm((f) => ({ ...f, shortDescription: e.target.value }))}
                    placeholder="A brief description of this plant and its characteristics…"
                    className="w-full resize-none rounded-2xl border border-slate-700 bg-slate-950 px-4 py-3 text-sm outline-none transition focus:border-emerald-400"
                  />
                </div>

                {/* Image */}
                <div>
                  <label className="mb-1.5 block text-sm font-medium text-slate-200">
                    Plant image
                  </label>
                  {imagePreviewUrl ?? form.imagePath ? (
                    <div className="relative mb-3">
                      <img
                        src={imagePreviewUrl ?? form.imagePath ?? ''}
                        alt="Preview"
                        className="h-40 w-full rounded-2xl object-cover"
                      />
                      <button
                        type="button"
                        onClick={() => {
                          setImageFile(null);
                          setImagePreviewUrl(null);
                          setForm((f) => ({ ...f, imagePath: '' }));
                        }}
                        className="absolute right-2 top-2 rounded-full bg-slate-900/80 p-1.5 text-slate-400 transition hover:text-white"
                      >
                        <X className="h-3.5 w-3.5" />
                      </button>
                    </div>
                  ) : null}
                  <label className="flex cursor-pointer items-center justify-center gap-2 rounded-2xl border border-dashed border-slate-600 bg-slate-950 px-4 py-4 text-sm text-slate-400 transition hover:border-emerald-400 hover:text-emerald-300">
                    <input
                      type="file"
                      accept="image/*"
                      className="sr-only"
                      onChange={(e) => {
                        const file = e.target.files?.[0] ?? null;
                        setImageFile(file);
                        setImagePreviewUrl(file ? URL.createObjectURL(file) : null);
                      }}
                    />
                    {uploadingImage ? (
                      <><LoaderCircle className="h-4 w-4 animate-spin" /> Uploading…</>
                    ) : imageFile ? (
                      <><ImageIcon className="h-4 w-4" /> {imageFile.name}</>
                    ) : (
                      <><ImageIcon className="h-4 w-4" /> Click to upload an image</>
                    )}
                  </label>
                </div>

                {/* Temperature */}
                <div>
                  <label className="mb-1.5 block text-sm font-medium text-slate-200">
                    Temperature range
                  </label>
                  <div className="flex items-center gap-2">
                    <input
                      type="number"
                      value={form.temperatureFrom}
                      onChange={(e) => setForm((f) => ({ ...f, temperatureFrom: e.target.value }))}
                      placeholder="15"
                      className="w-full rounded-2xl border border-slate-700 bg-slate-950 px-4 py-3 text-sm outline-none transition focus:border-emerald-400"
                    />
                    <span className="shrink-0 text-slate-500">°C –</span>
                    <input
                      type="number"
                      value={form.temperatureTo}
                      onChange={(e) => setForm((f) => ({ ...f, temperatureTo: e.target.value }))}
                      placeholder="30"
                      className="w-full rounded-2xl border border-slate-700 bg-slate-950 px-4 py-3 text-sm outline-none transition focus:border-emerald-400"
                    />
                    <span className="shrink-0 text-slate-500">°C</span>
                  </div>
                </div>

                {/* Light + Location + Difficulty */}
                <div className="grid gap-4 sm:grid-cols-2 md:grid-cols-3">
                  <div>
                    <label className="mb-1.5 block text-sm font-medium text-slate-200">
                      Light requirements
                    </label>
                    <select
                      value={form.lightRequirements}
                      onChange={(e) => setForm((f) => ({ ...f, lightRequirements: e.target.value }))}
                      className="w-full rounded-2xl border border-slate-700 bg-slate-950 px-4 py-3 text-sm outline-none transition focus:border-emerald-400"
                    >
                      {LIGHT_OPTIONS.map((opt) => (
                        <option key={opt} value={opt}>{opt}</option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="mb-1.5 block text-sm font-medium text-slate-200">
                      Location
                    </label>
                    <select
                      value={form.locationType}
                      onChange={(e) => setForm((f) => ({ ...f, locationType: e.target.value }))}
                      className="w-full rounded-2xl border border-slate-700 bg-slate-950 px-4 py-3 text-sm outline-none transition focus:border-emerald-400"
                    >
                      <option value="Both">Indoor &amp; Outdoor</option>
                      <option value="Indoor">Indoor only</option>
                      <option value="Outdoor">Outdoor only</option>
                    </select>
                  </div>
                  <div>
                    <label className="mb-1.5 block text-sm font-medium text-slate-200">
                      Caring difficulty
                    </label>
                    <select
                      value={form.caringDifficulty}
                      onChange={(e) => setForm((f) => ({ ...f, caringDifficulty: e.target.value }))}
                      className="w-full rounded-2xl border border-slate-700 bg-slate-950 px-4 py-3 text-sm outline-none transition focus:border-emerald-400"
                    >
                      <option value="low">Easy — forgiving</option>
                      <option value="high">Demanding — attentive</option>
                    </select>
                  </div>
                </div>

                {/* Water schedule builder */}
                <WaterScheduleBuilder
                  value={form.waterSchedule}
                  onChange={(s) => setForm((f) => ({ ...f, waterSchedule: s }))}
                />
              </div>

              {/* Footer */}
              <div className="flex items-center justify-end gap-3 rounded-b-3xl border-t border-border px-6 py-4">
                <button
                  type="button"
                  onClick={closeModal}
                  className="rounded-2xl border border-slate-700 bg-slate-800 px-5 py-2.5 text-sm font-semibold text-slate-200 transition hover:bg-slate-700"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={saving}
                  className="inline-flex items-center gap-2 rounded-2xl bg-emerald-500 px-5 py-2.5 text-sm font-semibold text-slate-950 transition hover:bg-emerald-400 disabled:cursor-not-allowed disabled:opacity-60"
                >
                  {saving ? (
                    <>
                      <LoaderCircle className="h-4 w-4 animate-spin" />
                      {uploadingImage ? 'Uploading…' : 'Saving…'}
                    </>
                  ) : editingPlant ? (
                    'Save changes'
                  ) : (
                    'Create plant'
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      ) : null}
    </ProtectedShell>
  );
}
