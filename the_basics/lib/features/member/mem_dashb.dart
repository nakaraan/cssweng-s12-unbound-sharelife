import 'package:flutter/material.dart';
import 'package:the_basics/core/widgets/top_navbar.dart';
import 'package:the_basics/core/widgets/side_menu.dart';
import 'package:the_basics/core/widgets/export_dropdown_button.dart';
import 'package:the_basics/core/utils/export_service.dart';
import 'package:the_basics/core/utils/themes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MemberDB extends StatefulWidget {
  const MemberDB({super.key});

  @override
  State<MemberDB> createState() => _MemDBState();
}

class _MemDBState extends State<MemberDB> {
  int? sortColumnIndex;
  bool isAscending = true;
  List<Map<String, dynamic>> loans = [];
  double buttonHeight = 28;
  bool _isLoading = false;
  // Controller for horizontal scrolling on the loans table
  late ScrollController _horizontalScrollController;
  // Aggregates for approved active loans
  double _approvedTotalLoanAmount = 0.0;
  double _approvedPrincipalRepayment = 0.0;
  double _approvedOutstandingBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _horizontalScrollController = ScrollController();
    _fetchMemberLoans();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMemberLoans() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      // Get current user's member_id from auth
      final user = Supabase.instance.client.auth.currentUser;
      debugPrint('[MemberDashboard] Current user: ${user?.email}');
      
      if (user == null || user.email == null) {
        debugPrint('[MemberDashboard] No authenticated user');
        if (mounted) {
          setState(() {
            loans = [];
            _isLoading = false;
          });
        }
        return;
      }

      // Get member info by email (more reliable than user_id)
      final memberResponse = await Supabase.instance.client
          .from('members')
          .select('id')
          .eq('email_address', user.email!)
          .maybeSingle();

      debugPrint('[MemberDashboard] Member lookup result: $memberResponse');

      if (memberResponse == null || memberResponse['id'] == null) {
        debugPrint('[MemberDashboard] Member not found for email ${user.email}');
        if (mounted) {
          setState(() {
            loans = [];
            _isLoading = false;
          });
        }
        return;
      }

      final memberId = memberResponse['id'];
      debugPrint('[MemberDashboard] Fetching loans for member_id: $memberId');

      // Also fetch approved active loans aggregates from approved_loans
      try {
        final approvedRecords = await Supabase.instance.client
            .from('approved_loans')
            .select('loan_amount, amount_paid, outstanding_balance, status')
            .eq('member_id', memberId)
            .eq('status', 'active') as List<dynamic>;

        double totalLoan = 0.0;
        double totalPaid = 0.0;
        double totalOutstanding = 0.0;
        for (var a in approvedRecords) {
          final loanAmt = a['loan_amount'];
          final amt = (loanAmt is num) ? loanAmt.toDouble() : double.tryParse(loanAmt?.toString() ?? '0') ?? 0.0;
          totalLoan += amt;

          final paid = a['amount_paid'];
          final paidVal = (paid is num) ? paid.toDouble() : double.tryParse(paid?.toString() ?? '0') ?? 0.0;
          totalPaid += paidVal;

          final out = a['outstanding_balance'];
          final outVal = (out is num) ? out.toDouble() : double.tryParse(out?.toString() ?? '0') ?? 0.0;
          totalOutstanding += outVal;
        }

        _approvedTotalLoanAmount = totalLoan;
        _approvedPrincipalRepayment = totalPaid;
        _approvedOutstandingBalance = totalOutstanding;
        debugPrint('[MemberDashboard] approved loan aggregates: totalLoan=$totalLoan paid=$totalPaid outstanding=$totalOutstanding');
      } catch (e) {
        debugPrint('[MemberDashboard] Error fetching approved_loans aggregates: $e');
        _approvedTotalLoanAmount = 0.0;
        _approvedPrincipalRepayment = 0.0;
        _approvedOutstandingBalance = 0.0;
      }

      // Fetch normalized member loans from the new view
      final records = await Supabase.instance.client
          .from('member_loans')
          .select('*')
          .eq('member_id', memberId)
          .order('created_at', ascending: false) as List<dynamic>;

