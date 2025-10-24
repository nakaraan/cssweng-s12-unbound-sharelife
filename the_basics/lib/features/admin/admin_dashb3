import 'package:flutter/material.dart';
import 'package:the_basics/widgets/side_menu.dart';
import 'package:the_basics/widgets/top_navbar.dart';
import 'package:flutter/material.dart';

class LoanReviewDetailsPage extends StatefulWidget {
  const LoanReviewDetailsPage({super.key});

  @override
  State<LoanReviewDetailsPage> createState() => _LoanReviewDetailsPageState();
}

class _LoanReviewDetailsPageState extends State<LoanReviewDetailsPage> {
  String decision = 'Approve';
  String reason1 = 'Missing Documents';
  String reason2 = 'Incomplete Requirements';
  final TextEditingController remarksController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Row(
        children: [
          // SIDEBAR
          Container(
            width: 200,
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text("Staff Management",
                      style: TextStyle(color: Colors.grey[700])),
                ),
                const SizedBox(height: 20),
                Container(
                  color: Colors.grey[200],
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: const Text("Loan Review",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black)),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text("Loan & Payment Records",
                      style: TextStyle(color: Colors.grey[700])),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text("Vouchers & Disbursements",
                      style: TextStyle(color: Colors.grey[700])),
                ),
              ],
            ),
          ),

          // MAIN CONTENT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TOP BAR
                Container(
                  height: 60,
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.transparent,
                            backgroundImage:
                                AssetImage('assets/logo.png'), // your logo
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Unbound Sharelife',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      Row(
                        children: const [
                          Text("Resources   Contact   Help   "),
                          Icon(Icons.person_outline),
                        ],
                      ),
                    ],
                  ),
                ),

                // HEADER
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Loan Application Review",
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Review applicant details and approve or reject this loan.",
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                ),

                // CARD SECTION
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Applicant info
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Applicant",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text("Mark Reyes"),
                                    SizedBox(height: 12),
                                    Text("Email",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text("mark@school.edu"),
                                    SizedBox(height: 12),
                                    Text("Member Type",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text("Regular"),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Loan Type",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text("Personal Loan"),
                                    SizedBox(height: 12),
                                    Text("Amount Requested",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text("₱50,000"),
                                    SizedBox(height: 12),
                                    Text("Payment Term",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text("12 months"),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                            const Divider(),

                            // Decision Section
                            const Text("Decision",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 10),

                            Row(
                              children: [
                                const Text("Decision:  "),
                                const SizedBox(width: 10),
                                DropdownButton<String>(
                                  value: decision,
                                  items: const [
                                    DropdownMenuItem(
                                        value: "Approve",
                                        child: Text("Approve")),
                                    DropdownMenuItem(
                                        value: "Reject",
                                        child: Text("Reject")),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      decision = value!;
                                    });
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            Row(
                              children: [
                                DropdownButton<String>(
                                  value: reason1,
                                  items: const [
                                    DropdownMenuItem(
                                        value: "Missing Documents",
                                        child: Text("Missing Documents")),
                                    DropdownMenuItem(
                                        value: "Invalid Information",
                                        child: Text("Invalid Information")),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      reason1 = value!;
                                    });
                                  },
                                ),
                                const SizedBox(width: 20),
                                DropdownButton<String>(
                                  value: reason2,
                                  items: const [
                                    DropdownMenuItem(
                                        value: "Incomplete Requirements",
                                        child: Text("Incomplete Requirements")),
                                    DropdownMenuItem(
                                        value: "Other", child: Text("Other")),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      reason2 = value!;
                                    });
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            TextField(
                              controller: remarksController,
                              decoration: InputDecoration(
                                labelText: "Remarks (optional)",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                            ),

                            const SizedBox(height: 10),
                            const Text(
                              "Applicant will be notified via email upon approval or rejection.",
                              style: TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 20),

                            // Buttons
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 12),
                                  ),
                                  child: const Text("Approve"),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 12),
                                  ),
                                  child: const Text("Reject"),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text("Back to List"),
                                ),
                              ],
                            ),
                          ],
                        ),
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
