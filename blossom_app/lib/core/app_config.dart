class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.diturn.net/api/v1',
  );

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://aophohpfxjnqcxxsqbck.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String passwordRecoveryRedirectUrl = String.fromEnvironment(
    'PASSWORD_RECOVERY_REDIRECT_URL',
    defaultValue:
        'https://olive-woodpecker-648529.hostingersite.com/password-recovery',
  );

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
