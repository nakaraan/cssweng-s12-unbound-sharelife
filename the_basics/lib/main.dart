import 'package:flutter/material.dart';
import 'package:the_basics/auth/login.dart';
import 'package:the_basics/features/admin/admin.dart';
import 'package:the_basics/features/encoder/encoder_dashb.dart';
import 'package:the_basics/features/member/mem_dashb.dart';
import 'package:the_basics/auth/register.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://thgmovkioubrizajsvze.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRoZ21vdmtpb3Vicml6YWpzdnplIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkyMzk3MzIsImV4cCI6MjA3NDgxNTczMn0.PBXfbH3n7yTVwZs_e9li_U9F8YirKTl4Wl3TVr1o0gw', // Public Anon Key, meant to be seen by users
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
        '/register': (context) => RegisterPage(),
        '/admin-dash': (context) => AdminDashboard(),
        '/encoder-dash': (context) => EncoderDashboard(),
        '/member-dash': (context) => MemDB()
      },
    );
  }
}