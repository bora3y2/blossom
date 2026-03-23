class CommunityProfileSummaryModel {
  CommunityProfileSummaryModel({
    required this.id,
    required this.displayName,
    required this.avatarPath,
  });

  final String id;
  final String? displayName;
  final String? avatarPath;

  factory CommunityProfileSummaryModel.fromJson(Map<String, dynamic> json) {
    return CommunityProfileSummaryModel(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      avatarPath: json['avatar_path'] as String?,
    );
  }
}

class CommunityCommentModel {
  CommunityCommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.hiddenByAdmin,
    required this.createdAt,
    required this.updatedAt,
    required this.author,
  });

  final String id;
  final String postId;
  final String userId;
  final String content;
  final bool hiddenByAdmin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CommunityProfileSummaryModel author;

  factory CommunityCommentModel.fromJson(Map<String, dynamic> json) {
    return CommunityCommentModel(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      hiddenByAdmin: json['hidden_by_admin'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      author: CommunityProfileSummaryModel.fromJson(
        json['author'] as Map<String, dynamic>,
      ),
    );
  }
}

class CommunityPostModel {
  CommunityPostModel({
    required this.id,
    required this.userId,
    required this.content,
    required this.imagePath,
    required this.hiddenByAdmin,
    required this.createdAt,
    required this.updatedAt,
    required this.author,
    required this.comments,
    required this.likesCount,
    required this.commentsCount,
    required this.likedByMe,
  });

  final String id;
  final String userId;
  final String content;
  final String? imagePath;
  final bool hiddenByAdmin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CommunityProfileSummaryModel author;
  final List<CommunityCommentModel> comments;
  final int likesCount;
  final int commentsCount;
  final bool likedByMe;

  factory CommunityPostModel.fromJson(Map<String, dynamic> json) {
    return CommunityPostModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String? ?? '',
      imagePath: json['image_path'] as String?,
      hiddenByAdmin: json['hidden_by_admin'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      author: CommunityProfileSummaryModel.fromJson(
        json['author'] as Map<String, dynamic>,
      ),
      comments: (json['comments'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                CommunityCommentModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      likedByMe: json['liked_by_me'] as bool? ?? false,
    );
  }

  CommunityPostModel copyWith({
    String? id,
    String? userId,
    String? content,
    String? imagePath,
    bool? hiddenByAdmin,
    DateTime? createdAt,
    DateTime? updatedAt,
    CommunityProfileSummaryModel? author,
    List<CommunityCommentModel>? comments,
    int? likesCount,
    int? commentsCount,
    bool? likedByMe,
  }) {
    return CommunityPostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      imagePath: imagePath ?? this.imagePath,
      hiddenByAdmin: hiddenByAdmin ?? this.hiddenByAdmin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      author: author ?? this.author,
      comments: comments ?? this.comments,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }
}

class CommunityFeedModel {
  CommunityFeedModel({required this.items, required this.totalCount});

  final List<CommunityPostModel> items;
  final int totalCount;

  factory CommunityFeedModel.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    return CommunityFeedModel(
      items: (json['items'] as List<dynamic>? ?? const [])
          .map(
            (item) => CommunityPostModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      totalCount: meta['count'] as int? ?? 0,
    );
  }
}
