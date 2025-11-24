import 'package:flutter/material.dart';
import 'package:the_basics/core/widgets/side_menu.dart';
import 'package:the_basics/core/widgets/top_navbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_basics/core/utils/themes.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  double nameSize = 40;
  double roleSize = 28;
  double subtitlesize = 28;
  double contentsize = 18;
  double subtitlegap = 40;
  double contentgap = 16;

  // profile fields
  String _firstName = '';
  String _lastName = '';
  String _role = '';
  String _username = '';
  String _dob = '';
  String _contactnum = '';
  String _email = '';
  String _recogDate = '';
  String _status = '';
  String _loanStatus = '';

  Widget _profileHeading(String fname, String lname, String role) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$fname $lname',
          style: TextStyle(fontSize: nameSize, fontWeight: FontWeight.bold),
        ),
        Text(
          role,
          style: TextStyle(color: Colors.grey[600], fontSize: roleSize),
        ),
      ],
    );
  }

  Widget _personalInfo(String username, String dob, String contactnum, String email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Personal Information",
          style: TextStyle(fontSize: subtitlesize, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        SizedBox(height: subtitlegap),
        Text("Username: $username", style: TextStyle(fontSize: contentsize, color: Colors.black)),
        SizedBox(height: contentgap),
        Text(
          "Date of Birth: ${(() {
            if (dob.isEmpty) return 'N/A';
            final dt = DateTime.tryParse(dob);
            if (dt != null) {
              final y = dt.year.toString().padLeft(4, '0');
              final m = dt.month.toString().padLeft(2, '0');
              final d = dt.day.toString().padLeft(2, '0');
              return '$y-$m-$d';
            }
            return dob;
          })()}",
          style: TextStyle(fontSize: contentsize, color: Colors.black),
        ),
        SizedBox(height: contentgap),
        Text("Contact Info: $contactnum", style: TextStyle(fontSize: contentsize, color: Colors.black)),
        SizedBox(height: contentgap),
        Text("Email: $email", style: TextStyle(fontSize: contentsize, color: Colors.black)),
        SizedBox(height: contentgap),
      ],
    );
  }

  Widget _loanInfo(String recogDate, String status, String loanStatus) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Loan Information",
          style: TextStyle(fontSize: subtitlesize, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        SizedBox(height: subtitlegap),
        Text("Recognition Date: $recogDate", style: TextStyle(fontSize: contentsize, color: Colors.black)),
        SizedBox(height: contentgap),
        Text("Status: $status", style: TextStyle(fontSize: contentsize, color: Colors.black)),
        SizedBox(height: contentgap),
        Text("Loan Status: $loanStatus", style: TextStyle(fontSize: contentsize, color: Colors.black)),
        SizedBox(height: contentgap),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {});
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      _email = user.email ?? '';

      // Load staff or member info (simplified, can keep your original logic)
      final staff = await supabase.from('staff').select('*').eq('email_address', _email).maybeSingle();
      if (staff != null) {
        setState(() {
          _firstName = staff['first_name'] ?? '';
          _lastName = staff['last_name'] ?? '';
          _role = staff['role'] ?? 'Staff';
          _username = staff['username'] ?? '';
          _contactnum = staff['contact_number'] ?? '';
          _dob = staff['date_of_birth'] ?? '';
        });
        return;
      }

      final member = await supabase.from('members').select('*').eq('email_address', _email).maybeSingle();
      if (member != null) {
        setState(() {
          _firstName = member['first_name'] ?? '';
          _lastName = member['last_name'] ?? '';
          _role = member['role'] ?? 'Member';
          _username = member['username'] ?? '';
          _contactnum = member['contact_number'] ?? '';
          _dob = member['date_of_birth'] ?? '';
          _recogDate = member['recognition_date'] ?? 'N/A';
          _status = member['status'] ?? 'active';
          _loanStatus = 'No loan applications'; // can keep your loan logic
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
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
            TopNavBar(
              splash: "Settings",
              logoIsBackButton: true,
              onAccountSettings: () {},
              onLogoBack: () {
                if (Navigator.of(context).canPop()) Navigator.of(context).pop();
              },
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SideMenu(role: "Settings"),
                  Expanded(
                    flex: 4,
                    child: Container(
                      color: Colors.transparent,
                      child: Container(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: 30),

                            Row(
                              children: [
                                SizedBox(width: 30),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.arrow_back),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                      Text(
                                        "Back",
                                        style: TextStyle(fontSize: 18, color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 200),

                            _profileHeading(
                              _firstName.isNotEmpty ? _firstName : 'First',
                              _lastName.isNotEmpty ? _lastName : 'Last',
                              _role.isNotEmpty ? _role : 'Member',
                            ),
                            SizedBox(height: 70),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _personalInfo(
                                  _username.isNotEmpty ? _username : '${_firstName.isNotEmpty ? _firstName : 'First'} ${_lastName.isNotEmpty ? _lastName : 'Last'}',
                                  _dob.isNotEmpty ? _dob : 'N/A',
                                  _contactnum.isNotEmpty ? _contactnum : 'N/A',
                                  _email.isNotEmpty ? _email : 'no-email',
                                ),
                                SizedBox(width: 80),
                                _loanInfo(
                                  _recogDate.isNotEmpty ? _recogDate : 'N/A',
                                  _status.isNotEmpty ? _status : 'N/A',
                                  _loanStatus.isNotEmpty ? _loanStatus : 'N/A',
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
