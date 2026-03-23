import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_session.dart';
import '../../core/date_time_utils.dart';
import '../../core/image_utils.dart';
import '../../models/community_models.dart';
import '../../repositories/community_repository.dart';
import '../../core/theme.dart';

class CommentsFeedScreen extends StatefulWidget {
  const CommentsFeedScreen({required this.postId, super.key});

  final String? postId;

  @override
  State<CommentsFeedScreen> createState() => _CommentsFeedScreenState();
}

class _CommentsFeedScreenState extends State<CommentsFeedScreen> {
  final TextEditingController _commentController = TextEditingController();

  bool _didLoad = false;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  CommunityPostModel? _post;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) {
      return;
    }
    _didLoad = true;
    _loadPost();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Center(
                child: Container(
                  width: 48,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
                  onPressed: () => context.pop(),
                ),
                const Expanded(
                  child: Text(
                    'COMMENTS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? _buildErrorState()
                  : _buildCommentsContent(),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Unable to load comments.',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPost,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsContent() {
    final post = _post;
    if (post == null) {
      return const SizedBox.shrink();
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      children: [
        if (post.content.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              post.content,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (post.comments.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 48),
            child: Text(
              'No comments yet. Start the conversation.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          )
        else
          ...post.comments.map(
            (comment) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildCommentItem(comment),
            ),
          ),
      ],
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        border: Border(
          top: BorderSide(color: AppTheme.primary.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        children: [
          if (_errorMessage != null && !_isLoading)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                IconButton(
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send, color: AppTheme.primary),
                  onPressed: _isSubmitting ? null : _submitComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(CommunityCommentModel comment) {
    final authorName = comment.author.displayName?.trim().isNotEmpty == true
        ? comment.author.displayName!
        : 'Plant Lover';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundImage: CachedNetworkImageProvider(
            resolveAvatarImageUrl(comment.author.avatarPath),
          ),
          radius: 20,
          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            authorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                        Text(
                          formatTimeAgo(comment.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            size: 16,
                            color: Colors.grey,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onSelected: (value) {
                            if (value == 'delete') {
                              _handleDeleteComment(comment);
                            } else if (value == 'report') {
                              _handleReportComment(comment);
                            }
                          },
                          itemBuilder: (context) {
                            final currentUserId = AppSessionScope.of(
                              context,
                            ).currentUserId;
                            final isMine = comment.userId == currentUserId;
                            return [
                              if (isMine)
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    'Delete Comment',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                )
                              else
                                const PopupMenuItem(
                                  value: 'report',
                                  child: Text('Report Comment'),
                                ),
                            ];
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comment.content,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _loadPost() async {
    final postId = widget.postId;
    if (postId == null || postId.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'A post ID is required to load comments.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final repository = CommunityRepository(AppSessionScope.of(context));
      final post = await repository.fetchPost(postId);
      if (!mounted) {
        return;
      }
      setState(() {
        _post = post;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = '$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitComment() async {
    final postId = widget.postId;
    if (postId == null || postId.isEmpty) {
      return;
    }
    final content = _commentController.text.trim();
    if (content.isEmpty) {
      setState(() {
        _errorMessage = 'Write a comment before sending.';
      });
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final repository = CommunityRepository(AppSessionScope.of(context));
      await repository.createComment(postId: postId, content: content);
      _commentController.clear();
      await _loadPost();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = '$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _handleDeleteComment(CommunityCommentModel comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text(
          'Are you sure you want to delete this comment? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await CommunityRepository(
        AppSessionScope.of(context),
      ).deleteComment(comment.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Comment deleted')));
      await _loadPost(); // Refresh the list
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete comment: $e')));
    }
  }

  Future<void> _handleReportComment(CommunityCommentModel comment) async {
    final reasonController = TextEditingController();
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Comment'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Reason for reporting...',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: const Text('Report'),
          ),
        ],
      ),
    );
    if (submit != true || reasonController.text.trim().isEmpty) return;

    try {
      await CommunityRepository(AppSessionScope.of(context)).reportComment(
        commentId: comment.id,
        reason: reasonController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment reported to administrators.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to report comment: $e')));
    }
  }
}
