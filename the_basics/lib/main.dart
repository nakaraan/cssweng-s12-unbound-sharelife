import 'package:flutter/material.dart';
import 'package:the_basics/auth/login.dart';
import 'package:the_basics/features/account_settings.dart';
import 'package:the_basics/features/admin/admin_dashb.dart';
import 'package:the_basics/features/encoder/encoder_dashb.dart';
import 'package:the_basics/features/member/mem_dashb.dart';
import 'package:the_basics/auth/register.dart';
import 'package:the_basics/auth/staff_register.dart';
import 'package:the_basics/utils/profile_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_basics/auth/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://thgmovkioubrizajsvze.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRoZ21vdmtpb3Vicml6YWpzdnplIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkyMzk3MzIsImV4cCI6MjA3NDgxNTczMn0.PBXfbH3n7yTVwZs_e9li_U9F8YirKTl4Wl3TVr1o0gw',
  );
  runApp(const MainApp());
}


final supabase = Supabase.instance.client;

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final authService = AuthService();

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      print("<!> Auth event: $event"); // ← This should appear when you sign in

      if (event == AuthChangeEvent.signedIn) {
        print("<✓> User signed in — checking pending profile...");
        final pending = await ProfileStorage.getPendingProfile();
        print("<⋯> Pending profile: $pending");

        if (pending != null) { 
            print('<◍> Claiming as a MEMBER...');
            await authService.tryClaimPendingProfile();
        }

        await _routeUserAfterLogin();
      }
    });
  }

  Future<void> _routeUserAfterLogin() async {
    final role = await authService.getUserRole();

    if (role == null) {
      print("Routing user with role: member");
    } else {
      print("Routing user with role: $role");
    }

    final context = navigatorKey.currentContext;
    if (context == null) return;

    switch(role?.toLowerCase()) {
      case 'admin':
        Navigator.pushReplacementNamed(context, '/admin-dash');
        break;
      case 'encoder':
        Navigator.pushReplacementNamed(context, '/encoder-dash');
        break;
      default:
        Navigator.pushReplacementNamed(context, '/member-dash');
        break;
    }
  }

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      initialRoute: '/login',
      routes: {
        '/home':(context) => MemberDB(),
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/admin-dash': (context) => AdminDashboard(),
        '/encoder-dash': (context) => EncoderDashboard(),
        '/member-dash': (context) => MemberDB(),
        '/staff-register': (context) => StaffRegisterPage(),
        '/account-options': (context) => AccountSettings(),
      },
    );
  }
}