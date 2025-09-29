import 'package:flutter/material.dart';
import 'package:the_basics/auth_navbar.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

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
                        
                        const TextField(
                          decoration: InputDecoration(
                            labelText: 'Username',
                            border: OutlineInputBorder(),
                            hintText: 'Username'
                          ),
                        ),
                        const SizedBox(height: 15),
                        
                        const TextField(
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                            hintText: 'Password'
                          ),
                        ),
                        const SizedBox(height: 15),
                        
                        const TextField(
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            border: OutlineInputBorder(),
                            hintText: 'Confirm Password'
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
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C0C0D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text(
                  'Register',
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