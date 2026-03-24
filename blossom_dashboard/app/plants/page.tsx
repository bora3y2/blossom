'use client';

import { useEffect, useMemo, useState } from 'react';
import { Leaf, LoaderCircle, Plus, Save, Trash2 } from 'lucide-react';

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

type PlantFormState = {
  commonName: string;
  scientificName: string;
  shortDescription: string;
  imagePath: string;
  waterRequirements: string;
  lightRequirements: string;
  temperature: string;
  petSafe: boolean;
  locationType: string;
  caringDifficulty: string;
  source: 'admin' | 'ai_image_discovery';
  aiConfidence: string;
  reviewedByAdmin: boolean;
  isActive: boolean;
};

function emptyForm(): PlantFormState {
  return {
    commonName: '',
    scientificName: '',
    shortDescription: '',
    imagePath: '',
    waterRequirements: '',
    lightRequirements: '',
    temperature: '',
    petSafe: false,
    locationType: 'Both',
    caringDifficulty: 'low',
    source: 'admin',
    aiConfidence: '',
    reviewedByAdmin: true,
    isActive: true,
  };
}

function toFormState(plant: Plant): PlantFormState {
  return {
    commonName: plant.common_name,
    scientificName: plant.scientific_name ?? '',
    shortDescription: plant.short_description,
    imagePath: plant.image_path ?? '',
    waterRequirements: plant.water_requirements,
    lightRequirements: plant.light_requirements,
    temperature: plant.temperature,
    petSafe: plant.pet_safe,
    locationType: plant.location_type ?? 'Both',
    caringDifficulty: plant.caring_difficulty ?? 'low',
    source: plant.source,
    aiConfidence: plant.ai_confidence == null ? '' : String(plant.ai_confidence),
    reviewedByAdmin: plant.reviewed_by_admin,
    isActive: plant.is_active,
  };
}

function toPayload(form: PlantFormState): PlantMutationPayload {
  return {
    common_name: form.commonName.trim(),
    scientific_name: form.scientificName.trim() || null,
    short_description: form.shortDescription.trim(),
    image_path: form.imagePath.trim() || null,
    water_requirements: form.waterRequirements.trim(),
    light_requirements: form.lightRequirements.trim(),
    temperature: form.temperature.trim(),
    pet_safe: form.petSafe,
    location_type: form.locationType,
    caring_difficulty: form.caringDifficulty,
    source: form.source,
    ai_confidence: form.aiConfidence.trim() === '' ? null : Number(form.aiConfidence),
    reviewed_by_admin: form.reviewedByAdmin,
    is_active: form.isActive,
  };
}

function upsertPlant(plants: Plant[], plant: Plant) {
  const next = plants.some((item) => item.id === plant.id)
    ? plants.map((item) => (item.id === plant.id ? plant : item))
    : [plant, ...plants];
  return next.sort((left, right) => left.common_name.localeCompare(right.common_name));
}

async function uploadPlantImage(file: File): Promise<string> {
  const supabase = getSupabaseBrowserClient();
  if (!supabase) {
    throw new Error('Supabase is not configured. Cannot upload image.');
  }
  const extension = file.name.split('.').pop() ?? 'jpg';
  const fileName = `${crypto.randomUUID()}.${extension}`;
  const { error } = await supabase.storage.from('plant-images').upload(fileName, file, { upsert: false });
  if (error) {
    throw new Error(`Image upload failed: ${error.message}`);
  }
  const { data } = supabase.storage.from('plant-images').getPublicUrl(fileName);
  return data.publicUrl;
}

