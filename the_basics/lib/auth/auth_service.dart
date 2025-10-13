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
    String input_credential, String password) async {
    String? email_credential;

    print('[signIn] input credential: $input_credential');

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(input_credential)) {
      // input is not an email (treat as username)
      print('[signIn] Detected username input. Looking up email by username...');
      try {
        final userByUsername = await _supabase
            .from('staff')
            .select('email_address')
            .eq('username', input_credential)
            .maybeSingle();

        print('[signIn] userByUsername result: $userByUsername');

        final staffByUsername = await _supabase
            .from('staff')
            .select('email_address')
            .eq('username', input_credential)
            .maybeSingle();

        print('[signIn] staffByUsername result: $staffByUsername');

        if (userByUsername != null && userByUsername['email_address'] != null) {
          email_credential = userByUsername['email_address'];
        } else if (staffByUsername != null && staffByUsername['email_address'] != null) {
          email_credential = staffByUsername['email_address'];
        } else {
          print('[signIn] No user found with that username');
          return Future.error('No user found with that username');
        }
      } catch (e) {
        print('[signIn] Error fetching user by username: $e');
        return Future.error('Error fetching user by username: $e');
      }
    } else {
      // input is an email
      email_credential = input_credential.trim().toLowerCase();
      print('[signIn] Detected email input. Using email: $email_credential');
    }

    print('[signIn] Calling Supabase signInWithPassword for $email_credential');
    try {
      final resp = await _supabase.auth.signInWithPassword(
        email: email_credential,
        password: password,
      );
      print('[signIn] Supabase response: $resp');
      return resp;
    } catch (e) {
      print('[signIn] Supabase signIn error: $e');
      rethrow;
    }
  }

  Future<String?> getUserRole() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final email = user.email!; // null safety

    try {
      final staffRecord = await _supabase
          .from('staff')
          .select('role')
          .eq('email_address', email)
          .maybeSingle();

      if (staffRecord != null && staffRecord['role'] != null) {
        return staffRecord['role'] as String;
      }

      final memberRecord = await _supabase
          .from('members')
          .select('role')
          .eq('email_address', email)
          .maybeSingle();

      return memberRecord?['role'] as String?;
    } catch (e) {
      print("Error fetching user role: $e");
      return null;
    }
  }

  final String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRoZ21vdmtpb3Vicml6YWpzdnplIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkyMzk3MzIsImV4cCI6MjA3NDgxNTczMn0.PBXfbH3n7yTVwZs_e9li_U9F8YirKTl4Wl3TVr1o0gw';
  
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
      'role': 'member', // mark as member so claim logic knows where to insert
    });

    // Only do the auth signup - no members table insert yet
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    return response;
  }

  // NEW: Staff sign up using same pending-profile flow as members
  Future<AuthResponse> staffSignUp(
    String email,
    String password, {
    required String username,
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    required String contactNo,
    String role = 'encoder',
  }) async {
    // Save staff profile data locally before signup (include role)
    print('[staffSignUp] Saving pending staff profile for: $email, role: $role');
    await ProfileStorage.savePendingProfile({
      'email': email.trim().toLowerCase(),
      'username': username.trim(),
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'date_of_birth': dateOfBirth.trim(),
      'contact_no': contactNo.trim(),
      'role': role.trim(), // important for claim step
    });

    // Use Supabase auth signUp (same as member flow)
    print('[staffSignUp] Calling Supabase signUp for: $email');
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

  print('[staffSignUp] Supabase signUp response: ${response.user?.id}, response: $response');
    return response;
  }

  // Claim pending profile after authentication
  Future<void> tryClaimPendingProfile({int maxRetries = 3}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      print('[tryClaimPendingProfile] No current user, aborting.');
      return;
    }

    final pending = await ProfileStorage.getPendingProfile();
    if (pending == null) {
      print('[tryClaimPendingProfile] No pending profile found, aborting.');
      return;
    }

    final role = (pending['role'] ?? 'member').toString().toLowerCase();
    print('[tryClaimPendingProfile] Pending profile: $pending, role: $role');

    // Build common row; will adjust per table below
    final row = <String, dynamic>{
      'email_address': pending['email'] ?? user.email,
      'username': pending['username'],
      'first_name': pending['first_name'],
      'last_name': pending['last_name'],
      'contact_no': pending['contact_no'],
      'date_of_birth': pending['date_of_birth'],
    };

    // Remove empty/null date_of_birth to avoid DB errors (calling code may require non-null)
    if (row['date_of_birth'] == null || (row['date_of_birth'] as String).isEmpty) {
      row.remove('date_of_birth');
    }

    // If staff, ensure role present in row (staff table requires role)
    if (role == 'encoder') {
      row['role'] = pending['role'] ?? 'encoder';
    }

    final targetTable = role == 'encoder' ? 'staff' : 'members';
    print('[tryClaimPendingProfile] Target table: $targetTable, row: $row');

    for (var attempt = 0; attempt < maxRetries; attempt++) {
      try {

        print('[tryClaimPendingProfile] Attempt ${attempt + 1} to insert/update $targetTable for email: ${row['email_address']}');
        // Use checkUserExists to determine if user already exists
        final exists = await checkUserExists(row['email_address'] ?? '');

        if (exists) {
          print('[tryClaimPendingProfile] Existing record found, updating...');
          // Update existing record (by email)
          await _supabase
              .from(targetTable)
              .update(row)
              .eq('email_address', row['email_address']);
          print('[tryClaimPendingProfile] Update successful.');
        } else {
          print('[tryClaimPendingProfile] No existing record, inserting new...');
          // Insert new record
          await _supabase.from(targetTable).insert(row);
          print('[tryClaimPendingProfile] Insert successful.');
        }

        // Success - clear pending profile
        await ProfileStorage.clearPendingProfile();
        print('[tryClaimPendingProfile] Cleared pending profile after successful insert/update.');
        return;

      } catch (e) {
        print('[tryClaimPendingProfile] Error on attempt ${attempt + 1}: $e');
        if (attempt < maxRetries - 1) {
          await Future.delayed(Duration(seconds: 1 << attempt));
          continue;
        } else {
          print('[tryClaimPendingProfile] Max retries reached. Not clearing pending profile.');
          // Don't clear pending profile on failure - admin/user can try again later
          return;
        }
      }
    }
  }

  // Check if user exists before registration
  Future<bool> checkUserExists(String email, {String? username}) async {
    final trimmedEmail = email.trim().toLowerCase();
    final trimmedUsername = username?.trim();

    // If both empty, nothing to check
    if ((trimmedEmail.isEmpty) && (trimmedUsername == null || trimmedUsername.isEmpty)) {
      return false;
    }

    try {
      // Debug
      print('checkUserExists: email="$trimmedEmail" username="$trimmedUsername"');

      // Check by email if provided (email match is already normalized)
      if (trimmedEmail.isNotEmpty) {
        final staffByEmail = await _supabase
            .from('staff')
            .select('id')
            .eq('email_address', trimmedEmail)
            .maybeSingle();
        if (staffByEmail != null) {
          print('checkUserExists: found by email in staff');
          return true;
        }

        final memberByEmail = await _supabase
            .from('members')
            .select('id')
            .eq('email_address', trimmedEmail)
            .maybeSingle();
        if (memberByEmail != null) {
          print('checkUserExists: found by email in members');
          return true;
        }
      }

      // Check by username (case-sensitive)
      if (trimmedUsername != null && trimmedUsername.isNotEmpty) {
        // check staff for username matches (case-sensitive)
        final staffByUsername = await _supabase
            .from('staff')
            .select('id, username, email_address')
            .eq('username', trimmedUsername);
        
        print('staffByUsername raw: $staffByUsername');
        
        if (staffByUsername != null && staffByUsername is List && staffByUsername.isNotEmpty) {
          print('checkUserExists: found by username in staff: $staffByUsername');
          return true;
        }

        // check members for username matches (case-sensitive)
        final memberByUsername = await _supabase
            .from('members')
            .select('id')
            .eq('username', trimmedUsername);
        if (memberByUsername != null && memberByUsername is List && memberByUsername.isNotEmpty) {
          print('checkUserExists: found by username in members: $memberByUsername');
          return true;
        }
      }

      // Not found
      print('checkUserExists: not found');
      return false;
    } catch (e) {
      print('checkUserExists error: $e');
      rethrow;
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
    String role = 'encoder',
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