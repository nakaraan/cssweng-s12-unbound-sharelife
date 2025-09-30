import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Test connection to Supabase
  Future<bool> testConnection() async {
    try {
      print('Testing Supabase connection...');
      
      // Simple health check - try to get session (doesn't require auth)
      final session = _supabase.auth.currentSession;
      if (session != null) {
        print('Connection test successful. Current session: ${session.user.id}');
      } else {
        print('Connection test successful. No current session.');
      }
      return true;
    } catch (e) {
      print('Connection test failed: $e');
      print('Error type: ${e.runtimeType}');
      return false;
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signInWithEmailPassword(
    String email, String password) async {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password
      );
    }
  
  // Sign up with email and password
  Future<AuthResponse> signUpWithEmailPassword(
      String email, String password, ) async {
      return await _supabase.auth.signUp(
        email: email,
        password: password,
      );
    }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Get user email
  String? getCurrentUserEmail() {
    final session = _supabase.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }
  
}