'use client';

import { useEffect, useMemo, useState } from 'react';
import { Eye, EyeOff, LoaderCircle, MessageSquareWarning, Trash2, Check, X } from 'lucide-react';

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

function replacePost(posts: CommunityPost[], updatedPost: CommunityPost) {
  return posts.map((post) => (post.id === updatedPost.id ? updatedPost : post));
}

function replaceComment(posts: CommunityPost[], updatedComment: CommunityComment) {
  return posts.map((post) => {
    if (post.id !== updatedComment.post_id) {
      return post;
    }
    const comments = post.comments.map((comment) =>
      comment.id === updatedComment.id ? updatedComment : comment,
    );
    const commentsCount = comments.filter((comment) => !comment.hidden_by_admin).length;
    return {
      ...post,
      comments,
      comments_count: commentsCount,
    };
  });
}

function removePost(posts: CommunityPost[], postId: string) {
  return posts.filter((post) => post.id !== postId);
}

function removeComment(posts: CommunityPost[], commentId: string) {
  return posts.map((post) => ({
    ...post,
    comments: post.comments.filter((c) => c.id !== commentId),
  }));
}

function formatRelativeDate(dateString: string) {
  const date = new Date(dateString);
  const now = new Date();
  const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000);
  
  if (diffInSeconds < 60) return `${diffInSeconds}s ago`;
  const diffInMinutes = Math.floor(diffInSeconds / 60);
  if (diffInMinutes < 60) return `${diffInMinutes}m ago`;
  const diffInHours = Math.floor(diffInMinutes / 60);
  if (diffInHours < 24) return `${diffInHours}h ago`;
  const diffInDays = Math.floor(diffInHours / 24);
  if (diffInDays < 7) return `${diffInDays}d ago`;
  
  return date.toLocaleDateString();
}