      debugPrint('[MemberDashboard] member_loans query returned ${records.length} records');
      debugPrint('[MemberDashboard] Records preview: ${records.take(3).toList()}');

      final List<Map<String, dynamic>> fetchedLoans = [];

      for (var rec in records) {
        final createdAt = rec['created_at'] != null
            ? DateTime.parse(rec['created_at'].toString())
            : DateTime.now();
        final dueDate = rec['due_date'] != null
            ? DateTime.parse(rec['due_date'].toString())
            : _calculateDueDate(createdAt, rec['installment_count'] as int?);

        final year = createdAt.year;
        final prefix = (rec['source']?.toString() == 'approved') ? 'LN' : 'AP';
        final loanId = '$prefix-$year-${rec['application_id']?.toString().padLeft(4, '0') ?? '0000'}';

        final amt = (rec['loan_amount'] is num) ? rec['loan_amount'] : double.tryParse(rec['loan_amount']?.toString() ?? '0') ?? 0;
        final instCount = rec['installment_count'] is int ? rec['installment_count'] : int.tryParse(rec['installment_count']?.toString() ?? '0') ?? 0;

        fetchedLoans.add({
          'source': rec['source'] ?? 'approved',
          'ref': loanId,
          'amt': amt,
          // view doesn't provide interest_rate; default to 0 for display
          'interest': 0,
          'start': createdAt.toIso8601String().split('T')[0],
          'due': dueDate.toIso8601String().split('T')[0],
          'instType': rec['repayment_term_text'] ?? (rec['installment_count']?.toString() ?? 'N/A'),
          'totalInst': instCount,
          'instAmt': instCount > 0 ? (amt / instCount) : 0,
          'status': rec['status'] ?? 'unknown',
        });
      }

      debugPrint('[MemberDashboard] Mapped ${fetchedLoans.length} loans to UI format');

