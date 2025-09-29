import 'package:flutter/material.dart';

void main() {
  runApp(const AdminDashboardApp());
}

class AdminDashboardApp extends StatelessWidget {
  const AdminDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Dashboard',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AdminDashboard(),
    );
  }
}

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Admin Dashboard'),
        actions: [
          TextButton(onPressed: () {}, child: const Text("Dashboard", style: TextStyle(color: Colors.white))),
          TextButton(onPressed: () {}, child: const Text("Staff", style: TextStyle(color: Colors.white))),
          TextButton(onPressed: () {}, child: const Text("Reservations", style: TextStyle(color: Colors.white))),
          TextButton(onPressed: () {}, child: const Text("Reports", style: TextStyle(color: Colors.white))),
          TextButton(onPressed: () {}, child: const Text("Settings", style: TextStyle(color: Colors.white))),
          TextButton(onPressed: () {}, child: const Text("Logout", style: TextStyle(color: Colors.white))),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumb
            const Text(
              "Home > Admin > Staff Management",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              "STAFF MANAGEMENT",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const Text(
              "View, add, and manage staff accounts & roles.",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Staff Data Table
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.grey.shade300),
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
      ),
    );
  }
}
