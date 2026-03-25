'use client';

import { useEffect, useMemo, useState } from 'react';
import {
  Check,
  Eye,
  EyeOff,
  ImageIcon,
  LoaderCircle,
  MessageSquare,
  Trash2,
  X,
} from 'lucide-react';

import { ProtectedShell } from '@/components/dashboard/protected-shell';
import { Topbar } from '@/components/dashboard/topbar';
import { Panel } from '@/components/ui/panel';
import { StatusBadge } from '@/components/ui/status-badge';
import { useAuth } from '@/components/providers/auth-provider';
import {
  deleteAdminComment,
  deleteAdminPost,
  getAdminCommunityFeed,
  getAdminReports,
  setAdminCommentVisibility,
  setAdminPostVisibility,
  updateAdminReportStatus,
} from '@/lib/api';
import type { CommunityComment, CommunityPost, Report } from '@/lib/types';

// ── Helpers ───────────────────────────────────────────────────────────────────

function replacePost(posts: CommunityPost[], updated: CommunityPost): CommunityPost[] {
  return posts.map((p) => (p.id === updated.id ? updated : p));
}

function replaceComment(posts: CommunityPost[], updated: CommunityComment): CommunityPost[] {
  return posts.map((post) => {
    if (post.id !== updated.post_id) return post;
    const comments = post.comments.map((c) => (c.id === updated.id ? updated : c));
    return { ...post, comments, comments_count: comments.filter((c) => !c.hidden_by_admin).length };
  });
}

function removePost(posts: CommunityPost[], id: string): CommunityPost[] {
  return posts.filter((p) => p.id !== id);
}

function removeComment(posts: CommunityPost[], id: string): CommunityPost[] {
  return posts.map((p) => ({ ...p, comments: p.comments.filter((c) => c.id !== id) }));
}

function timeAgo(dateString: string): string {
  const diff = Math.floor((Date.now() - new Date(dateString).getTime()) / 1000);
  if (diff < 60) return `${diff}s ago`;
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
  if (diff < 604800) return `${Math.floor(diff / 86400)}d ago`;
  return new Date(dateString).toLocaleDateString();
}

// Safely resolve image URLs — hides broken images gracefully
function PostImage({ src, className }: { src: string; className?: string }) {
  const [failed, setFailed] = useState(false);
  if (failed) return null;
  return (
    <img
      src={src}
      alt=""
      className={className}
      onError={() => setFailed(true)}
    />
  );
}

function Avatar({ src, name }: { src: string | null; name: string }) {
  const [failed, setFailed] = useState(false);
  const initials = (name || '?').slice(0, 1).toUpperCase();
  if (!src || failed) {
    return (
      <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-slate-700 text-xs font-semibold text-white">
        {initials}
      </div>
    );
  }
  return (
    <img
      src={src}
      alt=""
      className="h-7 w-7 shrink-0 rounded-full object-cover"
      onError={() => setFailed(true)}
    />
  );
}

// ── Page ──────────────────────────────────────────────────────────────────────

