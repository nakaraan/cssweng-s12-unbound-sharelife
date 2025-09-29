import 'package:flutter/material.dart';
import 'package:the_basics/login.dart';
import 'package:the_basics/mem_dashb.dart';
import 'package:the_basics/register.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://tgwuswcywrbrcwacldrk.supabase.coL',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRnd3Vzd2N5d3JicmN3YWNsZHJrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNTI3OTcsImV4cCI6MjA3NDcyODc5N30.85VT2XUJ_U7869baU9lijLZ5bP1p9_NBqjepCvzGKxE', // Public Anon Key, meant to be seen by users
  );
  runApp(const MainApp());
}

final supabase = Supabase.instance.client;

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/login',
      routes: {
        '/home':(context) => MemDB(),
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage() 
      },
    );
  }
}