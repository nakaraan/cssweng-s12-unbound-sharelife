import 'package:flutter/material.dart';

class TopNavBar extends StatelessWidget{
  const TopNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(
            color: Colors.grey, 
            width: 1.0
          )
        ),
      ),
      child: Row(
        children: const [
          SideMenuBtn(),  // opens sidebar
          Spacer(),       // pushes menu options to the right
          MenuOptions(),  // opens menu options
          ProfileBtn(),
        ]
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

  const ProfileBtn({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      itemBuilder: (context) => [
        const PopupMenuItem(
          child: Text("Profile Settings"),
        ),
        PopupMenuItem(
          child: Container(
            color: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: const Text(
              "Log Out",
              style: TextStyle(color: Colors.white),
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
