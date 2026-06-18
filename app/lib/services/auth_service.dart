import 'package:supabase_flutter/supabase_flutter.dart';

final _supabase = Supabase.instance.client;

class AuthService {
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

  static Future<AuthResponse> login(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  static User? get currentUser => _supabase.auth.currentUser;

  static String? get currentUserId => _supabase.auth.currentUser?.id;

  static Stream<AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;
}
