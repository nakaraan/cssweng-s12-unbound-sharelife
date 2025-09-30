import 'package:flutter/material.dart';
import 'package:the_basics/widgets/side_menu.dart';
import 'package:the_basics/widgets/top_navbar.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const SideMenu(role: "Admin"), // <-- integrate sidebar
      body: Column(
        children: const [
          TopNavBar(), // <-- top navigation bar
          Expanded(
            child: AdminDashboardBody(), // main body content
          ),
        ],
      ),
    );
  }
}

class AdminDashboardBody extends StatelessWidget {
  const AdminDashboardBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Home > Admin > Staff Management",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 20),
          const Text(
            "STAFF MANAGEMENT",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const Text(
            "View, add, and manage staff accounts & roles.",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 20),

          // Staff Table here
          Expanded(
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor: MaterialStatePropertyAll(Colors.grey),
                columns: const [
                  DataColumn(label: Text("Name")),
                  DataColumn(label: Text("Email")),
                  DataColumn(label: Text("Role")),
                  DataColumn(label: Text("Status")),
                  DataColumn(label: Text("Actions")),
                ],
                rows: [
                  DataRow(cells: [
                    const DataCell(Text("John Doe")),
                    const DataCell(Text("john@school.edu")),
                    const DataCell(Text("Technician")),
                    const DataCell(Text("Active")),
                    DataCell(Row(
                      children: [
                        TextButton(onPressed: () {}, child: const Text("Edit")),
                        TextButton(onPressed: () {}, child: const Text("Revoke")),
                      ],
                    )),
                  ]),
                  DataRow(cells: [
                    const DataCell(Text("Jane Smith")),
                    const DataCell(Text("jane@school.edu")),
                    const DataCell(Text("Admin")),
                    const DataCell(Text("Active")),
                    DataCell(Row(
                      children: [
                        TextButton(onPressed: () {}, child: const Text("Edit")),
                        TextButton(onPressed: () {}, child: const Text("Revoke")),
                      ],
                    )),
                  ]),
                  DataRow(cells: [
                    const DataCell(Text("Mark Reyes")),
                    const DataCell(Text("mark@school.edu")),
                    const DataCell(Text("Staff")),
                    const DataCell(Text("Inactive")),
                    DataCell(Row(
                      children: [
                        TextButton(onPressed: () {}, child: const Text("Activate")),
                        TextButton(onPressed: () {}, child: const Text("Delete")),
                      ],
                    )),
                  ]),
                  DataRow(cells: [
                    const DataCell(Text("Juan Dela Cruz")),
                    const DataCell(Text("juan@school.edu")),
                    const DataCell(Text("Staff")),
                    const DataCell(Text("Active")),
                    DataCell(Row(
                      children: [
                        TextButton(onPressed: () {}, child: const Text("Edit")),
                        TextButton(onPressed: () {}, child: const Text("Revoke")),
                      ],
                    )),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

