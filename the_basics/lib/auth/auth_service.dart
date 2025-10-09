import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:the_basics/utils/profile_storage.dart';

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
  
  final String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRoZ21vdmtpb3Vicml6YWpzdnplIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkyMzk3MzIsImV4cCI6MjA3NDgxNTczMn0.PBXfbH3n7yTVwZs_e9li_U9F8YirKTl4Wl3TVr1o0gw';
  
  // Sign up, saves profile locally until email confirmed
  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password, {
    required String username,
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    required String contactNo,
  }) async {
    
    // Save profile data locally before signup
    await ProfileStorage.savePendingProfile({
      'email': email.trim().toLowerCase(),
      'username': username.trim(),
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'date_of_birth': dateOfBirth.trim(),
      'contact_no': contactNo.trim(),
    });

    // Only do the auth signup - no members table insert yet
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    return response;
  }

  // Claim pending profile after authentication
  Future<void> tryClaimPendingProfile({int maxRetries = 3}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final pending = await ProfileStorage.getPendingProfile();
    if (pending == null) return;

    final row = <String, dynamic>{
      'email_address': pending['email'] ?? user.email,
      'username': pending['username'],
      'first_name': pending['first_name'],
      'last_name': pending['last_name'],
      'contact_no': pending['contact_no'],
      'date_of_birth': pending['date_of_birth'],
    };

    for (var attempt = 0; attempt < maxRetries; attempt++) {
      try {
        // Check if member already exists by email
        final existing = await _supabase
            .from('members')
            .select('id, email_address')
            .eq('email_address', row['email_address'])
            .maybeSingle();

        if (existing != null && existing['id'] != null) {
          // Update existing member (in case they already have a partial record)
          await _supabase
              .from('members')
              .update(row)
              .eq('id', existing['id']);
        } else {
          // Insert new member
          await _supabase.from('members').insert(row);
        }

        // Success - clear pending profile
        await ProfileStorage.clearPendingProfile();
        return;

      } catch (e) {
        if (attempt < maxRetries - 1) {
          await Future.delayed(Duration(seconds: 1 << attempt));
          continue;
        } else {
          // Don't clear pending profile on failure - user can try again later
          return;
        }
      }
    }
  }



  final String endpoint = "https://thgmovkioubrizajsvze.supabase.co/functions/v1/check-user-exists";

// ...existing code...
  Future<bool> checkUserExists(String email) async {
    final trimmed = email.trim().toLowerCase();

    final payload = {'email': trimmed};

    try {
      final dynamic fnResp = await _supabase.functions.invoke(
        'check-user-exists',
        body: payload,
      );

      if (fnResp == null) {
        return false;
      }

      if (fnResp is Map<String, dynamic>) {
        final exists = fnResp['exists'] == true;
        return exists;
      }

      if (fnResp is String) {
        try {
          final Map<String, dynamic> body = jsonDecode(fnResp);
          final exists = body['exists'] == true;
          return exists;
        } catch (parseErr, st) {
          return false;
        }
      }
      return false;
    } catch (e, st) {
      return false;
    }
  }
// ...existing code...
  

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
  

  // ADMIN-CREATION METHODS
  // STAFF SIGNUP SYSTEM
  // Sign up, saves staff profile locally until email confirmed
  // Inside AuthService class
  Future<Map<String, dynamic>> createStaff({
    required String email,
    required String username,
    required String firstName,
    required String lastName,
    required String contactNo,
    String? dateOfBirth,
    String role = 'staff',
  }) async {
    try {
      // Normalize and validate email
      final normalizedEmail = email.trim().toLowerCase();
      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(normalizedEmail)) {
        throw Exception('Invalid email address');
      }

      final payload = {
        'email_address': normalizedEmail,
        'username': username.trim(),
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'contact_no': contactNo.trim(),
        'date_of_birth': dateOfBirth?.trim(),
        'role': role.trim(),
      };

      // Remove null/empty date_of_birth to avoid DB errors
      if (payload['date_of_birth'] == null || payload['date_of_birth']!.isEmpty) {
        payload.remove('date_of_birth');
      }

      // Invoke Edge Function
      final dynamic response = await _supabase.functions.invoke(
        'create-staff',
        body: payload,
      );

      // Handle response
      if (response is Map<String, dynamic>) {
        return response;
      } else {
        throw Exception('Unexpected response format from create-staff function');
      }
    } catch (e) {
      // Re-throw with clearer message
      if (e.toString().contains('CORS')) {
        throw Exception('CORS error: Check Supabase CORS settings for localhost');
      }
      throw Exception('Failed to create staff: ${e.toString()}');
    }
  }

}