import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;


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
      String email, 
      String password, 
      {Map<String, dynamic>? userMetadata,
    }) async {
      return await _supabase.auth.signUp(
        email: email,
        password: password,
        data: userMetadata,
      );
    }

  // Complete user registration (auth + profile + member records)
  Future<void> completeUserRegistration({
    required String email,
    required String password,
    required String username,
    required String firstName,
    required String lastName,
    required DateTime dateOfBirth,
    required String contactNumber,
  }) async {
    // Step 1: Create auth user first
    final authResponse = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );

    final userId = authResponse.user?.id;
    if (userId == null) {
      throw Exception('Failed to create auth user: ${authResponse.session}');
    }

    try {
      // Step 2: Insert into Profiles table using the auth user ID
      await _supabase.from('Profiles').insert({
        'user_id': userId,
        'username': username,
      });

      // Step 3: Insert into Members table using the auth user ID
      await _supabase.from('Members').insert({
        'user_id': userId,
        'first_name': firstName,
        'last_name': lastName,
        'date_of_birth': dateOfBirth.toIso8601String(),
        'contact_number': int.parse(contactNumber), // Convert to numeric
        'email': email,
      });

    } catch (e) {
      // If database inserts fail, we should clean up the auth user
      await _supabase.auth.signOut();
      throw Exception('Database error saving user profile: $e');
    }
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