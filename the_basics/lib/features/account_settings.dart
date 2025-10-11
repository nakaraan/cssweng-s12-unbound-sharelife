import 'package:flutter/material.dart';
import 'package:the_basics/widgets/side_menu.dart';
import 'package:the_basics/widgets/top_navbar.dart';

class AccountSettings extends StatefulWidget {
  const AccountSettings({super.key});

  @override
  State<AccountSettings> createState() => _AccountSettingsState();
}

class _AccountSettingsState extends State<AccountSettings> {
  String _notifications = 'Email';
  String _preference = 'Default';
  String _timezone = 'UTC';

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _accountSettings() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Security section
            _sectionHeader('Security'),
            ElevatedButton(
              onPressed: () => _showMessage('Change Password pressed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white54, // Background color
                foregroundColor: Colors.black, // Text color
              ),
              child: const Text('Change Password'),
            ),
            const SizedBox(height: 24),

            // Notifications section
            _sectionHeader('Notifications'),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _notifications,
                    items: const [
                      DropdownMenuItem(value: 'Email', child: Text('Email')),
                      DropdownMenuItem(value: 'None', child: Text('None')),
                    ],
                    onChanged: (v) => setState(() => _notifications = v ?? 'Email'),
                    decoration: const InputDecoration(labelText: 'Preferred channel'),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _showMessage('Notifications saved ($_notifications)'),
                  child: const Text('Save'),
                ),
              ],
            ),
            const SizedBox(height: 40),
            // small footer action
            ElevatedButton.icon(
              onPressed: () => _showMessage('Deactivate account clicked'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent, // Background color
                foregroundColor: Colors.black, // Text color
              ),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Deactivate Account'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: Column(
        children: [
          const TopNavBar(splash: "Settings"),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SideMenu(role: "Settings"),
                
                Expanded(
                  flex: 4, // right area ~80%
                  child: Container(
                    color: Colors.transparent,
                    child: _accountSettings(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}