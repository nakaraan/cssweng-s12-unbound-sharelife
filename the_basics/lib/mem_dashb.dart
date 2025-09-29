import 'package:flutter/material.dart';
import 'package:the_basics/top_navbar.dart';
import 'package:the_basics/side_menu.dart';

class MemDB extends StatelessWidget {
  const MemDB({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const SideMenu(role: "Member"), // sidebar
      body: Stack(
        children: [
          // Main content behind
          Container(
            color: const Color(0xFFEFEFEF), // background color
          ),

          // Top Navbar over everything
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: TopNavBar(),
          ),
        ],
      ),
    );
  }
}