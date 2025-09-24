class AppConfig {
  const AppConfig._();

  /// Base URL for the Supabase project. Provide this value at build time using
  /// `--dart-define SUPABASE_URL=...` or replace the default with your
  /// project's URL.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  /// Anonymous key for the Supabase project. Provide this value at build time
  /// using `--dart-define SUPABASE_ANON_KEY=...`.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
}
