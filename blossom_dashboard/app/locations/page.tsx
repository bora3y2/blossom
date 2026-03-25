'use client';

import { useEffect, useState } from 'react';
import { Plus, Trash2, Pencil, X, Check } from 'lucide-react';

import { ProtectedShell } from '@/components/dashboard/protected-shell';
import { Topbar } from '@/components/dashboard/topbar';
import { useAuth } from '@/components/providers/auth-provider';
import { Panel } from '@/components/ui/panel';
import {
  listCountries,
  createAdminCountry,
  deleteAdminCountry,
  listStates,
  createAdminState,
  updateAdminState,
  deleteAdminState,
} from '@/lib/api';
import type { Country, State } from '@/lib/types';

export default function LocationsPage() {
  const { session } = useAuth();
  const accessToken = session?.access_token ?? null;

  const [countries, setCountries] = useState<Country[]>([]);
  const [selectedCountry, setSelectedCountry] = useState<Country | null>(null);
  const [states, setStates] = useState<State[]>([]);

  const [loadingCountries, setLoadingCountries] = useState(true);
  const [loadingStates, setLoadingStates] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Country form
  const [showCountryForm, setShowCountryForm] = useState(false);
  const [newCountryName, setNewCountryName] = useState('');
  const [savingCountry, setSavingCountry] = useState(false);

  // State form
  const [showStateForm, setShowStateForm] = useState(false);
  const [newStateName, setNewStateName] = useState('');
  const [newStateLat, setNewStateLat] = useState('');
  const [newStateLon, setNewStateLon] = useState('');
  const [savingState, setSavingState] = useState(false);

  // Inline edit state
  const [editingStateId, setEditingStateId] = useState<number | null>(null);
  const [editStateName, setEditStateName] = useState('');
  const [editStateLat, setEditStateLat] = useState('');
  const [editStateLon, setEditStateLon] = useState('');

  useEffect(() => {
    if (!accessToken) return;
    void loadCountries();
  }, [accessToken]);

  async function loadCountries() {
    if (!accessToken) return;
    setLoadingCountries(true);
    setError(null);
    try {
      const data = await listCountries(accessToken);
      setCountries(data);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load countries');
    } finally {
      setLoadingCountries(false);
    }
  }

  async function loadStates(country: Country) {
    if (!accessToken) return;
    setSelectedCountry(country);
    setStates([]);
    setShowStateForm(false);
    setEditingStateId(null);
    setLoadingStates(true);
    try {
      const data = await listStates(accessToken, country.id);
      setStates(data);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load states');
    } finally {
      setLoadingStates(false);
    }
  }

  async function handleAddCountry(e: React.FormEvent) {
    e.preventDefault();
    if (!accessToken || !newCountryName.trim()) return;
    setSavingCountry(true);
    try {
      const created = await createAdminCountry(accessToken, { name: newCountryName.trim() });
      setCountries((prev) => [...prev, created].sort((a, b) => a.name.localeCompare(b.name)));
      setNewCountryName('');
      setShowCountryForm(false);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to create country');
    } finally {
      setSavingCountry(false);
    }
  }

  async function handleDeleteCountry(country: Country) {
    if (!accessToken) return;
    if (!confirm(`Delete "${country.name}" and all its states?`)) return;
    try {
      await deleteAdminCountry(accessToken, country.id);
      setCountries((prev) => prev.filter((c) => c.id !== country.id));
      if (selectedCountry?.id === country.id) {
        setSelectedCountry(null);
        setStates([]);
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to delete country');
    }
  }

  async function handleAddState(e: React.FormEvent) {
    e.preventDefault();
    if (!accessToken || !selectedCountry || !newStateName.trim()) return;
    const lat = parseFloat(newStateLat);
    const lon = parseFloat(newStateLon);
    if (isNaN(lat) || isNaN(lon)) {
      setError('Latitude and longitude must be valid numbers');
      return;
    }
    setSavingState(true);
    try {
      const created = await createAdminState(accessToken, selectedCountry.id, {
        name: newStateName.trim(),
        latitude: lat,
        longitude: lon,
      });
      setStates((prev) => [...prev, created].sort((a, b) => a.name.localeCompare(b.name)));
      setNewStateName('');
      setNewStateLat('');
      setNewStateLon('');
      setShowStateForm(false);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to create state');
    } finally {
      setSavingState(false);
    }
  }

  function startEditState(state: State) {
    setEditingStateId(state.id);
    setEditStateName(state.name);
    setEditStateLat(String(state.latitude));
    setEditStateLon(String(state.longitude));
  }

  async function handleSaveEditState(stateId: number) {
    if (!accessToken) return;
    const lat = parseFloat(editStateLat);
    const lon = parseFloat(editStateLon);
    if (isNaN(lat) || isNaN(lon)) {
      setError('Latitude and longitude must be valid numbers');
      return;
    }
    try {
      const updated = await updateAdminState(accessToken, stateId, {
        name: editStateName.trim(),
        latitude: lat,
        longitude: lon,
      });
      setStates((prev) => prev.map((s) => (s.id === stateId ? updated : s)));
      setEditingStateId(null);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to update state');
    }
  }

  async function handleDeleteState(stateId: number, stateName: string) {
    if (!accessToken) return;
    if (!confirm(`Delete "${stateName}"?`)) return;
    try {
      await deleteAdminState(accessToken, stateId);
      setStates((prev) => prev.filter((s) => s.id !== stateId));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to delete state');
    }
  }

  return (
    <ProtectedShell>
      <div className="flex h-full flex-col gap-6 overflow-y-auto">
        <Topbar title="Locations" subtitle="Manage countries and their states for user location and weather display." />

        {error && (
          <div className="rounded-2xl border border-red-500/20 bg-red-500/10 px-4 py-3 text-sm text-red-400">
            {error}
            <button className="ml-2 underline" onClick={() => setError(null)}>dismiss</button>
          </div>
        )}

        <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
          {/* Countries panel */}
          <Panel className="flex flex-col gap-4 p-5">
            <div className="flex items-center justify-between">
              <h2 className="text-sm font-semibold uppercase tracking-widest text-slate-400">Countries</h2>
              <button
                onClick={() => setShowCountryForm((v) => !v)}
                className="inline-flex items-center gap-1 rounded-xl bg-emerald-500/15 px-3 py-1.5 text-xs font-medium text-emerald-300 hover:bg-emerald-500/25"
              >
                <Plus className="h-3 w-3" /> Add
              </button>
            </div>

            {showCountryForm && (
              <form onSubmit={(e) => void handleAddCountry(e)} className="flex gap-2">
                <input
                  className="flex-1 rounded-xl border border-slate-700 bg-slate-900 px-3 py-2 text-sm text-white placeholder-slate-500 focus:outline-none focus:ring-1 focus:ring-emerald-500"
                  placeholder="Country name"
                  value={newCountryName}
                  onChange={(e) => setNewCountryName(e.target.value)}
                  required
                />
                <button
                  type="submit"
                  disabled={savingCountry}
                  className="rounded-xl bg-emerald-600 px-4 py-2 text-xs font-medium text-white hover:bg-emerald-500 disabled:opacity-50"
                >
                  {savingCountry ? 'Saving…' : 'Save'}
                </button>
                <button
                  type="button"
                  onClick={() => { setShowCountryForm(false); setNewCountryName(''); }}
                  className="rounded-xl border border-slate-700 px-3 py-2 text-slate-400 hover:text-white"
                >
                  <X className="h-3 w-3" />
                </button>
              </form>
            )}

            {loadingCountries ? (
              <p className="text-sm text-slate-500">Loading…</p>
            ) : countries.length === 0 ? (
              <p className="text-sm text-slate-500">No countries yet. Add one above.</p>
            ) : (
              <ul className="space-y-1">
                {countries.map((country) => (
                  <li
                    key={country.id}
                    className={`flex cursor-pointer items-center justify-between rounded-xl px-3 py-2.5 text-sm transition ${
                      selectedCountry?.id === country.id
                        ? 'bg-emerald-500/10 text-white'
                        : 'text-slate-300 hover:bg-slate-800'
                    }`}
                    onClick={() => void loadStates(country)}
                  >
                    <span className="font-medium">{country.name}</span>
                    <button
                      onClick={(e) => { e.stopPropagation(); void handleDeleteCountry(country); }}
                      className="text-slate-500 hover:text-red-400"
                    >
                      <Trash2 className="h-3.5 w-3.5" />
                    </button>
                  </li>
                ))}
              </ul>
            )}
          </Panel>

          {/* States panel */}
          <Panel className="flex flex-col gap-4 p-5">
            <div className="flex items-center justify-between">
              <h2 className="text-sm font-semibold uppercase tracking-widest text-slate-400">
                {selectedCountry ? `States — ${selectedCountry.name}` : 'States'}
              </h2>
              {selectedCountry && (
                <button
                  onClick={() => setShowStateForm((v) => !v)}
                  className="inline-flex items-center gap-1 rounded-xl bg-emerald-500/15 px-3 py-1.5 text-xs font-medium text-emerald-300 hover:bg-emerald-500/25"
                >
                  <Plus className="h-3 w-3" /> Add
                </button>
              )}
            </div>

            {!selectedCountry && (
              <p className="text-sm text-slate-500">Select a country to manage its states.</p>
            )}

            {selectedCountry && showStateForm && (
              <form onSubmit={(e) => void handleAddState(e)} className="grid grid-cols-2 gap-2">
                <input
                  className="col-span-2 rounded-xl border border-slate-700 bg-slate-900 px-3 py-2 text-sm text-white placeholder-slate-500 focus:outline-none focus:ring-1 focus:ring-emerald-500"
                  placeholder="State / city name"
                  value={newStateName}
                  onChange={(e) => setNewStateName(e.target.value)}
                  required
                />
                <input
                  className="rounded-xl border border-slate-700 bg-slate-900 px-3 py-2 text-sm text-white placeholder-slate-500 focus:outline-none focus:ring-1 focus:ring-emerald-500"
                  placeholder="Latitude (e.g. 30.0444)"
                  value={newStateLat}
                  onChange={(e) => setNewStateLat(e.target.value)}
                  required
                />
                <input
                  className="rounded-xl border border-slate-700 bg-slate-900 px-3 py-2 text-sm text-white placeholder-slate-500 focus:outline-none focus:ring-1 focus:ring-emerald-500"
                  placeholder="Longitude (e.g. 31.2357)"
                  value={newStateLon}
                  onChange={(e) => setNewStateLon(e.target.value)}
                  required
                />
                <button
                  type="submit"
                  disabled={savingState}
                  className="rounded-xl bg-emerald-600 px-4 py-2 text-xs font-medium text-white hover:bg-emerald-500 disabled:opacity-50"
                >
                  {savingState ? 'Saving…' : 'Save'}
                </button>
                <button
                  type="button"
                  onClick={() => { setShowStateForm(false); setNewStateName(''); setNewStateLat(''); setNewStateLon(''); }}
                  className="rounded-xl border border-slate-700 px-3 py-2 text-center text-xs text-slate-400 hover:text-white"
                >
                  Cancel
                </button>
              </form>
            )}

            {selectedCountry && loadingStates && (
              <p className="text-sm text-slate-500">Loading…</p>
            )}

            {selectedCountry && !loadingStates && states.length === 0 && !showStateForm && (
              <p className="text-sm text-slate-500">No states yet. Add one above.</p>
            )}

            {selectedCountry && !loadingStates && states.length > 0 && (
              <ul className="space-y-1">
                {states.map((state) =>
                  editingStateId === state.id ? (
                    <li key={state.id} className="grid grid-cols-2 gap-2 rounded-xl bg-slate-800 p-2">
                      <input
                        className="col-span-2 rounded-lg border border-slate-700 bg-slate-900 px-2 py-1.5 text-sm text-white focus:outline-none focus:ring-1 focus:ring-emerald-500"
                        value={editStateName}
                        onChange={(e) => setEditStateName(e.target.value)}
                      />
                      <input
                        className="rounded-lg border border-slate-700 bg-slate-900 px-2 py-1.5 text-sm text-white focus:outline-none focus:ring-1 focus:ring-emerald-500"
                        value={editStateLat}
                        onChange={(e) => setEditStateLat(e.target.value)}
                        placeholder="Latitude"
                      />
                      <input
                        className="rounded-lg border border-slate-700 bg-slate-900 px-2 py-1.5 text-sm text-white focus:outline-none focus:ring-1 focus:ring-emerald-500"
                        value={editStateLon}
                        onChange={(e) => setEditStateLon(e.target.value)}
                        placeholder="Longitude"
                      />
                      <div className="col-span-2 flex gap-2">
                        <button
                          onClick={() => void handleSaveEditState(state.id)}
                          className="flex items-center gap-1 rounded-lg bg-emerald-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-emerald-500"
                        >
                          <Check className="h-3 w-3" /> Save
                        </button>
                        <button
                          onClick={() => setEditingStateId(null)}
                          className="rounded-lg border border-slate-700 px-3 py-1.5 text-xs text-slate-400 hover:text-white"
                        >
                          Cancel
                        </button>
                      </div>
                    </li>
                  ) : (
                    <li
                      key={state.id}
                      className="flex items-center justify-between rounded-xl px-3 py-2.5 text-sm text-slate-300 hover:bg-slate-800"
                    >
                      <div>
                        <span className="font-medium text-white">{state.name}</span>
                        <span className="ml-2 text-xs text-slate-500">
                          {state.latitude}, {state.longitude}
                        </span>
                      </div>
                      <div className="flex gap-2">
                        <button
                          onClick={() => startEditState(state)}
                          className="text-slate-500 hover:text-emerald-400"
                        >
                          <Pencil className="h-3.5 w-3.5" />
                        </button>
                        <button
                          onClick={() => void handleDeleteState(state.id, state.name)}
                          className="text-slate-500 hover:text-red-400"
                        >
                          <Trash2 className="h-3.5 w-3.5" />
                        </button>
                      </div>
                    </li>
                  ),
                )}
              </ul>
            )}
          </Panel>
        </div>
      </div>
    </ProtectedShell>
  );
}
