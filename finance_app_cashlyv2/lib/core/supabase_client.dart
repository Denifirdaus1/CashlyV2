import 'package:supabase_flutter/supabase_flutter.dart';

import 'env.dart';

class SupabaseManager {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      anonKey: AppEnv.supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
