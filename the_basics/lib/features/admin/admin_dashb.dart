import 'package:flutter/material.dart';
import 'package:the_basics/widgets/side_menu.dart';
import 'package:the_basics/widgets/top_navbar.dart';
import 'package:the_basics/data/staff_data.dart';

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

  List<Map<String, dynamic>> filteredStaff = staffData;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _filterStaff() {
    setState(() {
      filteredStaff = staffData.where((staff) {
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

  @override
  Widget build(BuildContext context) {
    const double fieldHeight = 40;

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: Column(
        children: [
          const TopNavBar(),
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
                                  DropdownMenuItem(value: "Admin", child: Text("Admin")),
                                  DropdownMenuItem(value: "Encoder", child: Text("Encoder")),
                                  DropdownMenuItem(value: "Member", child: Text("Member")),
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
                            child: SingleChildScrollView(
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
                                          if (staff["status"] == "Active") ...[
                                            TextButton(onPressed: () {}, child: const Text("Edit")),
                                            TextButton(onPressed: () {}, child: const Text("Revoke")),
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