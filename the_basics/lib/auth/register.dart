import 'package:flutter/material.dart';
import 'package:the_basics/auth/auth_service.dart';
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
  // final _usernameController = TextEditingController();
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
    // _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
/*
  // sign up button pressed
  void signUp() async {
    // prepare data
    // final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
/*
  // validate username: non-empty, 3-30 chars, allowed: letters
  final usernameRegex = RegExp(r'^[a-zA-Z0-9._-]{3,30}$');
  if (username.isEmpty || !usernameRegex.hasMatch(username)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Invalid username. Use 3-30 characters: letters, numbers, ., _, -',
        ),
      ),
    );
    return;
  }
*/
  //check if the passwords match
  if (password != confirmPassword) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords don't match")));
    return;
  }

  // check if password fits supabase requirements
  if (password.length < 6) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Password must be at least 6 characters")),
    );
    return;
  }
/*
  //attempt sign up..
  try {
    // Test connection first
    print('Testing connection before registration...');
    final connectionOk = await authService.testConnection();
    if (!connectionOk) {
      throw Exception('Cannot connect to Supabase server. Please check your internet connection.');
    }

    // Use the complete registration method with dummy data for now
    await authService.completeUserRegistration(
      email: email,
      password: password,
      username: username,
      firstName: 'Test', // You can add text fields for these later
      lastName: 'User',
      dateOfBirth: DateTime(1990, 1, 1), // Default date
      contactNumber: '1234567890', // Default number
    );

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration successful!")),
      );
      Navigator.pop(context);
    }
  } catch (e) {
    if (mounted) {
      // Print detailed error to console
      print('Registration error: $e');
      print('Error type: ${e.runtimeType}');
      
      // Show detailed error in a dialog
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Registration Error'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Error details:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('$e'),
                const SizedBox(height: 16),
                const Text('Check the console for more details.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      
      // Also show a snackbar for quick reference
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration failed: ${e.toString().substring(0, 100)}...")),
      );
    }
  } 
              */

  }
  */

  void signUp() async {
    // prepare data
    final email = _emailController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;


    // check that passwords match
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Passwords don't match")));
      return;
    }

    // attempt sign up...
    try {
      await authService.signUpWithEmailPassword(email, password);

      if (mounted) {
        Navigator.pop(context);
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
        return;
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
                        
                        const TextField(
                          decoration: InputDecoration(
                            labelText: 'First Name',
                            border: OutlineInputBorder(),
                            hintText: 'First Name',
                          ),
                        ),
                        const SizedBox(height: 15),
                        
                        const TextField(
                          decoration: InputDecoration(
                            labelText: 'Last Name',
                            border: OutlineInputBorder(),
                            hintText: 'Last Name',
                          ),
                        ),
                        const SizedBox(height: 15),
                        
                        const TextField(
                          decoration: InputDecoration(
                            labelText: 'Date of Birth',
                            border: OutlineInputBorder(),
                            hintText: 'MM/DD/YYYY',
                          ),
                        ),
                        const SizedBox(height: 15),
                        
                        const TextField(
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
                          // controller: _usernameController,
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