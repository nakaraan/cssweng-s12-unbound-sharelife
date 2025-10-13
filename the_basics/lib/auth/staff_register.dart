import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_basics/auth/auth_service.dart';
import 'package:the_basics/widgets/auth_navbar.dart';
import 'package:the_basics/utils/profile_storage.dart';
import 'package:the_basics/main.dart';

class StaffRegisterPage extends StatefulWidget {
  const StaffRegisterPage({super.key});

  @override
  State<StaffRegisterPage> createState() => _StaffRegisterPageState();
}

class _StaffRegisterPageState extends State<StaffRegisterPage> {
  // get auth service
  final authService = AuthService();

  // text controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _usernameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _showConfirmPassword = false;
  

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      final shouldShow = _passwordController.text.isNotEmpty;
      if (shouldShow != _showConfirmPassword) {
        setState(() => _showConfirmPassword = shouldShow);
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dateOfBirthController.dispose();
    _usernameController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void createStaffAccount() async {
    final email = _emailController.text.trim().toLowerCase();
    final username = _usernameController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final contactNo = _contactNumberController.text.trim();
    final dateOfBirth = _dateOfBirthController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // INPUT VALIDATION //
    if (email.isEmpty || username.isEmpty || firstName.isEmpty || lastName.isEmpty || contactNo.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields.")));
      return;
    }

    // Validate email
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a valid email address.")));
      return;
    }

    // Convert DOB to ISO if possible (reuse logic from register.dart)
    String dobIso = '';
    if (dateOfBirth.isNotEmpty) {
      try {
        final parts = dateOfBirth.split('/');
        if (parts.length == 3) {
          final dt = DateTime(int.parse(parts[2]), int.parse(parts[0]), int.parse(parts[1]));
          dobIso = dt.toIso8601String().split('T')[0];
        }
      } catch (_) {}
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Passwords don't match")));
      return;
    }

    // Check if user exists
    try {
      final userExists = await authService.checkUserExists(email, username: username);
      if (userExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User with this email or username already exists."))
        );
        return;
      }
    } catch (e) {
      debugPrint('Error checking user existence: $e');
    }

    try {
      // Use new staffSignUp so we reuse pending-profile flow (no edge function)
      final response = await authService.staffSignUp(
        email,
        password,
        username: username,
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dobIso,
        contactNo: contactNo,
        role: 'encoder',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Staff invited! Please check email to complete registration."))
      );

      // Go back to admin dashboard
      Navigator.of(context).pop();

    } on AuthException catch (authErr) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${authErr.message}")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: Column(
        children: [
          const AuthNavBar(hideAuthButtons: true, showBackButton: true,),
          Expanded(
            child: Center(
              child: Container(
          width: 800,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Two groups side by side
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group 1: Personal Information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        TextField(
                          controller: _firstNameController,
                          decoration: InputDecoration(
                            labelText: 'First Name',
                            border: OutlineInputBorder(),
                            hintText: 'First Name',
                          ),
                        ),
                        const SizedBox(height: 15),
                        
                        TextField(
                          controller: _lastNameController,
                          decoration: InputDecoration(
                            labelText: 'Last Name',
                            border: OutlineInputBorder(),
                            hintText: 'Last Name',
                          ),
                        ),
                        const SizedBox(height: 15),
                        
                        TextField(
                          controller: _dateOfBirthController,
                          decoration: InputDecoration(
                            labelText: 'Date of Birth',
                            border: OutlineInputBorder(),
                            hintText: 'MM/DD/YYYY',
                          ),
                        ),
                        const SizedBox(height: 15),
                        
                        TextField(
                          controller: _contactNumberController,
                          decoration: InputDecoration(
                            labelText: 'Contact Number',
                            border: OutlineInputBorder(),
                            hintText: '09XX XXX XXXX',
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 30),
                  
                  // Group 2: Log In Information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Log In Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Username',
                            border: OutlineInputBorder(),
                            hintText: 'Username'
                          ),
                        ),
                        const SizedBox(height: 15),

                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            border: OutlineInputBorder(),
                            hintText: 'Email Address'
                          ),
                        ),
                        const SizedBox(height: 15),
                        
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                            hintText: 'Password'
                          ),
                        ),
                        const SizedBox(height: 15),
                        
                        // Animated fade for Confirm Password
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(opacity: animation, child: child),
                          child: _showConfirmPassword
                              ? TextField(
                                  key: const ValueKey('confirm_field'),
                                  controller: _confirmPasswordController,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Confirm Password',
                                    border: OutlineInputBorder(),
                                    hintText: 'Confirm Password',
                                  ),
                                )
                              : const SizedBox(
                                  key: ValueKey('confirm_empty'),
                                  height: 0,
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Remember me checkbox
              Row(
                children: [
                  Checkbox(
                    value: false,
                    onChanged: (value) {},
                  ),
                  const Text('Remember me?'),
                ],
              ),
              const SizedBox(height: 20),
              
              // Register button
              ElevatedButton(
                onPressed: createStaffAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C0C0D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ],
      ),
    );
  }
}