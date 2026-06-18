import 'package:supabase_flutter/supabase_flutter.dart';

final _supabase = Supabase.instance.client;

class AuthService {
  // Kayıt ol
  static Future<AuthResponse> register(
      String email, String password, String fullName) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );

    if (response.user != null) {
      await _supabase.from('users').insert({
        'id': response.user!.id,
        'email': email,
        'full_name': fullName,
      });
    }

    return response;
  }

  // Giriş yap
  static Future<AuthResponse> login(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Çıkış yap
  static Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // Giriş yapılı mı?
  static User? get currentUser => _supabase.auth.currentUser;

  // Kullanıcı ID'si
  static String? get currentUserId => _supabase.auth.currentUser?.id;

  // Auth durumu değişikliklerini dinle
  static Stream<AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;
}
