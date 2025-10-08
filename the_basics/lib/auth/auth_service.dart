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
          print('Updated existing member profile');
        } else {
          // Insert new member
          await _supabase.from('members').insert(row);
          print('Inserted new member profile');
        }

        // Success - clear pending profile
        await ProfileStorage.clearPendingProfile();
        print('Member profile claimed successfully');
        return;

      } catch (e) {
        print('Attempt ${attempt + 1} failed: $e');
        if (attempt < maxRetries - 1) {
          await Future.delayed(Duration(seconds: 1 << attempt));
          continue;
        } else {
          print('Failed to claim pending profile after $maxRetries attempts: $e');
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
    print('checkUserExists: entered with email="$trimmed"');

    final payload = {'email': trimmed};
    print('checkUserExists: invoking function "check-user-exists" with payload: $payload');

    try {
      final dynamic fnResp = await _supabase.functions.invoke(
        'check-user-exists',
        body: payload,
      );

      print('checkUserExists: raw fnResp: $fnResp (type: ${fnResp.runtimeType})');

      if (fnResp == null) {
        print('checkUserExists: fnResp is null -> returning false');
        return false;
      }

      if (fnResp is Map<String, dynamic>) {
        final exists = fnResp['exists'] == true;
        print('checkUserExists: parsed Map -> exists=$exists, fullResp=$fnResp');
        return exists;
      }

      if (fnResp is String) {
        try {
          final Map<String, dynamic> body = jsonDecode(fnResp);
          final exists = body['exists'] == true;
          print('checkUserExists: parsed String->JSON -> exists=$exists, body=$body');
          return exists;
        } catch (parseErr, st) {
          print('checkUserExists: failed to parse string response: $parseErr\n$st');
          return false;
        }
      }

      print('checkUserExists: unexpected response type -> returning false');
      return false;
    } catch (e, st) {
      print('Could not check user existence: $e\n$st');
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
  Future<AuthResponse> signUpStaffWithEmailPassword(
    String email,
    String password, {
    required String username,
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    required String contactNo,
    required String role, //'Approver' or 'Encoder'
  }) async {
    // Save staff profile data locally before signup
    await ProfileStorage.savePendingProfile({
      'email': email.trim().toLowerCase(),
      'username': username.trim(),
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'date_of_birth': dateOfBirth.trim(),
      'contact_no': contactNo.trim(),
      'role': role.trim(),
    });

    // Only do the auth signup - no staff table insert yet
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    return response;
  }

  // Claim pending staff profile after authentication
  Future<void> tryClaimPendingStaffProfile({int maxRetries = 3}) async {
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
      'role': pending['role'],
    };

    for (var attempt = 0; attempt < maxRetries; attempt++) {
      try {
        // Check if staff already exists by email
        final existing = await _supabase
            .from('staff')
            .select('id, email_address')
            .eq('email_address', row['email_address'])
            .maybeSingle();

        if (existing != null && existing['id'] != null) {
          // Update existing staff (in case they already have a partial record)
          await _supabase
              .from('staff')
              .update(row)
              .eq('id', existing['id']);
          print('Updated existing staff profile');
        } else {
          // Insert new staff
          await _supabase.from('staff').insert(row);
          print('Inserted new staff profile');
        }

        // Success - clear pending profile
        await ProfileStorage.clearPendingProfile();
        print('Staff profile claimed successfully');
        return;

      } catch (e) {
        print('Attempt [${attempt + 1}] failed: $e');
        if (attempt < maxRetries - 1) {
          await Future.delayed(Duration(seconds: 1 << attempt));
          continue;
        } else {
          print('Failed to claim pending staff profile after $maxRetries attempts: $e');
          // Don't clear pending profile on failure - user can try again later
          return;
        }
      }
    }
  }
  // 

}