export default function CommunityModerationPage() {
  const { session } = useAuth();
  const accessToken = session?.access_token ?? null;
  const [activeTab, setActiveTab] = useState<'feed' | 'reports'>('feed');

  const [posts, setPosts] = useState<CommunityPost[]>([]);
  const [reports, setReports] = useState<Report[]>([]);
  const [loading, setLoading] = useState(true);
  const [pageError, setPageError] = useState<string | null>(null);
  const [busy, setBusy] = useState<string | null>(null);

  // filters
  const [query, setQuery] = useState('');
  const [showHiddenOnly, setShowHiddenOnly] = useState(false);

  // detail modal
  const [viewingPost, setViewingPost] = useState<CommunityPost | null>(null);

  // ── Load ────────────────────────────────────────────────────────────────────
  useEffect(() => {
    if (!accessToken) return;
    let active = true;
    setLoading(true);
    setPageError(null);
    const req =
      activeTab === 'feed'
        ? getAdminCommunityFeed(accessToken).then((d) => { if (active) setPosts(d.items); })
        : getAdminReports(accessToken, 'pending').then((d) => { if (active) setReports(d.items); });
    req
      .catch((err) => { if (active) setPageError(err instanceof Error ? err.message : 'Unable to load data.'); })
      .finally(() => { if (active) setLoading(false); });
    return () => { active = false; };
  }, [accessToken, activeTab]);

  // keep modal in sync with updated post state
  useEffect(() => {
    if (viewingPost) {
      const fresh = posts.find((p) => p.id === viewingPost.id);
      if (fresh) setViewingPost(fresh);
    }
  }, [posts]);

  // ── Derived ─────────────────────────────────────────────────────────────────
  const filteredPosts = useMemo(() => {
    const needle = query.trim().toLowerCase();
    return posts.filter((p) => {
      if (showHiddenOnly && !p.hidden_by_admin && !p.comments.some((c) => c.hidden_by_admin))
        return false;
      if (!needle) return true;
      return (
        p.content.toLowerCase().includes(needle) ||
        (p.author.display_name ?? '').toLowerCase().includes(needle)
      );
    });
  }, [posts, query, showHiddenOnly]);

  const hiddenPostCount = useMemo(() => posts.filter((p) => p.hidden_by_admin).length, [posts]);
  const hiddenCommentCount = useMemo(
    () => posts.flatMap((p) => p.comments).filter((c) => c.hidden_by_admin).length,
    [posts],
  );

  // ── Actions ──────────────────────────────────────────────────────────────────
  async function togglePost(post: CommunityPost) {
    if (!accessToken) return;
    setBusy(`toggle-post-${post.id}`);
    try {
      const updated = await setAdminPostVisibility(accessToken, post.id, !post.hidden_by_admin);
      setPosts((curr) => replacePost(curr, updated));
    } catch { /* silent */ }
    finally { setBusy(null); }
  }

  async function deletePost(post: CommunityPost) {
    if (!accessToken || !window.confirm('Delete this post permanently?')) return;
    setBusy(`delete-post-${post.id}`);
    try {
      await deleteAdminPost(accessToken, post.id);
      setPosts((curr) => removePost(curr, post.id));
      if (viewingPost?.id === post.id) setViewingPost(null);
    } catch { /* silent */ }
    finally { setBusy(null); }
  }

  async function toggleComment(comment: CommunityComment) {
    if (!accessToken) return;
    setBusy(`toggle-comment-${comment.id}`);
    try {
      const updated = await setAdminCommentVisibility(accessToken, comment.id, !comment.hidden_by_admin);
      setPosts((curr) => replaceComment(curr, updated));
    } catch { /* silent */ }
    finally { setBusy(null); }
  }

  async function deleteComment(comment: CommunityComment) {
    if (!accessToken || !window.confirm('Delete this comment permanently?')) return;
    setBusy(`delete-comment-${comment.id}`);
    try {
      await deleteAdminComment(accessToken, comment.id);
      setPosts((curr) => removeComment(curr, comment.id));
    } catch { /* silent */ }
    finally { setBusy(null); }
  }

  async function resolveReport(reportId: string, status: 'reviewed' | 'dismissed') {
    if (!accessToken) return;
    setBusy(`report-${reportId}`);
    try {
      await updateAdminReportStatus(accessToken, reportId, status);
      setReports((curr) => curr.filter((r) => r.id !== reportId));
    } catch { /* silent */ }
    finally { setBusy(null); }
  }

  // ── Render ───────────────────────────────────────────────────────────────────
  return (
    <ProtectedShell>
      <div className="space-y-6">
        {/* Header */}
        <Panel className="p-6 sm:p-8">
          <Topbar
            title="Community moderation"
            subtitle="Review posts, comments, and user reports from a single surface."
          />
          <div className="mt-6 flex gap-1 border-b border-white/10">
            {(['feed', 'reports'] as const).map((tab) => (
              <button
                key={tab}
                type="button"
                onClick={() => setActiveTab(tab)}
                className={`px-5 py-2.5 text-sm font-medium capitalize transition ${
                  activeTab === tab
                    ? 'border-b-2 border-emerald-400 text-emerald-400'
                    : 'text-slate-400 hover:text-slate-300'
                }`}
              >
                {tab === 'feed' ? 'Content Feed' : 'Pending Reports'}
              </button>
            ))}
          </div>
        </Panel>

        {/* Stats (feed only) */}
        {activeTab === 'feed' && (
          <div className="grid gap-4 sm:grid-cols-3">
            <Panel className="p-5">
              <p className="text-sm text-slate-400">Total posts</p>
              <p className="mt-2 text-3xl font-semibold text-white">{posts.length}</p>
            </Panel>
            <Panel className="p-5">
              <p className="text-sm text-slate-400">Hidden posts</p>
              <p className="mt-2 text-3xl font-semibold text-rose-400">{hiddenPostCount}</p>
            </Panel>
            <Panel className="p-5">
              <p className="text-sm text-slate-400">Hidden comments</p>
              <p className="mt-2 text-3xl font-semibold text-amber-400">{hiddenCommentCount}</p>
            </Panel>
          </div>
        )}

        {pageError ? (
          <Panel className="border-rose-400/20 bg-rose-500/10 p-5 text-sm text-rose-100">
            {pageError}
          </Panel>
        ) : null}

        {/* Table */}
        <Panel className="overflow-hidden p-0">
          {/* Toolbar */}
          <div className="flex flex-wrap items-center gap-3 border-b border-border px-5 py-4">
            {activeTab === 'feed' ? (
              <>
                <input
                  value={query}
                  onChange={(e) => setQuery(e.target.value)}
                  placeholder="Search posts…"
                  className="min-w-0 flex-1 rounded-xl border border-slate-700 bg-slate-950 px-4 py-2.5 text-sm outline-none transition focus:border-emerald-400"
                />
                <label className="flex cursor-pointer items-center gap-2 text-sm text-slate-300">
                  <input
                    type="checkbox"
                    checked={showHiddenOnly}
                    onChange={(e) => setShowHiddenOnly(e.target.checked)}
                    className="h-4 w-4 rounded border-slate-600 bg-slate-950 text-emerald-500"
                  />
                  Hidden only
                </label>
              </>
            ) : (
              <p className="text-sm font-medium text-slate-300">
                {reports.length} pending report{reports.length !== 1 ? 's' : ''}
              </p>
            )}
          </div>

          {/* ── Feed table ── */}
          {activeTab === 'feed' && (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border text-left text-xs uppercase tracking-wider text-slate-500">
                    <th className="px-4 py-3">Author</th>
                    <th className="px-4 py-3">Content</th>
                    <th className="w-14 px-4 py-3">Image</th>
                    <th className="px-4 py-3">Stats</th>
                    <th className="px-4 py-3">Status</th>
                    <th className="px-4 py-3 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {loading ? (
                    <tr>
                      <td colSpan={6} className="px-4 py-14 text-center">
                        <LoaderCircle className="mx-auto h-5 w-5 animate-spin text-slate-500" />
                      </td>
                    </tr>
                  ) : filteredPosts.length === 0 ? (
                    <tr>
                      <td colSpan={6} className="px-4 py-14 text-center text-slate-500">
                        No posts match your filters.
                      </td>
                    </tr>
                  ) : (
                    filteredPosts.map((post) => (
                      <tr
                        key={post.id}
                        className="border-b border-border/50 transition hover:bg-slate-900/40"
                      >
                        <td className="px-4 py-3">
                          <div className="flex items-center gap-2">
                            <Avatar src={post.author.avatar_path} name={post.author.display_name ?? '?'} />
                            <div>
                              <p className="font-medium text-white">
                                {post.author.display_name || 'Unknown'}
                              </p>
                              <p className="text-xs text-slate-500">{timeAgo(post.created_at)}</p>
                            </div>
                          </div>
                        </td>
                        <td className="max-w-xs px-4 py-3">
                          <p className="line-clamp-2 text-slate-300">
                            {post.content || <span className="italic text-slate-500">No text</span>}
                          </p>
                        </td>
                        <td className="px-4 py-3">
                          {post.image_path ? (
                            <div className="h-10 w-10 overflow-hidden rounded-lg bg-slate-800">
                              <PostImage src={post.image_path} className="h-full w-full object-cover" />
                            </div>
                          ) : (
                            <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-slate-800">
                              <ImageIcon className="h-4 w-4 text-slate-600" />
                            </div>
                          )}
                        </td>
                        <td className="px-4 py-3 text-slate-400">
                          <div className="flex items-center gap-3 text-xs">
                            <span>❤ {post.likes_count}</span>
                            <span className="flex items-center gap-1">
                              <MessageSquare className="h-3 w-3" /> {post.comments.length}
                            </span>
                          </div>
                        </td>
                        <td className="px-4 py-3">
                          <StatusBadge
                            label={post.hidden_by_admin ? 'Hidden' : 'Visible'}
                            tone={post.hidden_by_admin ? 'danger' : 'success'}
                          />
                        </td>
                        <td className="px-4 py-3 text-right">
                          <div className="inline-flex gap-2">
                            <button
                              type="button"
                              onClick={() => setViewingPost(post)}
                              className="rounded-lg border border-slate-700 bg-slate-900 px-2.5 py-1.5 text-xs font-medium text-slate-300 transition hover:border-emerald-500/50 hover:text-emerald-300"
                            >
                              View
                            </button>
                            <button
                              type="button"
                              onClick={() => void togglePost(post)}
                              disabled={busy === `toggle-post-${post.id}`}
                              title={post.hidden_by_admin ? 'Restore' : 'Hide'}
                              className="rounded-lg border border-slate-700 bg-slate-900 p-2 text-slate-400 transition hover:border-sky-500/50 hover:text-sky-300 disabled:opacity-40"
                            >
                              {post.hidden_by_admin ? (
                                <Eye className="h-3.5 w-3.5" />
                              ) : (
                                <EyeOff className="h-3.5 w-3.5" />
                              )}
                            </button>
                            <button
                              type="button"
                              onClick={() => void deletePost(post)}
                              disabled={busy === `delete-post-${post.id}`}
                              title="Delete permanently"
                              className="rounded-lg border border-slate-700 bg-slate-900 p-2 text-slate-400 transition hover:border-rose-500/50 hover:text-rose-300 disabled:opacity-40"
                            >
                              {busy === `delete-post-${post.id}` ? (
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
          )}

          {/* ── Reports table ── */}
          {activeTab === 'reports' && (
            <div className="overflow-x-auto">
              {loading ? (
                <div className="px-4 py-14 text-center">
                  <LoaderCircle className="mx-auto h-5 w-5 animate-spin text-slate-500" />
                </div>
              ) : reports.length === 0 ? (
                <div className="px-4 py-16 text-center">
                  <Check className="mx-auto mb-3 h-8 w-8 text-emerald-500" />
                  <p className="text-lg font-medium text-white">All caught up!</p>
                  <p className="mt-1 text-sm text-slate-400">No pending reports to review.</p>
                </div>
              ) : (
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-border text-left text-xs uppercase tracking-wider text-slate-500">
                      <th className="px-4 py-3">Type</th>
                      <th className="px-4 py-3">Content</th>
                      <th className="px-4 py-3">Author</th>
                      <th className="px-4 py-3">Reporter</th>
                      <th className="px-4 py-3">Reason</th>
                      <th className="px-4 py-3">Date</th>
                      <th className="px-4 py-3 text-right">Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {reports.map((report) => (
                      <tr
                        key={report.id}
                        className="border-b border-border/50 transition hover:bg-slate-900/40"
                      >
                        <td className="px-4 py-3">
                          <StatusBadge
                            label={report.post_id ? 'Post' : 'Comment'}
                            tone={report.post_id ? 'neutral' : 'warning'}
                          />
                        </td>
                        <td className="max-w-xs px-4 py-3">
                          <p className="line-clamp-2 text-slate-300 italic">
                            "{report.post_content || report.comment_content || 'No content'}"
                          </p>
                        </td>
                        <td className="px-4 py-3 text-slate-300">
                          {report.target_author?.display_name || 'Unknown'}
                        </td>
                        <td className="px-4 py-3 text-slate-300">
                          {report.reporter?.display_name || 'Unknown'}
                        </td>
                        <td className="px-4 py-3">
                          <span className="rounded-full border border-amber-500/30 bg-amber-500/10 px-2.5 py-1 text-xs font-medium text-amber-300">
                            {report.reason}
                          </span>
                        </td>
                        <td className="px-4 py-3 text-xs text-slate-500">
                          {timeAgo(report.created_at)}
                        </td>
                        <td className="px-4 py-3 text-right">
                          <div className="inline-flex gap-2">
                            <button
                              type="button"
                              onClick={() => void resolveReport(report.id, 'dismissed')}
                              disabled={busy === `report-${report.id}`}
                              className="inline-flex items-center gap-1.5 rounded-lg border border-slate-700 bg-slate-900 px-2.5 py-1.5 text-xs font-medium text-slate-300 transition hover:bg-slate-800 disabled:opacity-40"
                            >
                              <X className="h-3 w-3" /> Dismiss
                            </button>
                            <button
                              type="button"
                              onClick={() => void resolveReport(report.id, 'reviewed')}
                              disabled={busy === `report-${report.id}`}
                              className="inline-flex items-center gap-1.5 rounded-lg border border-emerald-900/50 bg-emerald-900/30 px-2.5 py-1.5 text-xs font-medium text-emerald-400 transition hover:bg-emerald-900/50 disabled:opacity-40"
                            >
                              <Check className="h-3 w-3" /> Reviewed
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
            </div>
          )}
        </Panel>
      </div>

      {/* Post detail modal */}
      {viewingPost ? (
        <div className="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto p-4 pt-12">
          <div className="absolute inset-0 bg-slate-950/80 backdrop-blur-sm" onClick={() => setViewingPost(null)} />
          <div className="relative z-10 w-full max-w-2xl rounded-3xl border border-border bg-slate-900 shadow-2xl">
            {/* Header */}
            <div className="flex items-center justify-between rounded-t-3xl border-b border-white/10 bg-slate-800/60 px-6 py-5">
              <div className="flex items-center gap-3">
                <Avatar src={viewingPost.author.avatar_path} name={viewingPost.author.display_name ?? '?'} />
                <div>
                  <p className="font-semibold text-white">
                    {viewingPost.author.display_name || 'Unknown'}
                  </p>
                  <p className="text-xs text-slate-500">{timeAgo(viewingPost.created_at)}</p>
                </div>
                <StatusBadge
                  label={viewingPost.hidden_by_admin ? 'Hidden' : 'Visible'}
                  tone={viewingPost.hidden_by_admin ? 'danger' : 'success'}
                />
              </div>
              <button
                type="button"
                onClick={() => setViewingPost(null)}
                className="rounded-xl border border-slate-700 bg-slate-800 p-2 text-slate-400 transition hover:text-white"
              >
                <X className="h-4 w-4" />
              </button>
            </div>

            {/* Body */}
            <div className="max-h-[72vh] overflow-y-auto">
              {/* Post content */}
              <div className="px-6 py-5">
                <p className="whitespace-pre-wrap leading-7 text-slate-200">
                  {viewingPost.content || <span className="italic text-slate-500">No text content.</span>}
                </p>
                {viewingPost.image_path ? (
                  <div className="mt-4 overflow-hidden rounded-2xl border border-slate-800">
                    <PostImage
                      src={viewingPost.image_path}
                      className="max-h-80 w-full object-cover"
                    />
                  </div>
                ) : null}
                {/* Post stats + actions */}
                <div className="mt-4 flex flex-wrap items-center justify-between gap-3">
                  <div className="flex gap-4 text-xs text-slate-500">
                    <span>❤ {viewingPost.likes_count} likes</span>
                    <span>💬 {viewingPost.comments.length} comments</span>
                  </div>
                  <div className="flex gap-2">
                    <button
                      type="button"
                      onClick={() => void togglePost(viewingPost)}
                      disabled={busy === `toggle-post-${viewingPost.id}`}
                      className="inline-flex items-center gap-2 rounded-xl border border-slate-700 bg-slate-800 px-3 py-2 text-sm font-medium text-slate-200 transition hover:bg-slate-700 disabled:opacity-50"
                    >
                      {viewingPost.hidden_by_admin ? (
                        <><Eye className="h-4 w-4" /> Restore post</>
                      ) : (
                        <><EyeOff className="h-4 w-4" /> Hide post</>
                      )}
                    </button>
                    <button
                      type="button"
                      onClick={() => void deletePost(viewingPost)}
                      disabled={busy === `delete-post-${viewingPost.id}`}
                      className="inline-flex items-center gap-2 rounded-xl border border-rose-900/50 bg-rose-950/30 px-3 py-2 text-sm font-medium text-rose-300 transition hover:bg-rose-900/50 disabled:opacity-50"
                    >
                      <Trash2 className="h-4 w-4" /> Delete post
                    </button>
                  </div>
                </div>
              </div>

              {/* Comments */}
              <div className="border-t border-white/10 px-6 py-4">
                <p className="mb-4 text-xs font-semibold uppercase tracking-widest text-slate-500">
                  Comments ({viewingPost.comments.length})
                </p>
                {viewingPost.comments.length === 0 ? (
                  <p className="text-sm text-slate-500">No comments on this post.</p>
                ) : (
                  <div className="space-y-3">
                    {viewingPost.comments.map((comment) => (
                      <div
                        key={comment.id}
                        className={`rounded-2xl border p-4 ${
                          comment.hidden_by_admin
                            ? 'border-rose-900/30 bg-rose-950/10'
                            : 'border-slate-800 bg-slate-950/50'
                        }`}
                      >
                        <div className="flex items-start justify-between gap-3">
                          <div className="min-w-0 flex-1">
                            <div className="flex flex-wrap items-center gap-2">
                              <span className="text-sm font-medium text-white">
                                {comment.author.display_name || 'Unknown'}
                              </span>
                              <StatusBadge
                                label={comment.hidden_by_admin ? 'Hidden' : 'Visible'}
                                tone={comment.hidden_by_admin ? 'danger' : 'success'}
                              />
                              <span className="text-xs text-slate-500">
                                {timeAgo(comment.created_at)}
                              </span>
                            </div>
                            <p className="mt-2 text-sm leading-6 text-slate-300">{comment.content}</p>
                          </div>
                          <div className="flex shrink-0 gap-1.5">
                            <button
                              type="button"
                              onClick={() => void toggleComment(comment)}
                              disabled={busy === `toggle-comment-${comment.id}`}
                              title={comment.hidden_by_admin ? 'Restore' : 'Hide'}
                              className="rounded-lg border border-slate-700 bg-slate-900 p-1.5 text-slate-400 transition hover:border-sky-500/50 hover:text-sky-300 disabled:opacity-40"
                            >
                              {comment.hidden_by_admin ? (
                                <Eye className="h-3.5 w-3.5" />
                              ) : (
                                <EyeOff className="h-3.5 w-3.5" />
                              )}
                            </button>
                            <button
                              type="button"
                              onClick={() => void deleteComment(comment)}
                              disabled={busy === `delete-comment-${comment.id}`}
                              title="Delete"
                              className="rounded-lg border border-slate-700 bg-slate-900 p-1.5 text-slate-400 transition hover:border-rose-500/50 hover:text-rose-300 disabled:opacity-40"
                            >
                              <Trash2 className="h-3.5 w-3.5" />
                            </button>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      ) : null}
    </ProtectedShell>
  );
}
