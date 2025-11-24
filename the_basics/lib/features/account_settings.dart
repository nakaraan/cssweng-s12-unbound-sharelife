import 'package:flutter/material.dart';
import 'package:the_basics/core/widgets/side_menu.dart';
import 'package:the_basics/core/widgets/top_navbar.dart';
import 'package:the_basics/core/utils/themes.dart';
import 'package:the_basics/auth/auth_service.dart';


class AccountSettings extends StatefulWidget {
  const AccountSettings({super.key});

  @override
  State<AccountSettings> createState() => _AccountSettingsState();
}

class _AccountSettingsState extends State<AccountSettings> {
  String _notifications = 'Email';
  final String _preference = 'Default';
  final String _timezone = 'UTC';
  final authService = AuthService();

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _changePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              style: TextStyle(color: AppThemes.authInput),
              decoration: const InputDecoration(labelText: 'Current Password'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              style: TextStyle(color: AppThemes.authInput),
              decoration: const InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              style: TextStyle(color: AppThemes.authInput),
              decoration: const InputDecoration(labelText: 'Confirm New Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Change'),
          ),
        ],
      ),
    );

    if (result == true) {
      final currentPassword = currentPasswordController.text;
      final newPassword = newPasswordController.text;
      final confirmPassword = confirmPasswordController.text;

      if (newPassword.isEmpty || confirmPassword.isEmpty) {
        _showMessage('Please enter both new password fields');
        return;
      }

      if (newPassword != confirmPassword) {
        _showMessage('New passwords do not match');
        return;
      }

      // Validate password complexity
      final validationError = authService.validatePassword(newPassword);
      if (validationError != null) {
        _showMessage(validationError);
        return;
      }

      try {
        // First verify current password by attempting to re-authenticate
        final email = authService.getCurrentUserEmail();
        if (email == null) {
          _showMessage('Not logged in');
          return;
        }

        try {
          await authService.signInWithEmailPassword(email, currentPassword);
        } catch (e) {
          _showMessage('Current password is incorrect');
          return;
        }

        // Update password
        await authService.updatePassword(newPassword);
        _showMessage('Password changed successfully');
      } catch (e) {
        _showMessage('Error changing password: $e');
      }
    }

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _profileHeading() {
    return Row(
      children: [
        
      ],
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
              onPressed: _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white54, // Background color
                foregroundColor: Colors.black, // Text color
              ),
              child: const Text('Change Password'),
            ),
            const SizedBox(height: 24),

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
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/imgs/bg_settings.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
        children: [

          // Top Navbar things
          TopNavBar(splash: "Settings", 
          logoIsBackButton: true, 
          onAccountSettings: () {},
          onLogoBack: () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          }),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SideMenu(role: "Settings"),
                
                Expanded(
                  flex: 4, // right area ~80%
                  child: Container(
                    color: Colors.transparent,
                    child: Column(

                      // Main content area
                      children: [
                        _profileHeading(),
                        _accountSettings(),
                      ]
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
    );
  }
}