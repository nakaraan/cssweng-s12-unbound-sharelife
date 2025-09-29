import 'package:flutter/material.dart';

class TopNavBar extends StatelessWidget {
  const TopNavBar({super.key});

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
      ),
      child: Row(
        children: const [
          SideMenuBtn(),
          Spacer(),
          MenuOptions(),
          ProfileBtn(),
        ],
      ),
    );
  }
}

class  SideMenuBtn extends StatelessWidget{
  const SideMenuBtn({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu),
      onPressed: () {
        Scaffold.of(context).openDrawer();  // opens sidebar
      },
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
          onPressed: () {}, 
          child: Text('Resources', style: TextStyle(color: Color(0xFF0C0C0D))) // for relevant links
        ),
        TextButton(
          onPressed: () {}, 
          child: Text('Contact Us', style: TextStyle(color: Color(0xFF0C0C0D))) // for contact info
        ),
        TextButton(
          onPressed: () {}, 
          child: Text('Help', style: TextStyle(color: Color(0xFF0C0C0D))) // for troubleshooting
        ),
      ]
    );
  }
}

class ProfileBtn extends StatelessWidget {
  const ProfileBtn({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      offset: const Offset(0, 40),
      itemBuilder: (context) => [
        const PopupMenuItem(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 5),
          child: Center(
            child: Text("Profile Settings"),
          ),
        ),
        PopupMenuItem(
          padding: EdgeInsets.zero,
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