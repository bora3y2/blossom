import { apiBaseUrl } from '@/lib/config';
import type {
  AiConnectionTestResult,
  AiSettings,
  CommunityComment,
  CommunityFeed,
  CommunityPost,
  Country,
  Plant,
  PlantMutationPayload,
  Profile,
  State,
} from '@/lib/types';

export class ApiError extends Error {
  readonly status: number;

  constructor(message: string, status: number) {
    super(message);
    this.status = status;
  }
}

async function parseResponse<T>(response: Response): Promise<T> {
  if (response.ok) {
    return (await response.json()) as T;
  }

  let message = 'Request failed';
  try {
    const payload = (await response.json()) as { detail?: string };
    if (payload.detail) {
      message = payload.detail;
    }
  } catch {
    const text = await response.text();
    if (text) {
      message = text;
    }
  }

  throw new ApiError(message, response.status);
}

async function authenticatedFetch<T>(path: string, accessToken: string, init?: RequestInit) {
  const response = await fetch(`${apiBaseUrl}${path}`, {
    ...init,
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${accessToken}`,
      ...(init?.headers ?? {}),
    },
    cache: 'no-store',
  });

  return parseResponse<T>(response);
}

export function getMyProfile(accessToken: string) {
  return authenticatedFetch<Profile>('/profiles/me', accessToken, {
    method: 'GET',
  });
}

export function getAiSettings(accessToken: string) {
  return authenticatedFetch<AiSettings>('/admin/ai-settings', accessToken, {
    method: 'GET',
  });
}

export function updateAiSettings(
  accessToken: string,
  payload: Partial<{
    model: string;
    system_prompt: string;
    temperature: number;
    max_tokens: number;
    is_enabled: boolean;
    api_key: string;
  }>,
) {
  return authenticatedFetch<AiSettings>('/admin/ai-settings', accessToken, {
    method: 'PATCH',
    body: JSON.stringify(payload),
  });
}

export function testAiConnection(accessToken: string) {
  return authenticatedFetch<AiConnectionTestResult>(
    '/admin/ai-settings/test-connection',
    accessToken,
    {
      method: 'POST',
      body: JSON.stringify({}),
    },
  );
}

export function listAdminPlants(accessToken: string) {
  return authenticatedFetch<Plant[]>('/admin/plants', accessToken, {
    method: 'GET',
  });
}

export function createAdminPlant(accessToken: string, payload: PlantMutationPayload) {
  return authenticatedFetch<Plant>('/admin/plants', accessToken, {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

export function updateAdminPlant(
  accessToken: string,
  plantId: string,
  payload: PlantMutationPayload,
) {
  return authenticatedFetch<Plant>(`/admin/plants/${plantId}`, accessToken, {
    method: 'PATCH',
    body: JSON.stringify(payload),
  });
}

export function archiveAdminPlant(accessToken: string, plantId: string) {
  return authenticatedFetch<Plant>(`/admin/plants/${plantId}`, accessToken, {
    method: 'DELETE',
  });
}

export function getAdminCommunityFeed(accessToken: string) {
  return authenticatedFetch<CommunityFeed>('/admin/community/posts', accessToken, {
    method: 'GET',
  });
}

export function setAdminPostVisibility(
  accessToken: string,
  postId: string,
  hiddenByAdmin: boolean,
) {
  return authenticatedFetch<CommunityPost>(
    `/admin/community/posts/${postId}/visibility`,
    accessToken,
    {
      method: 'PATCH',
      body: JSON.stringify({ hidden_by_admin: hiddenByAdmin }),
    },
  );
}

export function setAdminCommentVisibility(
  accessToken: string,
  commentId: string,
  hiddenByAdmin: boolean,
) {
  return authenticatedFetch<CommunityComment>(
    `/admin/community/comments/${commentId}/visibility`,
    accessToken,
    {
      method: 'PATCH',
      body: JSON.stringify({ hidden_by_admin: hiddenByAdmin }),
    },
  );
}

export function deleteAdminPost(accessToken: string, postId: string) {
  return authenticatedFetch<{ success: boolean; message: string }>(
    `/admin/community/posts/${postId}`,
    accessToken,
    {
      method: 'DELETE',
    },
  );
}

export function deleteAdminComment(accessToken: string, commentId: string) {
  return authenticatedFetch<{ success: boolean; message: string }>(
    `/admin/community/comments/${commentId}`,
    accessToken,
    {
      method: 'DELETE',
    },
  );
}

export function getAdminReports(accessToken: string, status?: string) {
  const url = status ? `/admin/community/reports?status=${status}` : '/admin/community/reports';
  return authenticatedFetch<{ items: import('@/lib/types').Report[]; meta: { count: number } }>(
    url,
    accessToken,
    {
      method: 'GET',
    },
  );
}

export function updateAdminReportStatus(
  accessToken: string,
  reportId: string,
  status: 'reviewed' | 'dismissed',
) {
  return authenticatedFetch<import('@/lib/types').Report>(
    `/admin/community/reports/${reportId}`,
    accessToken,
    {
      method: 'PATCH',
      body: JSON.stringify({ status }),
    },
  );
}

export function getAdminAuditLog(accessToken: string) {
  return authenticatedFetch<{ items: import('@/lib/types').AuditLogEntry[]; meta: { count: number } }>(
    '/admin/audit-log',
    accessToken,
    {
      method: 'GET',
    },
  );
}

// ── Countries & States ─────────────────────────────────────────────────

export function listCountries(accessToken: string) {
  return authenticatedFetch<Country[]>('/location/countries', accessToken, { method: 'GET' });
}

export function createAdminCountry(accessToken: string, payload: { name: string }) {
  return authenticatedFetch<Country>('/admin/countries', accessToken, {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

export function deleteAdminCountry(accessToken: string, countryId: number) {
  return authenticatedFetch<{ success: boolean; message: string }>(
    `/admin/countries/${countryId}`,
    accessToken,
    { method: 'DELETE' },
  );
}

export function listStates(accessToken: string, countryId: number) {
  return authenticatedFetch<State[]>(`/location/countries/${countryId}/states`, accessToken, {
    method: 'GET',
  });
}

export function createAdminState(
  accessToken: string,
  countryId: number,
  payload: { name: string; latitude: number; longitude: number },
) {
  return authenticatedFetch<State>(`/admin/countries/${countryId}/states`, accessToken, {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

export function updateAdminState(
  accessToken: string,
  stateId: number,
  payload: Partial<{ name: string; latitude: number; longitude: number }>,
) {
  return authenticatedFetch<State>(`/admin/states/${stateId}`, accessToken, {
    method: 'PATCH',
    body: JSON.stringify(payload),
  });
}

export function deleteAdminState(accessToken: string, stateId: number) {
  return authenticatedFetch<{ success: boolean; message: string }>(
    `/admin/states/${stateId}`,
    accessToken,
    { method: 'DELETE' },
  );
}
