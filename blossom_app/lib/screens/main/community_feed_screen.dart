import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_session.dart';
import '../../core/date_time_utils.dart';
import '../../core/image_utils.dart';
import '../../models/community_models.dart';
import '../../repositories/community_repository.dart';
import '../../core/theme.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

const _kPageSize = 20;

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  String _selectedFilter = 'all';
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  bool _didLoad = false;
  String? _errorMessage;
  List<CommunityPostModel> _posts = const [];
  final Set<String> _likeBusyPostIds = <String>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) {
      return;
    }
    _didLoad = true;
    _loadFeed();
  }

  CommunityRepository _repository(BuildContext context) {
    return CommunityRepository(AppSessionScope.of(context));
  }

  List<CommunityPostModel> _filteredPosts(BuildContext context) {
    final currentUserId = AppSessionScope.of(context).currentUserId;
    if (_selectedFilter == 'mine' && currentUserId != null) {
      return _posts.where((post) => post.userId == currentUserId).toList();
    }
    return _posts;
  }

  @override
  Widget build(BuildContext context) {
    final filteredPosts = _filteredPosts(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight.withValues(alpha: 0.8),
        elevation: 0,
        title: const Text(
          'Blossom',
          style: TextStyle(
            color: AppTheme.primary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: AppTheme.primary,
              radius: 20,
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: _openComposer,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorState()
          : RefreshIndicator(
              onRefresh: _loadFeed,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 16.0,
                      ),
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedFilter = 'all'),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _selectedFilter == 'all'
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'All',
                                    style: TextStyle(
                                      color: _selectedFilter == 'all'
                                          ? AppTheme.primary
                                          : AppTheme.primary.withValues(
                                              alpha: 0.6,
                                            ),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedFilter = 'mine'),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _selectedFilter == 'mine'
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'My Posts',
                                    style: TextStyle(
                                      color: _selectedFilter == 'mine'
                                          ? AppTheme.primary
                                          : AppTheme.primary.withValues(
                                              alpha: 0.6,
                                            ),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (filteredPosts.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            _selectedFilter == 'mine'
                                ? 'You have not posted yet.'
                                : 'No posts yet. Share the first update.',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      sliver: SliverList.builder(
                        itemCount: filteredPosts.length + 1,
                        itemBuilder: (context, index) {
                          if (index == filteredPosts.length) {
                            return _buildFeedFooter();
                          }
                          final post = filteredPosts[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: _buildPostCard(post),
                          );
                        },
                      ),
                    ),
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
              'Unable to load the community feed.',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFeed,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(CommunityPostModel post) {
    final authorName = post.author.displayName?.trim().isNotEmpty == true
        ? post.author.displayName!
        : 'Plant Lover';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: CachedNetworkImageProvider(
                    resolveAvatarImageUrl(post.author.avatarPath),
                  ),
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      Text(
                        formatTimeAgo(post.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primary.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_likeBusyPostIds.contains(post.id))
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _handleDeletePost(post);
                    } else if (value == 'report') {
                      _handleReportPost(post);
                    }
                  },
                  itemBuilder: (context) {
                    final currentUserId = AppSessionScope.of(
                      context,
                    ).currentUserId;
                    final isMine = post.userId == currentUserId;
                    return [
                      if (isMine)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Delete Post',
                            style: TextStyle(color: Colors.red),
                          ),
                        )
                      else
                        const PopupMenuItem(
                          value: 'report',
                          child: Text('Report Post'),
                        ),
                    ];
                  },
                ),
              ],
            ),
          ),
          if (post.imagePath != null)
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                color: AppTheme.primary.withValues(alpha: 0.05),
                child: CachedNetworkImage(
                  imageUrl: resolvePostImageUrl(post.imagePath),
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, err) =>
                      const Icon(Icons.broken_image),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: _likeBusyPostIds.contains(post.id)
                          ? null
                          : () => _toggleLike(post),
                      borderRadius: BorderRadius.circular(999),
                      child: _buildActionButton(
                        post.likedByMe ? Icons.favorite : Icons.favorite_border,
                        post.likesCount.toString(),
                        isActive: post.likedByMe,
                      ),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () => _openComments(post.id),
                      borderRadius: BorderRadius.circular(999),
                      child: _buildActionButton(
                        Icons.chat_bubble_outline,
                        post.commentsCount.toString(),
                        isActive: false,
                      ),
                    ),
                    const Spacer(),
                    _buildActionButton(
                      Icons.share,
                      '',
                      isActive: false,
                      showText: false,
                    ),
                  ],
                ),
                if (post.content.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.primary,
                        height: 1.5,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                      children: [
                        TextSpan(
                          text: '$authorName ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: post.content),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String text, {
    required bool isActive,
    bool showText = true,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 24,
          color: isActive
              ? Colors.redAccent
              : AppTheme.primary.withValues(alpha: 0.7),
        ),
        if (showText) ...[
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFeedFooter() {
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_hasMore) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: TextButton(
          onPressed: _loadMore,
          child: Text(
            'Load more',
            style: TextStyle(
              color: AppTheme.primary.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    return const SizedBox(height: 100);
  }

  Future<void> _loadFeed() async {
    final repository = _repository(context);
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final feed = await repository.fetchFeed(limit: _kPageSize, offset: 0);
      if (!mounted) return;
      setState(() {
        _posts = feed.items;
        _offset = feed.items.length;
        _hasMore = feed.items.length >= _kPageSize;
      });
    } catch (error) {
      if (!mounted) return;
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

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    final repository = _repository(context);
    setState(() {
      _isLoadingMore = true;
    });
    try {
      final feed = await repository.fetchFeed(
        limit: _kPageSize,
        offset: _offset,
      );
      if (!mounted) return;
      setState(() {
        _posts = [..._posts, ...feed.items];
        _offset = _offset + feed.items.length;
        _hasMore = feed.items.length >= _kPageSize;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _toggleLike(CommunityPostModel post) async {
    final repository = _repository(context);
    setState(() {
      _likeBusyPostIds.add(post.id);
    });
    try {
      final updatedPost = post.likedByMe
          ? await repository.unlikePost(post.id)
          : await repository.likePost(post.id);
      if (!mounted) {
        return;
      }
      _replacePost(updatedPost);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) {
        setState(() {
          _likeBusyPostIds.remove(post.id);
        });
      }
    }
  }

  Future<void> _openComposer() async {
    final created = await context.push('/upload_post');
    if (!mounted || created != true) {
      return;
    }
    await _loadFeed();
  }

  Future<void> _openComments(String postId) async {
    await context.push('/comments_feed', extra: postId);
    if (!mounted) {
      return;
    }
    await _refreshPost(postId);
  }

  Future<void> _refreshPost(String postId) async {
    try {
      final updatedPost = await _repository(context).fetchPost(postId);
      if (!mounted) {
        return;
      }
      _replacePost(updatedPost);
    } catch (_) {}
  }

  void _replacePost(CommunityPostModel updatedPost) {
    setState(() {
      _posts = _posts
          .map((post) => post.id == updatedPost.id ? updatedPost : post)
          .toList();
    });
  }

  Future<void> _handleDeletePost(CommunityPostModel post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
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
      await _repository(context).deletePost(post.id);
      if (!mounted) return;
      setState(() {
        _posts = _posts.where((p) => p.id != post.id).toList();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Post deleted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete post: $e')));
    }
  }

  Future<void> _handleReportPost(CommunityPostModel post) async {
    final reasonController = TextEditingController();
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Post'),
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
      await _repository(
        context,
      ).reportPost(postId: post.id, reason: reasonController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post reported to administrators.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to report post: $e')));
    }
  }
}
