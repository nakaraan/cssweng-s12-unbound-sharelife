import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class SideMenu extends StatelessWidget {
  final String role; // member, admin, encoder

  const SideMenu({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero
        ),
      backgroundColor: Colors.white,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: _buildMenuItems(context),
        ),
      ),
    );
  }

  List<Widget> _buildMenuItems(BuildContext context) {
    switch (role) {
      case "Admin":
        return [
          SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text("Staff Management"),
            onTap: () {},
          ),
          SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.checklist_rtl),
            title: const Text("Loan Approvals"),
            onTap: () {},
          ),
          SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.track_changes),
            title: const Text("Financial Tracking & Reports"),
            onTap: () {},
          ),
          SizedBox(height: 10),
          ListTile(
            leading: const Icon(CupertinoIcons.eye),
            title: const Text("Vouchers & Disbursements Oversight"),
            onTap: () {},
          ),
        ];

      case "Encoder":
        return [
          SizedBox(height: 10),
          ListTile(
            leading: Icon(Icons.query_stats),
            title: const Text("Dashboard"),
            onTap: () {},
          ),
          SizedBox(height: 10),
          ListTile(
            leading: const Icon(CupertinoIcons.pencil),
            title: const Text("Loan Applications"),
            onTap: () {},
          ),
          SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.folder_open),
            title: const Text("Record Installments"),
            onTap: () {},
          ),
          SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.supervisor_account),
            title: const Text("Member Info"),
            onTap: () {},
          )
        ];

      case "Member":
      default:
        return [
          SizedBox(height: 10),
          ListTile(
            leading: Image.asset(
                    'assets/icons/loan_icon.png',
                    width: 24,
                    height: 24,
                  ),
            title: const Text("My Loans"),
            onTap: () {},
          ),
          SizedBox(height: 10),
          ListTile(
            leading: const Icon(CupertinoIcons.pencil),
            title: const Text("Apply for Loan"),
            onTap: () {},
          ),
          SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text("Payment Records"),
            onTap: () {},
          ),
          SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.file_present),
            title: const Text("Docs & Vouchers"),
            onTap: () {},
          )
        ];
    }
  }
}
