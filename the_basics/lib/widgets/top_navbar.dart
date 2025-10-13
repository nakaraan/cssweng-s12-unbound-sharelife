import 'package:flutter/material.dart';
import 'package:the_basics/auth/auth_service.dart';

class TopNavBar extends StatefulWidget {
  final String splash;
  final bool logoIsBackButton;
  final VoidCallback? onLogoBack;
  final VoidCallback? onAccountSettings;

  const TopNavBar({
    super.key,
    required this.splash,
    this.logoIsBackButton = false,
    this.onLogoBack,
    this.onAccountSettings,
  });


  @override
  State<TopNavBar> createState() => _TopNavBarState();
}

class _TopNavBarState extends State<TopNavBar> {

  // get auth service
  final authService = AuthService();

  // logout button pressed
  void logOut() async {
    await authService.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
  color: Colors.white,
  boxShadow: [
    BoxShadow(
      color: Colors.grey.withOpacity(0.5),
      spreadRadius: 0,
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ],
  border: const Border(
    bottom: BorderSide(
      color: Colors.grey,
      width: 0.5,
    ),
  ),
),
      child: Row(
        children: [
          SideMenuBtn(
            splash: widget.splash,
            logoIsBackButton: widget.logoIsBackButton,
            onLogoBack: widget.onLogoBack,
          ),
          const Spacer(),
          const MenuOptions(),
          ProfileBtn(onAccountSettings: widget.onAccountSettings),
        ],
      ),
    );
  }
}

class SideMenuBtn extends StatelessWidget {
  final String splash;
  final bool logoIsBackButton;
  final VoidCallback? onLogoBack;

  const SideMenuBtn({
    super.key,
    required this.splash,
    this.logoIsBackButton = false,
    this.onLogoBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          // logo (can act as back button if enabled)
          icon: Image.asset(
            'assets/icons/logo.png',
            height: 40,
            width: 40,
          ),
          onPressed: () {
            if (logoIsBackButton) {
              if (onLogoBack != null) {
                onLogoBack!();
              } else {
                if (Navigator.of(context).canPop()) Navigator.of(context).pop();
              }
            } else {
              Scaffold.of(context).openDrawer();  // opens sidebar (dunno if i shld keep this pa)
            }
          },
        ),

        const SizedBox(width: 8),

        // org name + role
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Unbound Sharelife",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            Text(
              splash,  // Display the splash value
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }
}


class  MenuOptions extends StatelessWidget{
  const MenuOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton(
          onPressed: () {Navigator.pushReplacementNamed(context, '/admin-dash');}, 
          child: Text('Resources', style: TextStyle(color: Color(0xFF0C0C0D))) // for relevant links
        ),
        TextButton(
          onPressed: () {Navigator.pushReplacementNamed(context, '/encoder-dash');},
          child: Text('Contact Us', style: TextStyle(color: Color(0xFF0C0C0D))) // for contact info
        ),
        TextButton(
          onPressed: () {Navigator.pushReplacementNamed(context, '/member-dash');},
          child: Text('Help', style: TextStyle(color: Color(0xFF0C0C0D))) // for troubleshooting
        ),
      ]
    );
  }
}

class ProfileBtn extends StatefulWidget {
  final bool accountSettingsRoute;
  final VoidCallback? onAccountSettings;

  const ProfileBtn({
    super.key,
    this.accountSettingsRoute = true,
    this.onAccountSettings,
  });

  @override
  State<ProfileBtn> createState() => _ProfileBtnState();
}

class _ProfileBtnState extends State<ProfileBtn> {
  // get auth service
  final authService = AuthService();

  // logout button
  void logout() async {
    await authService.signOut();
    //Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      offset: const Offset(0, 40),
      itemBuilder: (context) => [
        PopupMenuItem(
          onTap: () {
            if (widget.onAccountSettings != null) {
              widget.onAccountSettings!();
            } else if (widget.accountSettingsRoute) {
              Navigator.pushNamed(context, '/account-options');
            }
          },
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 5),
          child: Center(
            child: Text("Profile Settings"),
          ),
        ),
        PopupMenuItem(
          padding: EdgeInsets.zero,
          onTap: () { logout(); },
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
              child: const Text(
                "Log Out",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      ],
      child: const CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey,
        child: Text(
          "AB",
          style: TextStyle(color: Color(0xFF0C0C0D), fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}