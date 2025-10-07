import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_basics/auth/auth_service.dart';
import 'package:the_basics/auth/login.dart';
import 'package:the_basics/widgets/auth_navbar.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
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

  void signUp() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final username = _usernameController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final dateOfBirth = _dateOfBirthController.text.trim();
    final contactNo = _contactNumberController.text.trim();


    // INPUT VALIDATION //
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty || username.isEmpty || firstName.isEmpty || lastName.isEmpty || dateOfBirth.isEmpty || contactNo.isEmpty) {
      ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Please fill in all fields.")));
      return;
    }

    String dobIso = '';
    if (dateOfBirth.isNotEmpty) {
      try {
        final dobParts = dateOfBirth.split('/');
        if (dobParts.length == 3) {
          final month = int.parse(dobParts[0]);
          final day = int.parse(dobParts[1]);
          final year = int.parse(dobParts[2]);
          final dt = DateTime(year, month, day);
          dobIso = dt.toIso8601String().split('T')[0];
        }
      } catch (_) {
        dobIso = '';
      }
    }
    if (email.isNotEmpty && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Please enter a valid email address.")));
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Passwords don't match")));
      return;
    }

    // Check if user exists
    try {
      final userExists = await authService.checkUserExists(email);
      if (userExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User with this email already exists."))
        );
        return;
      }
    } catch (e) {
      debugPrint('Error checking user existence: $e');
    }

    try {
      // Sign up with profile data saved locally
      final response = await authService.signUpWithEmailPassword(
        email, 
        password,
        username: username,
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dobIso,
        contactNo: contactNo,
      );

      if (response.user != null) {
        // Show success message and redirect to login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please check your email to confirm your registration. Your profile will be completed automatically when you click the confirmation link."))
        );
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => LoginPage(),
              transitionDuration: const Duration(milliseconds: 150),
              reverseTransitionDuration: const Duration(milliseconds: 150),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            )
          );
        }
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sign up did not complete. Please try again."))
      );

    } on AuthException catch (authError) {
      final errMsg = authError.message.toLowerCase() ?? '';
      if (errMsg.contains('already registered') ||
          errMsg.contains('already exists') ||
          errMsg.contains('user already registered') ||
          (errMsg.contains('duplicate') && errMsg.contains('email')) ||
          (errMsg.contains('email') && errMsg.contains('exists'))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User with this email already exists."))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sign up error: ${authError.message}"))
        );
      }
    } catch (e) {
      final err = e.toString().toLowerCase();
      if (err.contains('already registered') ||
          err.contains('already exists') ||
          err.contains('user already registered') ||
          err.contains('duplicate') && err.contains('email')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User with this email already exists."))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: Column(
        children: [
          const AuthNavBar(),
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
                onPressed: signUp,
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