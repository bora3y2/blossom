import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/app_session.dart';
import 'core/theme.dart';
import 'router/app_router.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<String>('garden_cache');
  await notificationService.init();
  await appSession.initialize();
  runApp(const BlossomApp());
}

class BlossomApp extends StatelessWidget {
  const BlossomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSessionScope(
      session: appSession,
      child: MaterialApp.router(
        title: 'Blossom App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: appRouter,
      ),
    );
  }
}
