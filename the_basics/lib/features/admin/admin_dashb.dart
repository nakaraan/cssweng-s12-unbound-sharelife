import 'package:flutter/material.dart';
import 'package:the_basics/widgets/side_menu.dart';
import 'package:the_basics/widgets/top_navbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String? _selectedRole;
  String? _selectedStatus;

  List<Map<String, dynamic>> allStaff = [];
  List<Map<String, dynamic>> filteredStaff = [];
  bool isLoading = true;
  String? errorMessage;

  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchStaffData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _fetchStaffData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // First, verify the current user is an admin
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null || currentUser.email == null) {
        throw Exception('Not authenticated');
      }

      // Check if current user is admin by querying their own record
      final userRecord = await _supabase
          .from('staff')
          .select('role')
          .eq('email_address', currentUser.email!)
          .maybeSingle();

      if (userRecord == null || userRecord['role']?.toLowerCase() != 'admin') {
        throw Exception('Access denied: Admin privileges required');
      }

      // Now fetch all staff data
      final response = await _supabase
          .from('staff')
          .select('id, first_name, last_name, email_address, role')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> staffList = [];
      
      for (final staff in response) {
        // Normalize role to handle legacy data
        String role = staff['role']?.toString().toLowerCase() ?? 'encoder';
        if (role == 'staff') {
          role = 'encoder'; // Convert legacy 'staff' role to 'encoder'
        }
        
        staffList.add({
          'id': staff['id'],
          'name': '${staff['first_name']} ${staff['last_name']}',
          'email': staff['email_address'],
          'role': role,
          'status': 'Active', // Default status since staff table doesn't have status field
        });
      }

      setState(() {
        allStaff = staffList;
        filteredStaff = staffList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching staff data: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _showRoleChangeDialog(Map<String, dynamic> staff) async {
    String? selectedRole = staff['role'];
    
    // Ensure the current role is one of the valid options
    final validRoles = ['admin', 'encoder'];
    if (!validRoles.contains(selectedRole)) {
      selectedRole = 'encoder'; // Default to encoder if current role is invalid
    }
    
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Change Role for ${staff['name']}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Current role: ${staff['role']}'),
                  const SizedBox(height: 16),
                  const Text('Select new role:'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Role',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(value: 'encoder', child: Text('Encoder')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedRole != null && selectedRole != staff['role']
                      ? () => Navigator.of(context).pop(selectedRole)
                      : null,
                  child: const Text('Update Role'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      await _updateStaffRole(staff['id'], result);
    }
  }

  Future<void> _updateStaffRole(int staffId, String newRole) async {
    try {
      // Verify admin status before updating
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null || currentUser.email == null) {
        throw Exception('Not authenticated');
      }

      final userRecord = await _supabase
          .from('staff')
          .select('role')
          .eq('email_address', currentUser.email!)
          .maybeSingle();

      if (userRecord == null || userRecord['role']?.toLowerCase() != 'admin') {
        throw Exception('Access denied: Admin privileges required');
      }

      // Update the staff role
      await _supabase
          .from('staff')
          .update({'role': newRole})
          .eq('id', staffId);

      // Refresh the staff data
      await _fetchStaffData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Role updated to $newRole successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating role: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterStaff() {
    setState(() {
      filteredStaff = allStaff.where((staff) {
        final nameMatch = staff["name"]
            .toLowerCase()
            .contains(_nameController.text.toLowerCase());
        final emailMatch = staff["email"]
            .toLowerCase()
            .contains(_emailController.text.toLowerCase());

        final roleMatch =
            _selectedRole == null || staff["role"] == _selectedRole;
        final statusMatch =
            _selectedStatus == null || staff["status"] == _selectedStatus;

        return nameMatch && emailMatch && roleMatch && statusMatch;
      }).toList();
    });
  }

  Widget _buildTableContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchStaffData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (filteredStaff.isEmpty) {
      return const Center(
        child: Text(
          'No staff members found',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: DataTable(
        columnSpacing: 48,
        headingRowHeight: 48,
        dataRowHeight: 48,
        columns: const [
          DataColumn(label: Text("Name", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Email", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Role", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: filteredStaff.map((staff) {
          return DataRow(
            cells: [
              DataCell(Text(staff["name"])),
              DataCell(Text(staff["email"])),
              DataCell(Text(staff["role"])),
              DataCell(Text(staff["status"])),
              DataCell(Row(
                children: [
                  TextButton(
                    onPressed: () => _showRoleChangeDialog(staff),
                    child: const Text("Change Role"),
                  ),
                  const SizedBox(width: 8),
                  if (staff["status"] == "Active") ...[
                    TextButton(onPressed: () {}, child: const Text("Edit")),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        "Revoke",
                        style: TextStyle(color: Color(0xFF8B0000)),
                      ),
                    ),
                  ] else ...[
                    TextButton(onPressed: () {}, child: const Text("Activate")),
                    TextButton(onPressed: () {}, child: const Text("Delete")),
                  ]
                ],
              )),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double fieldHeight = 40;

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: Column(
        children: [
          const TopNavBar(splash: "Admin"),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SideMenu(role: "Admin"),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Staff Management",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
                        ),
                        const Text(
                          "View, add, and manage staff accounts & roles.",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(height: 20),

                        // Filter row
                        Row(
                          children: [
                            // Name search
                            SizedBox(
                              width: 180,
                              height: fieldHeight,
                              child: TextField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: "Search by Name",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                ),
                                onChanged: (_) => _filterStaff(),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Email search
                            SizedBox(
                              width: 180,
                              height: fieldHeight,
                              child: TextField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: "Search by Email",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                ),
                                onChanged: (_) => _filterStaff(),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Role dropdown
                            SizedBox(
                              width: 150,
                              height: fieldHeight,
                              child: DropdownButtonFormField<String>(
                                value: _selectedRole,
                                decoration: InputDecoration(
                                  labelText: "Role",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                ),
                                items: const [
                                  DropdownMenuItem(value: "admin", child: Text("Admin")),
                                  DropdownMenuItem(value: "encoder", child: Text("Encoder")),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedRole = value;
                                  });
                                  _filterStaff();
                                },
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Status dropdown
                            SizedBox(
                              width: 150,
                              height: fieldHeight,
                              child: DropdownButtonFormField<String>(
                                value: _selectedStatus,
                                decoration: InputDecoration(
                                  labelText: "Status",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                ),
                                items: const [
                                  DropdownMenuItem(value: "Active", child: Text("Active")),
                                  DropdownMenuItem(value: "Inactive", child: Text("Inactive")),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedStatus = value;
                                  });
                                  _filterStaff();
                                },
                              ),
                            ),

                            const Spacer(),

                            // Download button
                            SizedBox(
                              height: fieldHeight,
                              child: ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.download, color: Colors.white),
                                label: const Text("Download", style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  minimumSize: const Size(100, fieldHeight),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Staff table
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            width: double.infinity,
                            child: _buildTableContent(),
                          ),
                        ),
                        // Add Staff button at the bottom
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, '/staff-register');
                              },
                              icon: const Icon(Icons.person_add, color: Colors.white),
                              label: const Text("Add Staff", style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                minimumSize: const Size(140, 44),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
