import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_basics/auth/auth_service.dart';
import 'package:the_basics/auth/login.dart';
import 'package:the_basics/core/widgets/auth_navbar.dart';
import 'package:the_basics/core/utils/themes.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final authService = AuthService();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _usernameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showConfirmPassword = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      final shouldShow = _passwordController.text.isNotEmpty;
      if (shouldShow != _showConfirmPassword) setState(() => _showConfirmPassword = shouldShow);
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

    // Basic required fields (including DOB)
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty || username.isEmpty || firstName.isEmpty || lastName.isEmpty || contactNo.isEmpty || dateOfBirth.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill in all required fields.")));
      return;
    }

    // Parse and validate DOB (required)
    String dobIso = '';
    try {
      final parts = dateOfBirth.split('/');
      if (parts.length != 3) throw FormatException('invalid');
      final month = int.parse(parts[0]);
      final day = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      final dt = DateTime(year, month, day);
      final now = DateTime.now();
      if (!(dt.year == year && dt.month == month && dt.day == day)) throw FormatException('invalid');
      if (dt.isAfter(now)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Date of birth can't be in the future.")));
        return;
      }
      int age = now.year - dt.year;
      if (now.month < dt.month || (now.month == dt.month && now.day < dt.day)) age -= 1;
      if (age < 18) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must be at least 18 years old to register.')));
        return;
      }
      dobIso = dt.toIso8601String().split('T')[0];
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter date of birth in MM/DD/YYYY format.')));
      return;
    }

    if (email.isNotEmpty && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a valid email address.")));
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords don't match")));
      return;
    }

    // Validate password against central policy
    final pwErr = authService.validatePassword(password);
    if (pwErr != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pwErr)));
      return;
    }

    // Validate contact number: allow optional leading '+' and 7-15 digits
    final normalizedContact = contactNo.replaceAll(RegExp(r'[\s\-()]'), '');
    if (!RegExp(r'^\+?\d{7,15}$').hasMatch(normalizedContact)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid contact number (7-15 digits, optional leading +).')));
      return;
    }

    // Check if user exists
    try {
      final userExists = await authService.checkUserExists(email, username: username);
      if (userExists) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User with this email or username already exists.")));
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please check your email to confirm your registration. Your profile will be completed automatically when you click the confirmation link.")));
        if (mounted) {
          Navigator.of(context).pushReplacement(PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) => LoginPage(), transitionDuration: const Duration(milliseconds: 150), reverseTransitionDuration: const Duration(milliseconds: 150), transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          }));
        }
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sign up did not complete. Please try again.")));
    } on AuthException catch (authError) {
      final errMsg = authError.message.toLowerCase();
      if (errMsg.contains('already registered') || errMsg.contains('already exists') || errMsg.contains('user already registered') || (errMsg.contains('duplicate') && errMsg.contains('email')) || (errMsg.contains('email') && errMsg.contains('exists'))) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User with this email already exists.")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sign up error: ${authError.message}")));
      }
    } catch (e) {
      final err = e.toString().toLowerCase();
      if (err.contains('already registered') || err.contains('already exists') || err.contains('user already registered') || err.contains('duplicate') && err.contains('email')) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User with this email already exists.")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
    decoration: BoxDecoration(
      image: DecorationImage(
        image: AssetImage("assets/imgs/bg_out.png"),
        fit: BoxFit.fill,
      ),
    ),
    child: Column(
        children: [
          const AuthNavBar(),
          Expanded(
            child: Center(
              child: Container(
          width: 800,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: AppThemes.lightcreme,
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
                            color: AppThemes.orange,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        TextField(
                          controller: _firstNameController,
                          style: TextStyle(color: AppThemes.brown),
                          decoration: InputDecoration(
                            labelText: 'First Name',
                            labelStyle: TextStyle(color: AppThemes.authFieldName),
                            border: OutlineInputBorder(),
                            hintText: 'First Name',
                          ),
                        ),
                        const SizedBox(height: 15),
                        
                        TextField(
                          controller: _lastNameController,
                          style: TextStyle(color: AppThemes.brown),
                          decoration: InputDecoration(
                            labelText: 'Last Name',
                            labelStyle: TextStyle(color: AppThemes.authFieldName),
                            border: OutlineInputBorder(),
                            hintText: 'Last Name',
                          ),
                        ),
                        const SizedBox(height: 15),
                        
                        TextField(
                          controller: _dateOfBirthController,
                          style: TextStyle(color: AppThemes.brown),
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Date of Birth',
                            labelStyle: TextStyle(color: AppThemes.authFieldName),
                            border: OutlineInputBorder(),
                            hintText: 'MM/DD/YYYY',
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          onTap: () async {
                            final now = DateTime.now();
                            DateTime initialDate = now;
                            try {
                              final parts = _dateOfBirthController.text.split('/');
                              if (parts.length == 3) {
                                final month = int.parse(parts[0]);
                                final day = int.parse(parts[1]);
                                final year = int.parse(parts[2]);
                                initialDate = DateTime(year, month, day);
                              }
                            } catch (_) {}

                            final picked = await showDatePicker(
                              context: context,
                              initialDate: initialDate,
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );

                            if (picked != null) {
                              final formatted = '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
                              setState(() {
                                _dateOfBirthController.text = formatted;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 15),
                        
                        TextField(
                          controller: _contactNumberController,
                          style: TextStyle(color: AppThemes.brown),
                          decoration: InputDecoration(
                            labelText: 'Contact Number',
                            labelStyle: TextStyle(color: AppThemes.authFieldName),
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
                            color: AppThemes.orange,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        TextField(
                          controller: _usernameController,
                          style: TextStyle(color: AppThemes.brown),
                          decoration: InputDecoration(
                            labelText: 'Username',
                            labelStyle: TextStyle(color: AppThemes.authFieldName),
                            border: OutlineInputBorder(),
                            hintText: 'Username'
                          ),
                        ),
                        const SizedBox(height: 15),

                        TextField(
                          controller: _emailController,
                          style: TextStyle(color: AppThemes.brown),
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            labelStyle: TextStyle(color: AppThemes.authFieldName),
                            border: OutlineInputBorder(),
                            hintText: 'Email Address'
                          ),
                        ),
                        const SizedBox(height: 15),
                        
                        TextField(
                          controller: _passwordController,
                          style: TextStyle(color: AppThemes.brown),
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(color: AppThemes.authFieldName),
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
                                  style: TextStyle(color: AppThemes.brown),
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Confirm Password',
                                    labelStyle: TextStyle(color: AppThemes.authFieldName),
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
                  Theme(
                    data: Theme.of(context).copyWith(
                      checkboxTheme: CheckboxThemeData(
                        fillColor: MaterialStateProperty.all(AppThemes.authRememberFilled),
                        checkColor: MaterialStateProperty.all(AppThemes.buttonText),
                      ),
                    ),
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (value) => setState(() => _rememberMe = value ?? false),
                    ),
                  ),

                  const Text(
                    'Remember me?',
                    style: TextStyle(color: AppThemes.brown),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Register button
              ElevatedButton(
                onPressed: signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemes.outerformButton,
                  foregroundColor: AppThemes.buttonText,
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
    )
    );
  }
}