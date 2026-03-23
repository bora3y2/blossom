import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/app_session.dart';
import '../models/add_plant_models.dart';
import '../models/ai_models.dart';
// Import screens
import '../screens/auth/sign_up_screen.dart';
import '../screens/auth/log_in_screen.dart';
import '../screens/main/garden_home_screen.dart';
import '../screens/main/garden_plant_detail_screen.dart';
import '../screens/main/my_garden_screen.dart';
import '../screens/main/community_feed_screen.dart';
import '../screens/main/profile_screen.dart';
import '../screens/add_plant/add_plant_step_1.dart';
import '../screens/add_plant/add_plant_step_2.dart';
import '../screens/add_plant/add_plant_step_3.dart';
import '../screens/add_plant/ai_identify_result_screen.dart';
import '../screens/add_plant/ai_identify_screen.dart';
import '../screens/main/change_password_screen.dart';
import '../screens/main/upload_post_screen.dart';
import '../screens/main/comments_feed_screen.dart';
import '../screens/main/edit_profile_screen.dart';
import '../widgets/main_layout.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final shellNavigatorMyGardenKey = GlobalKey<NavigatorState>(
  debugLabel: 'myGarden',
);
final shellNavigatorCommunityKey = GlobalKey<NavigatorState>(
  debugLabel: 'community',
);
final shellNavigatorProfileKey = GlobalKey<NavigatorState>(
  debugLabel: 'profile',
);

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  refreshListenable: appSession,
  initialLocation: '/login',
  redirect: (context, state) {
    final isRecoveryRoute = state.matchedLocation == '/password-recovery';
    final isAuthRoute =
        state.matchedLocation == '/login' || state.matchedLocation == '/signup';
    if (!appSession.initialized) {
      return null;
    }
    if (appSession.isPasswordRecovery && !isRecoveryRoute) {
      return '/password-recovery';
    }
    if (isRecoveryRoute && !appSession.isPasswordRecovery) {
      return appSession.isAuthenticated ? '/garden' : '/login';
    }
    if (!appSession.isAuthenticated && !isAuthRoute) {
      return '/login';
    }
    if (appSession.isAuthenticated && isAuthRoute) {
      return '/home';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LogInScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),
    GoRoute(
      path: '/add_plant_1',
      builder: (context, state) => const AddPlantStep1Screen(),
    ),
    GoRoute(
      path: '/add_plant_2',
      builder: (context, state) =>
          AddPlantStep2Screen(draft: state.extra as AddPlantDraft?),
    ),
    GoRoute(
      path: '/add_plant_3',
      builder: (context, state) =>
          AddPlantStep3Screen(selection: state.extra as AddPlantSelectionArgs?),
    ),
    GoRoute(
      path: '/ai_identify',
      builder: (context, state) =>
          AiIdentifyScreen(args: state.extra as AiIdentifyArgs?),
    ),
    GoRoute(
      path: '/ai_identify_result',
      builder: (context, state) =>
          AiIdentifyResultScreen(args: state.extra as AiIdentifyResultArgs?),
    ),
    GoRoute(
      path: '/change_password',
      builder: (context, state) => const ChangePasswordScreen(),
    ),
    GoRoute(
      path: '/password-recovery',
      builder: (context, state) =>
          const ChangePasswordScreen(isRecoveryMode: true),
    ),
    GoRoute(
      path: '/upload_post',
      builder: (context, state) => const UploadPostScreen(),
    ),
    GoRoute(
      path: '/comments_feed',
      builder: (context, state) =>
          CommentsFeedScreen(postId: state.extra as String?),
    ),
    GoRoute(
      path: '/my_garden',
      builder: (context, state) => const MyGardenScreen(),
    ),
    GoRoute(
      path: '/garden_plant/:userPlantId',
      builder: (context, state) => GardenPlantDetailScreen(
        userPlantId: state.pathParameters['userPlantId']!,
      ),
    ),
    GoRoute(
      path: '/edit_profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainLayout(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: shellNavigatorCommunityKey,
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const CommunityFeedScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: shellNavigatorHomeKey,
          routes: [
            GoRoute(
              path: '/garden',
              builder: (context, state) => const GardenHomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: shellNavigatorProfileKey,
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
