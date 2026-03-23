import '../core/app_session.dart';
import '../data/api_client.dart';
import '../models/community_models.dart';

class CommunityRepository {
  CommunityRepository(this.session) : _apiClient = ApiClient(session);

  final AppSession session;
  final ApiClient _apiClient;

  Future<CommunityFeedModel> fetchFeed({
    int limit = 20,
    int offset = 0,
  }) async {
    final data =
        await _apiClient.getJson(
              '/community/posts?limit=$limit&offset=$offset',
            )
            as Map<String, dynamic>;
    return CommunityFeedModel.fromJson(data);
  }

  Future<CommunityPostModel> fetchPost(String postId) async {
    final data =
        await _apiClient.getJson('/community/posts/$postId')
            as Map<String, dynamic>;
    return CommunityPostModel.fromJson(data);
  }

  Future<CommunityPostModel> createPost({
    required String content,
    String? imagePath,
  }) async {
    final body = <String, dynamic>{'content': content};
    if (imagePath != null) {
      body['image_path'] = imagePath;
    }
    final data =
        await _apiClient.postJson('/community/posts', body: body)
            as Map<String, dynamic>;
    return CommunityPostModel.fromJson(data);
  }

  Future<CommunityCommentModel> createComment({
    required String postId,
    required String content,
  }) async {
    final data =
        await _apiClient.postJson(
              '/community/posts/$postId/comments',
              body: {'content': content},
            )
            as Map<String, dynamic>;
    return CommunityCommentModel.fromJson(data);
  }

  Future<CommunityPostModel> likePost(String postId) async {
    final data =
        await _apiClient.postJson(
              '/community/posts/$postId/like',
              body: const {},
            )
            as Map<String, dynamic>;
    return CommunityPostModel.fromJson(data);
  }

  Future<CommunityPostModel> unlikePost(String postId) async {
    final data =
        await _apiClient.deleteJson('/community/posts/$postId/like')
            as Map<String, dynamic>;
    return CommunityPostModel.fromJson(data);
  }

  Future<void> deletePost(String postId) async {
    await _apiClient.deleteJson('/community/posts/$postId');
  }

  Future<void> deleteComment(String commentId) async {
    await _apiClient.deleteJson('/community/comments/$commentId');
  }

  Future<void> reportPost({
    required String postId,
    required String reason,
  }) async {
    await _apiClient.postJson(
      '/community/posts/$postId/report',
      body: {'reason': reason},
    );
  }

  Future<void> reportComment({
    required String commentId,
    required String reason,
  }) async {
    await _apiClient.postJson(
      '/community/comments/$commentId/report',
      body: {'reason': reason},
    );
  }
}