export default function PlantsPage() {
  const { session } = useAuth();
  const accessToken = session?.access_token ?? null;
  const [plants, setPlants] = useState<Plant[]>([]);
  const [selectedPlantId, setSelectedPlantId] = useState<string | null>(null);
  const [form, setForm] = useState<PlantFormState>(emptyForm());
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [imagePreviewUrl, setImagePreviewUrl] = useState<string | null>(null);
  const [uploadingImage, setUploadingImage] = useState(false);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [archiving, setArchiving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [query, setQuery] = useState('');
  const [showInactive, setShowInactive] = useState(true);

  useEffect(() => {
    if (!accessToken) {
      return;
    }

    let active = true;
    setLoading(true);
    setError(null);

    listAdminPlants(accessToken)
      .then((payload) => {
        if (!active) {
          return;
        }
        setPlants(payload);
      })
      .catch((nextError) => {
        if (!active) {
          return;
        }
        setError(nextError instanceof Error ? nextError.message : 'Unable to load plants.');
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

  const filteredPlants = useMemo(() => {
    const needle = query.trim().toLowerCase();
    return plants.filter((plant) => {
      if (!showInactive && !plant.is_active) {
        return false;
      }
      if (!needle) {
        return true;
      }
      return (
        plant.common_name.toLowerCase().includes(needle) ||
        (plant.scientific_name ?? '').toLowerCase().includes(needle) ||
        plant.water_requirements.toLowerCase().includes(needle) ||
        plant.light_requirements.toLowerCase().includes(needle)
      );
    });
  }, [plants, query, showInactive]);

  const selectedPlant = useMemo(
    () => plants.find((plant) => plant.id === selectedPlantId) ?? null,
    [plants, selectedPlantId],
  );

  const activeCount = useMemo(
    () => plants.filter((plant) => plant.is_active).length,
    [plants],
  );

  const aiDiscoveredCount = useMemo(
    () => plants.filter((plant) => plant.source === 'ai_image_discovery').length,
    [plants],
  );

  const handleSelectPlant = (plant: Plant) => {
    setSelectedPlantId(plant.id);
    setForm(toFormState(plant));
    setImageFile(null);
    setImagePreviewUrl(null);
    setError(null);
    setSuccessMessage(null);
  };

  const handleCreateNew = () => {
    setSelectedPlantId(null);
    setForm(emptyForm());
    setImageFile(null);
    setImagePreviewUrl(null);
    setError(null);
    setSuccessMessage(null);
  };

  const handleSave = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!accessToken) {
      return;
    }

    setSaving(true);
    setError(null);
    setSuccessMessage(null);

    try {
      let currentImagePath = form.imagePath;

      if (imageFile) {
        setUploadingImage(true);
        currentImagePath = await uploadPlantImage(imageFile);
        setUploadingImage(false);
      }

      const formWithImage = { ...form, imagePath: currentImagePath };
      const payload = toPayload(formWithImage);
      if (!payload.common_name || !payload.water_requirements || !payload.light_requirements || !payload.temperature) {
        throw new Error('Please fill in the required plant fields before saving.');
      }

      const savedPlant = selectedPlantId
        ? await updateAdminPlant(accessToken, selectedPlantId, payload)
        : await createAdminPlant(accessToken, payload);

      setPlants((current) => upsertPlant(current, savedPlant));
      setSelectedPlantId(savedPlant.id);
      setForm(toFormState(savedPlant));
      setImageFile(null);
      setImagePreviewUrl(null);
      setSuccessMessage(selectedPlantId ? 'Plant updated successfully.' : 'Plant created successfully.');
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : 'Unable to save plant.');
    } finally {
      setSaving(false);
      setUploadingImage(false);
    }
  };

  const handleArchive = async () => {
    if (!accessToken || !selectedPlant) {
      return;
    }

    setArchiving(true);
    setError(null);
    setSuccessMessage(null);

    try {
      const archivedPlant = await archiveAdminPlant(accessToken, selectedPlant.id);
      setPlants((current) => upsertPlant(current, archivedPlant));
      setSelectedPlantId(archivedPlant.id);
      setForm(toFormState(archivedPlant));
      setSuccessMessage('Plant archived successfully.');
    } catch (archiveError) {
      setError(archiveError instanceof Error ? archiveError.message : 'Unable to archive plant.');
    } finally {
      setArchiving(false);
    }
  };

  return (
    <ProtectedShell>
      <div className="space-y-4">
        <Panel className="p-6 sm:p-8">
          <Topbar
            title="Plant catalog"
            subtitle="Manage the canonical plant library used by the Blossom app. Create trusted admin plants, review AI-discovered entries, and archive outdated records without touching the database manually."
          />
        </Panel>

        <div className="grid gap-4 md:grid-cols-3">
          <Panel className="p-5">
            <p className="text-sm text-slate-400">Total catalog entries</p>
            <p className="mt-3 text-3xl font-semibold text-white">{plants.length}</p>
            <p className="mt-2 text-sm text-slate-500">Includes active and archived plants returned by the admin API.</p>
          </Panel>
          <Panel className="p-5">
            <p className="text-sm text-slate-400">Active plants</p>
            <p className="mt-3 text-3xl font-semibold text-white">{activeCount}</p>
            <p className="mt-2 text-sm text-slate-500">These are available for discovery and garden add flows.</p>
          </Panel>
          <Panel className="p-5">
            <p className="text-sm text-slate-400">AI-discovered plants</p>
            <p className="mt-3 text-3xl font-semibold text-white">{aiDiscoveredCount}</p>
            <p className="mt-2 text-sm text-slate-500">Review and normalize these entries as needed from the same control surface.</p>
          </Panel>
        </div>

        {error ? (
          <Panel className="border-rose-400/20 bg-rose-500/10 p-5 text-sm text-rose-100">{error}</Panel>
        ) : null}
        {successMessage ? (
          <Panel className="border-emerald-400/20 bg-emerald-500/10 p-5 text-sm text-emerald-100">
            {successMessage}
          </Panel>
        ) : null}

        <div className="grid gap-4 xl:grid-cols-[1fr_1.25fr]">
          <Panel className="p-6 sm:p-8">
            <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
              <div>
                <p className="text-xs uppercase tracking-[0.28em] text-emerald-300">Catalog browser</p>
                <h3 className="mt-3 text-2xl font-semibold text-white">Plants</h3>
              </div>
              <button
                type="button"
                onClick={handleCreateNew}
                className="inline-flex items-center justify-center gap-2 rounded-2xl bg-emerald-500 px-4 py-3 font-semibold text-slate-950 transition hover:bg-emerald-400"
              >
                <Plus className="h-4 w-4" />
                Create plant
              </button>
            </div>

            <div className="mt-6 space-y-4">
              <input
                value={query}
                onChange={(event) => setQuery(event.target.value)}
                placeholder="Search common name, scientific name, water or light..."
                className="w-full rounded-2xl border border-slate-700 bg-slate-950 px-4 py-3 outline-none transition focus:border-emerald-400"
              />
              <label className="flex items-center gap-3 text-sm text-slate-300">
                <input
                  type="checkbox"
                  checked={showInactive}
                  onChange={(event) => setShowInactive(event.target.checked)}
                  className="h-4 w-4 rounded border-slate-600 bg-slate-950 text-emerald-500"
                />
                Show archived plants
              </label>
            </div>

            <div className="mt-6 space-y-3">
              {loading ? (
                <div className="flex items-center gap-3 rounded-2xl border border-slate-800 bg-slate-950/70 p-4 text-sm text-slate-300">
                  <LoaderCircle className="h-4 w-4 animate-spin" />
                  Loading plant catalog...
                </div>
              ) : null}

              {!loading && filteredPlants.length === 0 ? (
                <div className="rounded-2xl border border-slate-800 bg-slate-950/70 p-6 text-sm text-slate-400">
                  No plants match your current filter.
                </div>
              ) : null}

              {filteredPlants.map((plant) => {
                const selected = plant.id === selectedPlantId;
                return (
                  <button
                    key={plant.id}
                    type="button"
                    onClick={() => handleSelectPlant(plant)}
                    className={`w-full rounded-2xl border p-4 text-left transition ${
                      selected
                        ? 'border-emerald-400/30 bg-emerald-500/10'
                        : 'border-slate-800 bg-slate-950/60 hover:border-slate-700 hover:bg-slate-950'
                    }`}
                  >
                    <div className="flex items-start justify-between gap-3">
                      <div>
                        <p className="font-semibold text-white">{plant.common_name}</p>
                        <p className="mt-1 text-sm text-slate-400">{plant.scientific_name || 'No scientific name'}</p>
                      </div>
                      <div className="flex flex-wrap justify-end gap-2">
                        <StatusBadge
                          label={plant.is_active ? 'Active' : 'Archived'}
                          tone={plant.is_active ? 'success' : 'warning'}
                        />
                        <StatusBadge
                          label={plant.source === 'admin' ? 'Admin' : 'AI'}
                          tone={plant.source === 'admin' ? 'neutral' : 'warning'}
                        />
                      </div>
                    </div>
                    <div className="mt-4 flex flex-wrap gap-2 text-xs text-slate-400">
                      <span className="rounded-full border border-white/10 px-3 py-1">Water: {plant.water_requirements}</span>
                      <span className="rounded-full border border-white/10 px-3 py-1">Light: {plant.light_requirements}</span>
                      <span className="rounded-full border border-white/10 px-3 py-1">Temp: {plant.temperature}</span>
                    </div>
                  </button>
                );
              })}
            </div>
          </Panel>

          <Panel className="p-6 sm:p-8">
            <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
              <div>
                <p className="text-xs uppercase tracking-[0.28em] text-sky-300">
                  {selectedPlant ? 'Edit plant' : 'Create plant'}
                </p>
                <h3 className="mt-3 text-2xl font-semibold text-white">
                  {selectedPlant ? selectedPlant.common_name : 'New catalog entry'}
                </h3>
              </div>
              {selectedPlant ? (
                <button
                  type="button"
                  onClick={() => void handleArchive()}
                  disabled={archiving || !selectedPlant.is_active}
                  className="inline-flex items-center justify-center gap-2 rounded-2xl border border-rose-400/30 bg-rose-500/10 px-4 py-3 font-semibold text-rose-100 transition hover:bg-rose-500/20 disabled:cursor-not-allowed disabled:opacity-60"
                >
                  <Trash2 className="h-4 w-4" />
                  {archiving ? 'Archiving...' : selectedPlant.is_active ? 'Archive plant' : 'Already archived'}
                </button>
              ) : null}
            </div>

            <form className="mt-6 space-y-6" onSubmit={handleSave}>
              <div className="grid gap-6 md:grid-cols-2">
                <label className="block">
                  <span className="mb-2 block text-sm font-medium text-slate-200">Common name</span>
                  <input
                    value={form.commonName}
                    onChange={(event) => setForm((current) => ({ ...current, commonName: event.target.value }))}
                    className="w-full rounded-2xl border border-slate-700 bg-slate-950 px-4 py-3 outline-none transition focus:border-emerald-400"
                    required
                  />
                </label>
                <label className="block">
                  <span className="mb-2 block text-sm font-medium text-slate-200">Scientific name</span>
                  <input
                    value={form.scientificName}
                    onChange={(event) => setForm((current) => ({ ...current, scientificName: event.target.value }))}
                    className="w-full rounded-2xl border border-slate-700 bg-slate-950 px-4 py-3 outline-none transition focus:border-emerald-400"
                  />
                </label>
              </div>

              <label className="block">
                <span className="mb-2 block text-sm font-medium text-slate-200">Short description</span>
                <textarea
                  rows={5}
                  value={form.shortDescription}
                  onChange={(event) => setForm((current) => ({ ...current, shortDescription: event.target.value }))}
                  className="w-full rounded-3xl border border-slate-700 bg-slate-950 px-4 py-4 outline-none transition focus:border-emerald-400"
                />
              </label>

              <div className="grid gap-6 md:grid-cols-2">
                <div className="block">
                  <span className="mb-2 block text-sm font-medium text-slate-200">Plant image</span>
                  {(imagePreviewUrl ?? form.imagePath) ? (
                    <div className="mb-3">
                      <img
                        src={imagePreviewUrl ?? form.imagePath ?? ''}
                        alt="Plant preview"
                        className="h-32 w-full rounded-2xl object-cover"
                      />
                    </div>
                  ) : null}
                  <label className="flex cursor-pointer items-center justify-center gap-2 rounded-2xl border border-dashed border-slate-600 bg-slate-950 px-4 py-4 text-sm text-slate-300 transition hover:border-emerald-400 hover:text-emerald-300">
                    <input
                      type="file"
                      accept="image/*"
                      className="sr-only"
                      onChange={(event) => {
                        const file = event.target.files?.[0] ?? null;
                        setImageFile(file);
                        setImagePreviewUrl(file ? URL.createObjectURL(file) : null);
                      }}
                    />
                    {uploadingImage ? <LoaderCircle className="h-4 w-4 animate-spin" /> : null}
                    {imageFile ? imageFile.name : 'Choose image…'}
                  </label>
                  {form.imagePath && !imageFile ? (
                    <p className="mt-1 truncate text-xs text-slate-500">{form.imagePath}</p>
                  ) : null}
                </div>
                <label className="block">
                  <span className="mb-2 block text-sm font-medium text-slate-200">Temperature</span>
                  <input
                    value={form.temperature}
                    onChange={(event) => setForm((current) => ({ ...current, temperature: event.target.value }))}
                    className="w-full rounded-2xl border border-slate-700 bg-slate-950 px-4 py-3 outline-none transition focus:border-emerald-400"
                    required
                  />
                </label>
              </div>

              <div className="grid gap-6 md:grid-cols-2">
                <label className="block">
                  <span className="mb-2 block text-sm font-medium text-slate-200">Water requirements</span>
                  <input
                    value={form.waterRequirements}
                    onChange={(event) => setForm((current) => ({ ...current, waterRequirements: event.target.value }))}
                    className="w-full rounded-2xl border border-slate-700 bg-slate-950 px-4 py-3 outline-none transition focus:border-emerald-400"
                    required
                  />
                </label>
                <label className="block">
                  <span className="mb-2 block text-sm font-medium text-slate-200">Light requirements</span>
                  <input
                    value={form.lightRequirements}
                    onChange={(event) => setForm((current) => ({ ...current, lightRequirements: event.target.value }))}
                    className="w-full rounded-2xl border border-slate-700 bg-slate-950 px-4 py-3 outline-none transition focus:border-emerald-400"
                    required
                  />
                </label>
              </div>

              <div className="grid gap-6 md:grid-cols-2">
                <label className="block">
                  <span className="mb-2 block text-sm font-medium text-slate-200">Source</span>
                  <select
                    value={form.source}
                    onChange={(event) =>
                      setForm((current) => ({
                        ...current,
                        source: event.target.value as 'admin' | 'ai_image_discovery',
                      }))
                    }
                    className="w-full rounded-2xl border border-slate-700 bg-slate-950 px-4 py-3 outline-none transition focus:border-emerald-400"
                  >
                    <option value="admin">admin</option>
                    <option value="ai_image_discovery">ai_image_discovery</option>
                  </select>
                </label>
                <label className="block">
                  <span className="mb-2 block text-sm font-medium text-slate-200">AI confidence</span>
                  <input
                    type="number"
                    min="0"
                    max="1"
                    step="0.01"
                    value={form.aiConfidence}
                    onChange={(event) => setForm((current) => ({ ...current, aiConfidence: event.target.value }))}
                    className="w-full rounded-2xl border border-slate-700 bg-slate-950 px-4 py-3 outline-none transition focus:border-emerald-400"
                  />
                </label>
              </div>

              <div className="grid gap-6 md:grid-cols-2">
                <label className="block">
                  <span className="mb-2 block text-sm font-medium text-slate-200">Location type</span>
                  <select
                    value={form.locationType}
                    onChange={(event) => setForm((current) => ({ ...current, locationType: event.target.value }))}
                    className="w-full rounded-2xl border border-slate-700 bg-slate-950 px-4 py-3 outline-none transition focus:border-emerald-400"
                  >
                    <option value="Both">Both (Indoor &amp; Outdoor)</option>
                    <option value="Indoor">Indoor</option>
                    <option value="Outdoor">Outdoor</option>
                  </select>
                </label>
                <label className="block">
                  <span className="mb-2 block text-sm font-medium text-slate-200">Caring difficulty</span>
                  <select
                    value={form.caringDifficulty}
                    onChange={(event) => setForm((current) => ({ ...current, caringDifficulty: event.target.value }))}
                    className="w-full rounded-2xl border border-slate-700 bg-slate-950 px-4 py-3 outline-none transition focus:border-emerald-400"
                  >
                    <option value="low">Low — forgiving for forgetful owners</option>
                    <option value="high">High — needs daily attention</option>
                  </select>
                </label>
              </div>

              <div className="grid gap-4 md:grid-cols-3">
                <label className="flex items-center justify-between gap-4 rounded-2xl border border-slate-800 bg-slate-950/80 px-4 py-4">
                  <span className="text-sm font-medium text-white">Pet safe</span>
                  <input
                    type="checkbox"
                    checked={form.petSafe}
                    onChange={(event) => setForm((current) => ({ ...current, petSafe: event.target.checked }))}
                    className="h-5 w-5 rounded border-slate-600 bg-slate-950 text-emerald-500"
                  />
                </label>
                <label className="flex items-center justify-between gap-4 rounded-2xl border border-slate-800 bg-slate-950/80 px-4 py-4">
                  <span className="text-sm font-medium text-white">Reviewed by admin</span>
                  <input
                    type="checkbox"
                    checked={form.reviewedByAdmin}
                    onChange={(event) => setForm((current) => ({ ...current, reviewedByAdmin: event.target.checked }))}
                    className="h-5 w-5 rounded border-slate-600 bg-slate-950 text-emerald-500"
                  />
                </label>
                <label className="flex items-center justify-between gap-4 rounded-2xl border border-slate-800 bg-slate-950/80 px-4 py-4">
                  <span className="text-sm font-medium text-white">Active</span>
                  <input
                    type="checkbox"
                    checked={form.isActive}
                    onChange={(event) => setForm((current) => ({ ...current, isActive: event.target.checked }))}
                    className="h-5 w-5 rounded border-slate-600 bg-slate-950 text-emerald-500"
                  />
                </label>
              </div>

              <div className="flex flex-col gap-3 sm:flex-row">
                <button
                  type="submit"
                  disabled={saving}
                  className="inline-flex items-center justify-center gap-2 rounded-2xl bg-emerald-500 px-5 py-3 font-semibold text-slate-950 transition hover:bg-emerald-400 disabled:cursor-not-allowed disabled:opacity-60"
                >
                  <Save className="h-4 w-4" />
                  {uploadingImage ? 'Uploading image…' : saving ? 'Saving…' : selectedPlant ? 'Save changes' : 'Create plant'}
                </button>
                <button
                  type="button"
                  onClick={selectedPlant ? () => setForm(toFormState(selectedPlant)) : handleCreateNew}
                  className="inline-flex items-center justify-center gap-2 rounded-2xl border border-slate-700 bg-slate-950 px-5 py-3 font-semibold text-slate-200 transition hover:border-slate-600 hover:bg-slate-900"
                >
                  <Leaf className="h-4 w-4" />
                  {selectedPlant ? 'Reset changes' : 'Clear form'}
                </button>
              </div>
            </form>
          </Panel>
        </div>
      </div>
    </ProtectedShell>
  );
}
