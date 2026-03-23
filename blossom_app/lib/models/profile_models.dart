class ProfileModel {
  ProfileModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.avatarPath,
    required this.role,
    required this.notificationsEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? avatarPath;
  final String role;
  final bool notificationsEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get userFacingName {
    final normalizedDisplayName = displayName?.trim();
    if (normalizedDisplayName != null && normalizedDisplayName.isNotEmpty) {
      return normalizedDisplayName;
    }
    final emailParts = email.split('@');
    return emailParts.isEmpty ? email : emailParts.first;
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      avatarPath: json['avatar_path'] as String?,
      role: json['role'] as String,
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
