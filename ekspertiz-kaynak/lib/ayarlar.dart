/// Derleme sırasında --dart-define ile verilir (kurulum.bat ayarlar.env dosyasından okur).
class Ayarlar {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static bool get demoModu => supabaseUrl.isEmpty || supabaseAnonKey.isEmpty;
}
