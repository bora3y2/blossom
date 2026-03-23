import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_config.dart';

final AppSession appSession = AppSession();

class AppSession extends ChangeNotifier {
  SupabaseClient? _client;
  StreamSubscription<AuthState>? _authSubscription;
  bool _initialized = false;
  bool _isBusy = false;
  bool _isPasswordRecovery = false;
  String? _configurationError;

  bool get initialized => _initialized;
  bool get isBusy => _isBusy;
  bool get isConfigured => AppConfig.hasSupabaseConfig;
  bool get isPasswordRecovery => _isPasswordRecovery;
  String? get configurationError => _configurationError;
  SupabaseClient? get client => _client;
  Session? get currentSession => _client?.auth.currentSession;
  String? get accessToken => currentSession?.accessToken;
  String? get currentUserId => currentSession?.user.id;
  String? get currentUserEmail => currentSession?.user.email;
  bool get isAuthenticated => accessToken != null;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    if (!isConfigured) {
      _configurationError = 'Missing Supabase configuration.';
      _initialized = true;
      notifyListeners();
      return;
    }
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
    _authSubscription = _client!.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        _isPasswordRecovery = true;
      } else if (data.event == AuthChangeEvent.signedOut) {
        _isPasswordRecovery = false;
      }
      notifyListeners();
    });
    _initialized = true;
    notifyListeners();
  }

  Future<void> signIn({required String email, required String password}) async {
    final client = _requireClient();
    _setBusy(true);
    try {
      await client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (error) {
      throw AppSessionException(error.message);
    } finally {
      _setBusy(false);
    }
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final client = _requireClient();
    _setBusy(true);
    try {
      await client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
    } on AuthException catch (error) {
      throw AppSessionException(error.message);
    } finally {
      _setBusy(false);
    }
  }

  Future<void> signOut() async {
    final client = _requireClient();
    await client.auth.signOut();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final client = _requireClient();
    final email = currentUserEmail;
    if (email == null || email.isEmpty) {
      throw const AppSessionException('Unable to verify your current account.');
    }
    _setBusy(true);
    try {
      await client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );
      await client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (error) {
      throw AppSessionException(error.message);
    } finally {
      _setBusy(false);
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    final client = _requireClient();
    final redirectTo = AppConfig.passwordRecoveryRedirectUrl.trim();
    _setBusy(true);
    try {
      await client.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectTo.isEmpty ? null : redirectTo,
      );
    } on AuthException catch (error) {
      throw AppSessionException(error.message);
    } finally {
      _setBusy(false);
    }
  }

  Future<void> updatePasswordFromRecovery({required String newPassword}) async {
    final client = _requireClient();
    _setBusy(true);
    try {
      await client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (error) {
      throw AppSessionException(error.message);
    } finally {
      _setBusy(false);
    }
  }

  void clearPasswordRecovery() {
    if (!_isPasswordRecovery) {
      return;
    }
    _isPasswordRecovery = false;
    notifyListeners();
  }

  SupabaseClient _requireClient() {
    if (!isConfigured) {
      throw const AppSessionException(
        'Set SUPABASE_URL and SUPABASE_ANON_KEY with --dart-define.',
      );
    }
    final client = _client;
    if (client == null) {
      throw const AppSessionException('Supabase is not initialized yet.');
    }
    return client;
  }

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

class AppSessionScope extends InheritedNotifier<AppSession> {
  const AppSessionScope({
    required AppSession session,
    required super.child,
    super.key,
  }) : super(notifier: session);

  static AppSession of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppSessionScope>();
    if (scope == null || scope.notifier == null) {
      throw StateError('AppSessionScope is missing.');
    }
    return scope.notifier!;
  }
}

class AppSessionException implements Exception {
  const AppSessionException(this.message);

  final String message;

  @override
  String toString() => message;
}
