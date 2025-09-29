import 'package:flutter/material.dart';
import 'package:the_basics/widgets/top_navbar.dart';
import 'package:the_basics/widgets/side_menu.dart';
import 'package:the_basics/data/loan_data.dart';

class MemDB extends StatefulWidget {
  const MemDB({super.key});

  @override
  State<MemDB> createState() => _MemDBState();
}

class _MemDBState extends State<MemDB> {
  int? sortColumnIndex;
  bool isAscending = true;

  List<Map<String, dynamic>> loans = loansData;

  void onSort(int columnIndex, bool ascending) {
    setState(() {
      sortColumnIndex = columnIndex;
      isAscending = ascending;

      switch (columnIndex) {
        case 0:
          loans.sort((a, b) => ascending
              ? a["ref"].compareTo(b["ref"])
              : b["ref"].compareTo(a["ref"]));
          break;
        case 1:

  @override
  Widget build(BuildContext context) {
    const double buttonHeight = 28;

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: Column(
        children: [
          // Top navigation bar
          const TopNavBar(),

          // main area
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sidebar
                const SideMenu(role: "Member"),

                // Main content
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Title
                          const Text(
                            "Your Loans",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 2. Filter row: Start/End + Search + Download
                          Row(
                            children: [
                              // Start Date
                              SizedBox(
                                width: 120,
                                height: buttonHeight,
                                child: TextField(
                                  decoration: InputDecoration(
                                    labelText: "Start Date",
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                    contentPadding:
                                        const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                  readOnly: true,
                                  onTap: () async {
                                    DateTime? picked = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),

                              // End Date
                              SizedBox(
                                width: 120,
                                height: buttonHeight,
                                child: TextField(
                                  decoration: InputDecoration(
                                    labelText: "End Date",
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                    contentPadding:
                                        const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                  readOnly: true,
                                  onTap: () async {
                                    DateTime? picked = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Search
                              SizedBox(
                                height: buttonHeight,
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    minimumSize: const Size(80, buttonHeight),
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                  child: const Text(
                                    "Search",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              
                              Spacer(),

                              // Download
                              SizedBox(
                                height: buttonHeight,
                                child: ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.download,
                                      color: Colors.white),
                                  label: const Text(
                                    "Download",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    minimumSize: const Size(100, buttonHeight),
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // 3. Breakdown (two boxes)
                          Row(
                            children: [
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
                                          offset: const Offset(0, 2))
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text("Total Loan Amount",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      SizedBox(height: 8),
                                      Text("₱100,000"),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
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
                                          offset: const Offset(0, 2))
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text("Outstanding Balance",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      SizedBox(height: 8),
                                      Text("₱50,000"),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // 4. Table
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
                                      offset: const Offset(0, 2))
                                ],
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(minWidth: 800),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.vertical,
                                    child: DataTable(
                                      sortColumnIndex: sortColumnIndex,
                                      sortAscending: isAscending,
                                      columnSpacing: 58,
                                      columns: [
                                        DataColumn(
                                            label: const Text("Ref. No."),
                                            onSort: (i, asc) => onSort(i, asc)),
                                        DataColumn(
                                            label: const Text("Amt."),
                                            numeric: true,
                                            onSort: (i, asc) => onSort(i, asc)),
                                        DataColumn(
                                            label: const Text("Interest"),
                                            numeric: true,
                                            onSort: (i, asc) => onSort(i, asc)),
                                        DataColumn(
                                            label: const Text("Start Date"),
                                            onSort: (i, asc) => onSort(i, asc)),
                                        DataColumn(
                                            label: const Text("Due Date"),
                                            onSort: (i, asc) => onSort(i, asc)),
                                        DataColumn(
                                            label: const Text("Inst Type"),
                                            onSort: (i, asc) => onSort(i, asc)),
                                        DataColumn(
                                            label: const Text("Total Inst"),
                                            numeric: true,
                                            onSort: (i, asc) => onSort(i, asc)),
                                        DataColumn(
                                            label: const Text("Inst Amt."),
                                            numeric: true,
                                            onSort: (i, asc) => onSort(i, asc)),
                                        DataColumn(
                                            label: const Text("Status"),
                                            onSort: (i, asc) => onSort(i, asc)),
                                      ],
                                      rows: loans
                                          .map(
                                            (loan) => DataRow(cells: [
                                              DataCell(Text(loan["ref"])),
                                              DataCell(Text("₱${loan["amt"]}")),
                                              DataCell(Text("${loan["interest"]}%")),
                                              DataCell(Text(loan["start"])),
                                              DataCell(Text(loan["due"])),
                                              DataCell(Text(loan["instType"])),
                                              DataCell(Text("${loan["totalInst"]}")),
                                              DataCell(Text("₱${loan["instAmt"]}")),
                                              DataCell(Text(loan["status"])),
                                            ]),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
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
    );
  }
}