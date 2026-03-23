import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_session.dart';
import '../../core/image_utils.dart';
import '../../models/profile_models.dart';
import '../../repositories/profile_repository.dart';

import '../../core/theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _didLoad = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  ProfileModel? _profile;

  bool get _notificationsEnabled => _profile?.notificationsEnabled ?? true;

  ProfileRepository _repository(BuildContext context) {
    return ProfileRepository(AppSessionScope.of(context));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) {
      return;
    }
    _didLoad = true;
    _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorState()
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: AppTheme.backgroundLight.withValues(
                    alpha: 0.8,
                  ),
                  floating: true,
                  pinned: true,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                        return;
                      }
                      context.go('/garden');
                    },
                  ),
                  title: const Text(
                    'Profile',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  centerTitle: true,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.logout, color: AppTheme.primary),
                      onPressed: _isSaving ? null : _signOut,
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 24.0,
                    ),
                    child: Column(
                      children: [
                        // Profile Details
                        Column(
                          children: [
                            Container(
                              width: 128,
                              height: 128,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  width: 4,
                                ),
                                image: DecorationImage(
                                  image: CachedNetworkImageProvider(
                                    resolveAvatarImageUrl(_profile?.avatarPath),
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _profile?.userFacingName ?? 'Your Profile',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              _profile?.email ?? '',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.primary.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Account Settings
                        _buildSectionTitle('Account Settings'),
                        const SizedBox(height: 8),
                        _buildMenuItem(
                          icon: Icons.edit_outlined,
                          title: 'Edit Profile',
                          onTap: _isSaving
                              ? () {}
                              : () async {
                                  final result = await context.push(
                                    '/edit_profile',
                                  );
                                  if (result == true && mounted) {
                                    _loadProfile();
                                  }
                                },
                        ),
                        const SizedBox(height: 8),
                        _buildMenuItem(
                          icon: Icons.lock,
                          title: 'Change Password',
                          onTap: () {
                            context.push('/change_password');
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildMenuContentItem(
                          icon: Icons.verified_user_outlined,
                          title: 'Role',
                          subtitle: _profile?.role == 'admin'
                              ? 'Administrator'
                              : 'Member',
                          trailingIcon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 8),
                        _buildMenuItem(
                          icon: Icons.delete_forever,
                          title: 'Delete Account',
                          onTap: _isSaving ? () {} : _deleteAccount,
                          iconColor: Colors.red,
                          textColor: Colors.red,
                        ),
                        const SizedBox(height: 24),
                        // Preferences
                        _buildSectionTitle('Preferences'),
                        const SizedBox(height: 8),
                        _buildToggleItem(
                          icon: Icons.notifications,
                          title: 'Notifications',
                          value: _notificationsEnabled,
                          onChanged: _isSaving ? null : _updateNotifications,
                        ),
                        const SizedBox(height: 8),
                        _buildMenuContentItem(
                          icon: Icons.calendar_today_outlined,
                          title: 'Member Since',
                          subtitle: _formatJoinedDate(_profile?.createdAt),
                          trailingIcon: Icons.event_available_outlined,
                        ),
                        const SizedBox(height: 100), // padding for bottom nav
                      ],
                    ),
                  ),
                ),
              ],
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
              'Unable to load your profile.',
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
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProfile,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadProfile() async {
    final repository = _repository(context);
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final profile = await repository.fetchMyProfile();
      if (!mounted) {
        return;
      }
      setState(() {
        _profile = profile;
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

  Future<void> _updateNotifications(bool value) async {
    final repository = _repository(context);
    setState(() => _isSaving = true);
    try {
      final updatedProfile = await repository.updateMyProfile(
        notificationsEnabled: value,
      );
      if (!mounted) return;
      setState(() => _profile = updatedProfile);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notifications updated')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteAccount() async {
    final nameConfirmController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.red),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to permanently delete your account? This action cannot be undone.',
            ),
            const SizedBox(height: 16),
            const Text('Type "DELETE" below to confirm:'),
            const SizedBox(height: 8),
            TextField(
              controller: nameConfirmController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameConfirmController.text.trim() == 'DELETE') {
                ctx.pop(true);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('You must type DELETE to confirm'),
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    nameConfirmController.dispose();

    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      final repository = _repository(context);
      await repository.deleteAccount();
      // Wait to gracefully clear session so UI doesnt snap early
      await AppSessionScope.of(context).signOut();
      if (!mounted) return;
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete account: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _signOut() async {
    final session = AppSessionScope.of(context);
    setState(() {
      _isSaving = true;
    });
    try {
      await session.signOut();
      if (!mounted) {
        return;
      }
      context.go('/login');
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
          _isSaving = false;
        });
      }
    }
  }

  String _formatJoinedDate(DateTime? date) {
    if (date == null) {
      return 'Unknown';
    }
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final localDate = date.toLocal();
    return '${months[localDate.month - 1]} ${localDate.day}, ${localDate.year}';
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary.withValues(alpha: 0.4),
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    iconColor?.withValues(alpha: 0.1) ??
                    AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor ?? AppTheme.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor ?? AppTheme.primary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color:
                  iconColor?.withValues(alpha: 0.4) ??
                  AppTheme.primary.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuContentItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required IconData trailingIcon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.primary.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Icon(trailingIcon, color: AppTheme.primary.withValues(alpha: 0.4)),
        ],
      ),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppTheme.primary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}