      if (mounted) {
        setState(() {
          loans = fetchedLoans;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[MemberDashboard] Error fetching member loans: $e');
      if (mounted) {
        setState(() {
          loans = [];
          _isLoading = false;
        });
      }
    }
  }

  DateTime _calculateDueDate(DateTime startDate, int? repaymentTerm) {
    if (repaymentTerm == null || repaymentTerm == 0) {
      return startDate.add(Duration(days: 30));
    }
    return DateTime(
      startDate.year,
      startDate.month + repaymentTerm,
      startDate.day,
    );
  }

  // Sum loan amounts (robust to int/double/string values)
  // legacy: per-loan summation is no longer used for the summary cards
  // kept for potential future filters; returns 0 when unused
  // ignore: unused_element
  double _sumLoanAmounts() {
    return loans.fold(0.0, (double prev, l) {
      final amt = l['amt'];
      if (amt == null) return prev;
      if (amt is num) return prev + amt.toDouble();
      if (amt is String) {
        final parsed = double.tryParse(amt.replaceAll(RegExp(r'[^0-9\.-]'), ''));
        return prev + (parsed ?? 0.0);
      }
      return prev;
    });
  }

  String _formatCurrency(double value) {
    // Format with comma thousand separators, drop decimals when .00
    if (value == value.roundToDouble()) {
      final intVal = value.toInt();
      final s = intVal.toString().replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => ',');
      return 'Php $s';
    }
    final s = value.toStringAsFixed(2);
    final parts = s.split('.');
    final intPart = parts[0].replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => ',');
    return 'Php $intPart.${parts[1]}';
  }



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

  Widget summaryCards() {
    // Use aggregates derived from active approved loans
    final totalLoan = _approvedTotalLoanAmount;
    final principalRepayment = _approvedPrincipalRepayment;
    final rawOutstanding = _approvedOutstandingBalance;
    
    // Clamp to 0 if NaN, infinite, or negative (handles edge cases)
    double outstandingBalance = 0.0;
    try {
      if (!rawOutstanding.isNaN && !rawOutstanding.isInfinite && rawOutstanding >= 0.0) {
        outstandingBalance = rawOutstanding;
      }
    } catch (_) {
      outstandingBalance = 0.0;
    }

    return Row(
      children: [

        // Principal repayment
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Principal Repayment",
                    style: TextStyle(
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                  Text(_formatCurrency(principalRepayment)),
              ],
            ),
          ),
        ),
        SizedBox(width: 16),

        // Outstanding balance
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Outstanding Balance",
                    style: TextStyle(
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                  Text(_formatCurrency(outstandingBalance)),
              ],
            ),
          ),
        ),
        SizedBox(width: 16),

        // Total loan amount
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Total Loan Amount",
                    style: TextStyle(
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                  Text(_formatCurrency(totalLoan)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget filters() {
    return Row(
      children: [
        // Reference number search
        SizedBox(
          width: 160,
          height: buttonHeight,
          child: TextField(
            style: TextStyle(color: AppThemes.authInput),
            decoration: InputDecoration(
              labelText: "Ref. No.",
              labelStyle: TextStyle(color: AppThemes.searchButton),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
            ),
            onChanged: (value) {
              // Filter logic can be implemented here
            },
          ),
        ),
        SizedBox(width: 16),

        // Start date
        SizedBox(
          width: 120,
          height: buttonHeight,
          child: TextField(
            style: TextStyle(color: AppThemes.authInput),
            decoration: InputDecoration(
              labelText: "Start Date",
              labelStyle: TextStyle(color: AppThemes.searchButton),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
            ),
            readOnly: true,
            onTap: () async {
              await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
            },
          ),
        ),
        SizedBox(width: 16),

        // End date
        SizedBox(
          width: 120,
          height: buttonHeight,
          child: TextField(
            style: TextStyle(color: AppThemes.authInput),
            decoration: InputDecoration(
              labelText: "End Date",
              labelStyle: TextStyle(color: AppThemes.searchButton),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
            ),
            readOnly: true,
            onTap: () async {
              await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
            },
          ),
        ),
        SizedBox(width: 16),

        // Search button
        SizedBox(
          height: buttonHeight,
          child: ElevatedButton(
            onPressed: _fetchMemberLoans,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              minimumSize: Size(80, buttonHeight),
              padding: EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(
              "Search",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),

        Spacer(),

        // Download button
        ExportDropdownButton(
          height: buttonHeight,
          minWidth: 100,
          onExportPdf: () async {
            await ExportService.exportAndSharePdf(
              context: context,
              title: 'Loan Dashboard',
              rows: loans,
              filename: 'loan_dashboard.pdf',
              // Use the actual keys present in the `loans` map so columns are populated
              columnOrder: ['ref', 'amt', 'interest', 'start', 'due', 'instType', 'totalInst', 'instAmt', 'status'],
              columnHeaders: {
                'ref': 'Loan ID',
                'amt': 'Amount',
                'interest': 'Interest',
                'start': 'Start Date',
                'due': 'Due Date',
                'instType': 'Inst. Type',
                'totalInst': 'Total Inst',
                'instAmt': 'Inst. Amt',
                'status': 'Status',
              },
            );
          },
          onExportXlsx: () async {
            await ExportService.exportAndShareExcel(
              context: context,
              rows: loans,
              filename: 'loan_dashboard.xlsx',
              sheetName: 'Loans',
              columnOrder: ['ref', 'amt', 'interest', 'start', 'due', 'instType', 'totalInst', 'instAmt', 'status'],
              columnHeaders: {
                'ref': 'Loan ID',
                'amt': 'Amount',
                'interest': 'Interest',
                'start': 'Start Date',
                'due': 'Due Date',
                'instType': 'Inst. Type',
                'totalInst': 'Total Inst',
                'instAmt': 'Inst. Amt',
                'status': 'Status',
              },
            );
          },
        ),
      ],
    );
  }

  Widget amortizationTable() {
    if (_isLoading) {
      return Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (loans.isEmpty) {
      return Expanded(
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No loans found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Your loan applications will appear here',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Scrollbar(
                controller: _horizontalScrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: _horizontalScrollController,
                  child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: constraints.maxWidth,
                  ),
                  child: DataTable(
                    sortColumnIndex: sortColumnIndex,
                    sortAscending: isAscending,
                    columnSpacing: 58,
                    columns: [
                      DataColumn(
                          label: Text("Ref. No.", style: TextStyle(fontWeight: FontWeight.bold)),
                          onSort: (i, asc) => onSort(i, asc)),
                      DataColumn(
                          label: Text("Amt.", style: TextStyle(fontWeight: FontWeight.bold)),
                          numeric: true,
                          onSort: (i, asc) => onSort(i, asc)),
                      DataColumn(
                          label: Text("Interest", style: TextStyle(fontWeight: FontWeight.bold)),
                          numeric: true,
                          onSort: (i, asc) => onSort(i, asc)),
                      DataColumn(
                          label: Text("Start Date", style: TextStyle(fontWeight: FontWeight.bold)),
                          onSort: (i, asc) => onSort(i, asc)),
                      DataColumn(
                          label: Text("Due Date", style: TextStyle(fontWeight: FontWeight.bold)),
                          onSort: (i, asc) => onSort(i, asc)),
                      DataColumn(
                          label: Text("Inst Type", style: TextStyle(fontWeight: FontWeight.bold)),
                          onSort: (i, asc) => onSort(i, asc)),
                      DataColumn(
                          label: Text("Total Inst", style: TextStyle(fontWeight: FontWeight.bold)),
                          numeric: true,
                          onSort: (i, asc) => onSort(i, asc)),
                      DataColumn(
                          label: Text("Inst Amt.", style: TextStyle(fontWeight: FontWeight.bold)),
                          numeric: true,
                          onSort: (i, asc) => onSort(i, asc)),
                      DataColumn(
                          label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold)),
                          onSort: (i, asc) => onSort(i, asc)),
                    ],
                    rows: loans
                        .map(
                          (loan) => DataRow(cells: [
                            DataCell(Text(loan["ref"])),
                            DataCell(Text(ExportService.currencyFormat.format((loan["amt"] is num) ? loan["amt"] : double.tryParse(loan["amt"].toString()) ?? 0))),
                            DataCell(Text(loan["interest"] != null && loan["interest"] != 0 ? "${loan["interest"]}%" : '-')),
                            DataCell(Text(loan["start"])),
                DataCell(Text(loan["due"])),
                            DataCell(Text(loan["instType"])),
                            DataCell(Text("${loan["totalInst"]}")),
                            DataCell(Text(ExportService.currencyFormat.format((loan["instAmt"] is num) ? loan["instAmt"] : double.tryParse(loan["instAmt"].toString()) ?? 0))),
                            DataCell(
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (loan["status"]?.toString().toLowerCase() == 'pending')
                                      ? Colors.orange.withOpacity(0.1)
                                      : (loan["status"]?.toString().toLowerCase() == 'rejected')
                                          ? Colors.red.withOpacity(0.1)
                                          : Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  loan["status"]?.toString() ?? 'unknown',
                                  style: TextStyle(
                                    color: (loan["status"]?.toString().toLowerCase() == 'pending')
                                        ? Colors.orange.shade700
                                        : (loan["status"]?.toString().toLowerCase() == 'rejected')
                                            ? Colors.red.shade700
                                            : Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ]),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
            );
          },
        ),
      ),
    );
  }




  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Color(0xFFEFEFEF),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/imgs/bg_in.png"),
            fit: BoxFit.cover,
          )
        ),
        child: Column(
        children: [
          // top nav bar
          TopNavBar(splash: "Member"),

          // main area
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // sidebar
                SideMenu(role: "Member"),

                // main content
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(left: 16),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [

                          // title
                          Text(
                            "Your Loans",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppThemes.pageTitle
                            ),
                          ),
                          Text(
                            "View your loan applications and their statuses.",
                            style: TextStyle(color: AppThemes.pageSubtitle, fontSize: 14),
                          ),
                          SizedBox(height: 24),

                          // filter row
                          filters(),
                          SizedBox(height: 24),

                          // summary cards
                          summaryCards(),
                          SizedBox(height: 24),

                          // amortization table
                          amortizationTable(),
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