export default function CommunityModerationPage() {
  const { session } = useAuth();
  const accessToken = session?.access_token ?? null;
  const [activeTab, setActiveTab] = useState<'feed' | 'reports'>('feed');
  const [posts, setPosts] = useState<CommunityPost[]>([]);
  const [reports, setReports] = useState<Report[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [busyIndicator, setBusyIndicator] = useState<string | null>(null);
  const [query, setQuery] = useState('');
  const [showHiddenOnly, setShowHiddenOnly] = useState(false);

  const loadData = async () => {
    if (!accessToken) return;
    setLoading(true);
    setError(null);
    try {
      if (activeTab === 'feed') {
        const payload = await getAdminCommunityFeed(accessToken);
        setPosts(payload.items);
      } else {
        const payload = await getAdminReports(accessToken, 'pending');
        setReports(payload.items);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unable to load data.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void loadData();
  }, [accessToken, activeTab]);

  const filteredPosts = useMemo(() => {
    const needle = query.trim().toLowerCase();
    return posts.filter((post) => {
      if (showHiddenOnly) {
        const hasHiddenComments = post.comments.some((comment) => comment.hidden_by_admin);
        if (!post.hidden_by_admin && !hasHiddenComments) {
          return false;
        }
      }
      if (!needle) return true;
      return (
        post.content.toLowerCase().includes(needle) ||
        (post.author.display_name ?? '').toLowerCase().includes(needle) ||
        post.comments.some(
          (comment) =>
            comment.content.toLowerCase().includes(needle) ||
            (comment.author.display_name ?? '').toLowerCase().includes(needle),
        )
      );
    });
  }, [posts, query, showHiddenOnly]);

  const hiddenPostCount = useMemo(() => posts.filter((post) => post.hidden_by_admin).length, [posts]);
  const hiddenCommentCount = useMemo(
    () => posts.flatMap((post) => post.comments).filter((comment) => comment.hidden_by_admin).length,
    [posts],
  );

  const handleTogglePost = async (post: CommunityPost) => {
    if (!accessToken) return;
    setBusyIndicator(`toggle-post-${post.id}`);
    setError(null);
    setSuccessMessage(null);
    try {
      const updated = await setAdminPostVisibility(accessToken, post.id, !post.hidden_by_admin);
      setPosts((current) => replacePost(current, updated));
      setSuccessMessage(updated.hidden_by_admin ? 'Post hidden successfully.' : 'Post restored successfully.');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unable to update post.');
    } finally {
      setBusyIndicator(null);
    }
  };

  const handleToggleComment = async (comment: CommunityComment) => {
    if (!accessToken) return;
    setBusyIndicator(`toggle-comment-${comment.id}`);
    setError(null);
    setSuccessMessage(null);
    try {
      const updated = await setAdminCommentVisibility(accessToken, comment.id, !comment.hidden_by_admin);
      setPosts((current) => replaceComment(current, updated));
      setSuccessMessage(updated.hidden_by_admin ? 'Comment hidden successfully.' : 'Comment restored.');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unable to update comment.');
    } finally {
      setBusyIndicator(null);
    }
  };

  const handleDeletePost = async (postId: string) => {
    if (!accessToken || !window.confirm('Delete this post permanently? This cannot be undone.')) return;
    setBusyIndicator(`delete-post-${postId}`);
    setError(null);
    setSuccessMessage(null);
    try {
      await deleteAdminPost(accessToken, postId);
      setPosts((current) => removePost(current, postId));
      setSuccessMessage('Post deleted permanently.');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unable to delete post.');
    } finally {
      setBusyIndicator(null);
    }
  };

  const handleDeleteComment = async (commentId: string) => {
    if (!accessToken || !window.confirm('Delete this comment permanently? This cannot be undone.')) return;
    setBusyIndicator(`delete-comment-${commentId}`);
    setError(null);
    setSuccessMessage(null);
    try {
      await deleteAdminComment(accessToken, commentId);
      setPosts((current) => removeComment(current, commentId));
      setSuccessMessage('Comment deleted permanently.');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unable to delete comment.');
    } finally {
      setBusyIndicator(null);
    }
  };

  const handleUpdateReportStatus = async (reportId: string, status: 'reviewed' | 'dismissed') => {
    if (!accessToken) return;
    setBusyIndicator(`resolve-report-${reportId}`);
    setError(null);
    setSuccessMessage(null);
    try {
      await updateAdminReportStatus(accessToken, reportId, status);
      setReports((current) => current.filter((r) => r.id !== reportId));
      setSuccessMessage(`Report marked as ${status}.`);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unable to update report.');
    } finally {
      setBusyIndicator(null);
    }
  };

  return (
    <ProtectedShell>
      <div className="space-y-4">
        <Panel className="p-6 sm:p-8">
          <Topbar
            title="Community moderation"
            subtitle="Review all community posts, comments, and user reports from a single operational surface."
          />
          <div className="mt-8 flex items-center border-b border-white/10">
            <button
              type="button"
              onClick={() => setActiveTab('feed')}
              className={`px-6 py-3 text-sm font-medium transition-colors ${
                activeTab === 'feed'
                  ? 'border-b-2 border-emerald-400 text-emerald-400'
                  : 'text-slate-400 hover:text-slate-300'
              }`}
            >
              All Content Feed
            </button>
            <button
              type="button"
              onClick={() => setActiveTab('reports')}
              className={`px-6 py-3 text-sm font-medium transition-colors ${
                activeTab === 'reports'
                  ? 'border-b-2 border-emerald-400 text-emerald-400'
                  : 'text-slate-400 hover:text-slate-300'
              }`}
            >
              Pending Reports
            </button>
          </div>
        </Panel>

        {activeTab === 'feed' && (
          <div className="grid gap-4 md:grid-cols-3">
            <Panel className="p-5">
              <p className="text-sm text-slate-400">Posts in feed</p>
              <p className="mt-3 text-3xl font-semibold text-white">{posts.length}</p>
            </Panel>
            <Panel className="p-5">
              <p className="text-sm text-slate-400">Hidden posts</p>
              <p className="mt-3 text-3xl font-semibold text-white">{hiddenPostCount}</p>
            </Panel>
            <Panel className="p-5">
              <p className="text-sm text-slate-400">Hidden comments</p>
              <p className="mt-3 text-3xl font-semibold text-white">{hiddenCommentCount}</p>
            </Panel>
          </div>
        )}

        {error ? (
          <Panel className="border-rose-400/20 bg-rose-500/10 p-5 text-sm text-rose-100">{error}</Panel>
        ) : null}
        {successMessage ? (
          <Panel className="border-emerald-400/20 bg-emerald-500/10 p-5 text-sm text-emerald-100">
            {successMessage}
          </Panel>
        ) : null}

        <Panel className="p-6 sm:p-8">
          {activeTab === 'feed' && (
            <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
              <div>
                <p className="text-xs uppercase tracking-[0.28em] text-emerald-300">Moderation queue</p>
                <h3 className="mt-3 text-2xl font-semibold text-white">Posts and comments</h3>
              </div>
              <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
                <input
                  value={query}
                  onChange={(event) => setQuery(event.target.value)}
                  placeholder="Search..."
                  className="w-full rounded-2xl border border-slate-700 bg-slate-950 px-4 py-3 outline-none transition focus:border-emerald-400 sm:w-64"
                />
                <label className="flex items-center gap-3 text-sm text-slate-300">
                  <input
                    type="checkbox"
                    checked={showHiddenOnly}
                    onChange={(event) => setShowHiddenOnly(event.target.checked)}
                    className="h-4 w-4 rounded border-slate-600 bg-slate-950 text-emerald-500"
                  />
                  Hidden only
                </label>
              </div>
            </div>
          )}

          {activeTab === 'reports' && (
            <div>
              <p className="text-xs uppercase tracking-[0.28em] text-emerald-300">User Reports</p>
              <h3 className="mt-3 text-2xl font-semibold text-white">Pending content review</h3>
            </div>
          )}

          <div className="mt-6 space-y-4">
            {loading ? (
              <div className="flex items-center gap-3 rounded-2xl border border-slate-800 bg-slate-950/70 p-4 text-sm text-slate-300">
                <LoaderCircle className="h-4 w-4 animate-spin" />
                Loading {activeTab === 'feed' ? 'feed' : 'reports'}...
              </div>
            ) : null}

            {!loading && activeTab === 'feed' && filteredPosts.length === 0 ? (
              <div className="rounded-2xl border border-slate-800 bg-slate-950/70 p-6 text-sm text-slate-400">
                No posts match your current filter.
              </div>
            ) : null}

            {!loading && activeTab === 'reports' && reports.length === 0 ? (
              <div className="rounded-2xl border border-emerald-900/50 bg-emerald-950/30 p-8 text-center text-emerald-200">
                <Check className="mx-auto mb-3 h-8 w-8 text-emerald-500" />
                <p className="text-lg font-medium">All caught up!</p>
                <p className="mt-1 text-sm opacity-80">There are no pending reports to review.</p>
              </div>
            ) : null}

            {activeTab === 'feed' &&
              filteredPosts.map((post) => (
                <div key={post.id} className="rounded-3xl border border-slate-800 bg-slate-950/70 p-5">
                  <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                    <div className="min-w-0 flex-1">
                      <div className="flex flex-wrap items-center gap-2">
                        <img 
                          src={post.author.avatar_path || '/placeholder-avatar.png'} 
                          alt="" 
                          className="h-6 w-6 rounded-full bg-slate-800 object-cover" 
                        />
                        <p className="font-semibold text-white">
                          {post.author.display_name || 'Unknown author'}
                        </p>
                        <StatusBadge
                          label={post.hidden_by_admin ? 'Hidden post' : 'Visible post'}
                          tone={post.hidden_by_admin ? 'danger' : 'success'}
                        />
                        <span className="text-sm text-slate-500">• {formatRelativeDate(post.created_at)}</span>
                      </div>
                      <p className="mt-3 whitespace-pre-wrap text-sm leading-7 text-slate-300">
                        {post.content || <span className="italic opacity-50">No text content provided.</span>}
                      </p>
                      {post.image_path ? (
                        <div className="mt-4 overflow-hidden rounded-xl border border-slate-800">
                          <img src={post.image_path} alt="Post attachment" className="max-h-64 object-cover" />
                        </div>
                      ) : null}
                    </div>

                    <div className="flex items-center gap-2">
                      <button
                        type="button"
                        onClick={() => void handleTogglePost(post)}
                        disabled={busyIndicator === `toggle-post-${post.id}`}
                        className="inline-flex items-center gap-2 rounded-2xl border border-slate-700 bg-slate-950 px-4 py-2 text-sm font-semibold text-slate-200 transition hover:border-slate-600 hover:bg-slate-900 disabled:opacity-60"
                      >
                        {post.hidden_by_admin ? <Eye className="h-4 w-4" /> : <EyeOff className="h-4 w-4" />}
                        {post.hidden_by_admin ? 'Restore' : 'Hide'}
                      </button>
                      <button
                        type="button"
                        onClick={() => void handleDeletePost(post.id)}
                        disabled={busyIndicator === `delete-post-${post.id}`}
                        className="inline-flex items-center gap-2 rounded-2xl border border-rose-900/50 bg-rose-950/30 px-4 py-2 text-sm font-semibold text-rose-300 transition hover:bg-rose-900/50 disabled:opacity-60"
                      >
                        <Trash2 className="h-4 w-4" />
                        Delete
                      </button>
                    </div>
                  </div>

                  <div className="mt-6 space-y-3 border-t border-white/5 pt-5">
                    <div className="flex items-center gap-2 text-sm font-medium text-slate-400">
                      <MessageSquareWarning className="h-4 w-4" />
                      {post.comments.length} Comments
                    </div>

                    {post.comments.map((comment) => (
                      <div key={comment.id} className="rounded-2xl border border-slate-800/80 bg-slate-900/30 p-4">
                        <div className="flex flex-col gap-3 md:flex-row md:items-start md:justify-between">
                          <div className="min-w-0 flex-1">
                            <div className="flex flex-wrap items-center gap-2">
                              <p className="text-sm font-medium text-white">
                                {comment.author.display_name || 'Unknown commenter'}
                              </p>
                              <StatusBadge
                                label={comment.hidden_by_admin ? 'Hidden comment' : 'Visible comment'}
                                tone={comment.hidden_by_admin ? 'danger' : 'success'}
                              />
                              <span className="text-xs text-slate-500">• {formatRelativeDate(comment.created_at)}</span>
                            </div>
                            <p className="mt-2 whitespace-pre-wrap text-sm leading-6 text-slate-300">
                              {comment.content}
                            </p>
                          </div>

                          <div className="flex items-center gap-2 mt-2 md:mt-0">
                            <button
                              type="button"
                              onClick={() => void handleToggleComment(comment)}
                              disabled={busyIndicator === `toggle-comment-${comment.id}`}
                              className="rounded-xl border border-slate-700 bg-slate-950 p-2 text-slate-300 hover:bg-slate-800 disabled:opacity-50"
                              title={comment.hidden_by_admin ? 'Restore' : 'Hide'}
                            >
                              {comment.hidden_by_admin ? <Eye className="h-4 w-4" /> : <EyeOff className="h-4 w-4" />}
                            </button>
                            <button
                              type="button"
                              onClick={() => void handleDeleteComment(comment.id)}
                              disabled={busyIndicator === `delete-comment-${comment.id}`}
                              className="rounded-xl border border-rose-900/50 bg-rose-950/30 p-2 text-rose-400 hover:bg-rose-900/50 disabled:opacity-50"
                              title="Delete permanently"
                            >
                              <Trash2 className="h-4 w-4" />
                            </button>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              ))}

            {activeTab === 'reports' &&
              reports.map((report) => (
                <div key={report.id} className="rounded-3xl border border-amber-900/30 bg-amber-950/10 p-5">
                  <div className="flex items-start justify-between">
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="rounded-md bg-amber-500/20 px-2 py-1 text-xs font-semibold uppercase tracking-wider text-amber-400">
                          {report.post_id ? 'Reported Post' : 'Reported Comment'}
                        </span>
                        <span className="text-xs text-slate-500">{formatRelativeDate(report.created_at)}</span>
                      </div>
                      <p className="mt-3 text-sm text-slate-400">
                        Reason: <span className="font-semibold text-white">{report.reason}</span>
                      </p>
                      <p className="mt-1 text-xs text-slate-500">
                        Reported by: {report.reporter?.display_name || 'Unknown'}
                      </p>
                      
                      <div className="mt-4 rounded-xl border border-white/10 bg-black/20 p-4">
                        <p className="mb-2 text-xs font-medium text-slate-500">
                          TARGET CONTENT ({report.target_author?.display_name || 'Unknown User'})
                        </p>
                        <p className="text-sm text-slate-300 italic">
                          "{report.post_content || report.comment_content || 'No content visible'}"
                        </p>
                        <p className="mt-2 text-xs text-slate-500">
                          To moderate this content, search for the user in the Feed tab.
                        </p>
                      </div>
                    </div>
                    
                    <div className="flex items-center gap-2">
                      <button
                        onClick={() => handleUpdateReportStatus(report.id, 'dismissed')}
                        disabled={busyIndicator === `resolve-report-${report.id}`}
                        className="inline-flex items-center gap-1.5 rounded-lg border border-slate-700 bg-slate-800 px-3 py-1.5 text-xs font-medium text-slate-300 transition hover:bg-slate-700 disabled:opacity-50"
                      >
                        <X className="h-3 w-3" />
                        Dismiss
                      </button>
                      <button
                        onClick={() => handleUpdateReportStatus(report.id, 'reviewed')}
                        disabled={busyIndicator === `resolve-report-${report.id}`}
                        className="inline-flex items-center gap-1.5 rounded-lg border border-emerald-900/50 bg-emerald-900/30 px-3 py-1.5 text-xs font-medium text-emerald-400 transition hover:bg-emerald-900/50 disabled:opacity-50"
                      >
                        <Check className="h-3 w-3" />
                        Mark Reviewed
                      </button>
                    </div>
                  </div>
                </div>
              ))}
          </div>
        </Panel>
      </div>
    </ProtectedShell>
  );
}
