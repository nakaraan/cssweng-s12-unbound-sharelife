import 'package:flutter/material.dart';
import 'package:the_basics/widgets/top_navbar.dart';
import 'package:the_basics/widgets/side_menu.dart';
import 'package:the_basics/data/loan_data.dart';

class MemberDB extends StatefulWidget {
  const MemberDB({super.key});

  @override
  State<MemberDB> createState() => _MemDBState();
}

class _MemDBState extends State<MemberDB> {
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
          loans.sort((a, b) => ascending
              ? a["amt"].compareTo(b["amt"])
              : b["amt"].compareTo(a["amt"]));
          break;
        case 2:
          loans.sort((a, b) => ascending
              ? a["interest"].compareTo(b["interest"])
              : b["interest"].compareTo(a["interest"]));
          break;
        case 3:
          loans.sort((a, b) => ascending
              ? a["start"].compareTo(b["start"])
              : b["start"].compareTo(a["start"]));
          break;
        case 4:
          loans.sort((a, b) => ascending
              ? a["due"].compareTo(b["due"])
              : b["due"].compareTo(a["due"]));
          break;
        case 5:
          loans.sort((a, b) => ascending
              ? a["instType"].compareTo(b["instType"])
              : b["instType"].compareTo(a["instType"]));
          break;
        case 6:
          loans.sort((a, b) => ascending
              ? a["totalInst"].compareTo(b["totalInst"])
              : b["totalInst"].compareTo(a["totalInst"]));
          break;
        case 7:
          loans.sort((a, b) => ascending
              ? a["instAmt"].compareTo(b["instAmt"])
              : b["instAmt"].compareTo(a["instAmt"]));
          break;
        case 8:
          loans.sort((a, b) => ascending
              ? a["status"].compareTo(b["status"])
              : b["status"].compareTo(a["status"]));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const double buttonHeight = 28;

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: Column(
        children: [
          // top nav bar
          const TopNavBar(splash: "Member"),

          // main area
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // sidebar
                const SideMenu(role: "Member"),

                // main content
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [

                          // title
                          const Text(
                            "Your Loans",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            "View your loan applications and their statuses.",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          const SizedBox(height: 24),

                          // filter row
                          Row(
                            children: [

                              // start date
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

                              // end date
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

                              // search
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

                              // download btn
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

                          // summary cards
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
                                      Text("Principal Repayment",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      SizedBox(height: 8),
                                      Text("₱60,000"),
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
                                      Text("₱40,000"),
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
                                      Text("Total Loan Amount",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      SizedBox(height: 8),
                                      Text("₱100,000"),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // amortization table
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
                                            label: const Text("Ref. No.", style: TextStyle( fontWeight: FontWeight.bold)),
                                            onSort: (i, asc) => onSort(i, asc)),
                                        DataColumn(
                                            label: const Text("Amt.", style: TextStyle( fontWeight: FontWeight.bold)),
                                            numeric: true,
                                            onSort: (i, asc) => onSort(i, asc)),
                                        DataColumn(
                                            label: const Text("Interest", style: TextStyle( fontWeight: FontWeight.bold)),
                                            numeric: true,
                                            onSort: (i, asc) => onSort(i, asc)),
                                        DataColumn(
                                            label: const Text("Start Date", style: TextStyle( fontWeight: FontWeight.bold)),
                                            onSort: (i, asc) => onSort(i, asc)),
                                        DataColumn(
                                            label: const Text("Due Date", style: TextStyle( fontWeight: FontWeight.bold)),
                                            onSort: (i, asc) => onSort(i, asc)),
                                        DataColumn(
                                            label: const Text("Inst Type", style: TextStyle( fontWeight: FontWeight.bold)),
                                            onSort: (i, asc) => onSort(i, asc)),
                                        DataColumn(
                                            label: const Text("Total Inst", style: TextStyle( fontWeight: FontWeight.bold)),
                                            numeric: true,
                                            onSort: (i, asc) => onSort(i, asc)),
                                        DataColumn(
                                            label: const Text("Inst Amt.", style: TextStyle( fontWeight: FontWeight.bold)),
                                            numeric: true,
                                            onSort: (i, asc) => onSort(i, asc)),
                                        DataColumn(
                                            label: const Text("Status", style: TextStyle( fontWeight: FontWeight.bold)),
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