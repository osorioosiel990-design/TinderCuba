import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Registration with email and password
  static Future<AuthResponse> signUp(String email, String password) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  // Login with email and password
  static Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  // Sign out
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Get current user
  static User? getCurrentUser() {
    return _client.auth.currentUser;
  }
}
