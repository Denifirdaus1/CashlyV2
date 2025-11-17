class AppEnv {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://kyzhztjcwpswogtzfkwq.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt5emh6dGpjd3Bzd29ndHpma3dxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzNjA1NjIsImV4cCI6MjA3ODkzNjU2Mn0.DNhd6LonaYStrjzk3rr6urxIXtUS_G7z9yMPNML26js',
  );
}
