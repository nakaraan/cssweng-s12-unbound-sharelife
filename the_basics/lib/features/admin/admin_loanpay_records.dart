import 'package:flutter/material.dart';
import 'package:the_basics/core/widgets/top_navbar.dart';
import 'package:the_basics/core/widgets/side_menu.dart';
import 'package:the_basics/core/widgets/export_dropdown_button.dart';
import 'package:the_basics/core/utils/export_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_basics/core/utils/themes.dart';

class AdminLoanPayRec extends StatefulWidget {
  const AdminLoanPayRec({super.key});

  @override
  State<AdminLoanPayRec> createState() => _MemDBState();
}

class _MemDBState extends State<AdminLoanPayRec> {
  int? sortColumnIndex;
  bool isAscending = true;
  bool _isLoading = false;

  // Real data from Supabase
  List<Map<String, dynamic>> loans = [];
  List<Map<String, dynamic>> filteredLoans = [];
  List<Map<String, dynamic>> filteredPayments = [];
  List<Map<String, dynamic>> payments = [];

  // Filter controllers
  final TextEditingController _loanRefController = TextEditingController();
  final TextEditingController _loanMemberController = TextEditingController();
  DateTime? _loanStartDate;
  DateTime? _loanEndDate;
  final TextEditingController _paymentIdController = TextEditingController();
  DateTime? _paymentStartDate;
  DateTime? _paymentEndDate;

  double buttonHeight = 28;
  // Scroll controllers for tables (separate for loans and payments)
  final ScrollController _loansVertController = ScrollController();
  final ScrollController _loansHorizController = ScrollController();
  final ScrollController _paymentsVertController = ScrollController();
  final ScrollController _paymentsHorizController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _loansVertController.dispose();
    _loansHorizController.dispose();
    _paymentsVertController.dispose();
    _paymentsHorizController.dispose();
    _loanRefController.dispose();
    _loanMemberController.dispose();
    _paymentIdController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    await Future.wait([
      _fetchLoans(),
      _fetchPayments(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchLoans() async {
    try {
      // Use explicit select to fetch member fields (avoids extra queries and RLS issues)
      final response = await Supabase.instance.client
          .from('approved_loans')
          .select('application_id, member_id, member_first_name, member_last_name, loan_amount, created_at, outstanding_balance, status, repayment_term, installment')
          .order('created_at', ascending: false);

      final List<dynamic> data = List<dynamic>.from(response);

      // Batch collect member ids so we can fetch member names if the loan rows don't include them
      final Set<int> memberIds = {};
      for (final loan in data) {
        try {
          if (loan != null && loan['member_id'] != null) memberIds.add(loan['member_id'] as int);
        } catch (_) {}
      }

      Map<int, String> memberNames = {};
      if (memberIds.isNotEmpty) {
        try {
          final membersResp = await Supabase.instance.client
              .from('members')
              .select('id, first_name, last_name')
              .inFilter('id', memberIds.toList());
          for (final m in membersResp as List<dynamic>) {
            memberNames[m['id'] as int] = '${m['first_name'] ?? ''} ${m['last_name'] ?? ''}'.trim();
          }
        } catch (e) {
          debugPrint('[AdminLoanPayRec] Error fetching members: $e');
        }
      }

      final List<Map<String, dynamic>> fetchedLoans = [];
      for (var i = 0; i < data.length; i++) {
        final loan = data[i];
        try {
          final appId = loan['application_id'] ?? 0;
          final createdAt = loan['created_at'] != null ? DateTime.parse(loan['created_at']) : DateTime.now();
          final loanId = 'LN-${createdAt.year}-${appId.toString().padLeft(4, '0')}';
          final startDate = createdAt;
          final dueDate = _calculateDueDate(startDate, loan['repayment_term']);

          String memName = '';
          try {
            memName = '${loan['member_first_name'] ?? ''} ${loan['member_last_name'] ?? ''}'.trim();
          } catch (_) {
            memName = '';
          }
          if (memName.isEmpty && loan['member_id'] != null) {
            final lookup = memberNames[loan['member_id'] as int];
            if (lookup != null && lookup.isNotEmpty) memName = lookup;
          }

          final repaymentMonths = _repaymentTermToMonths(loan['repayment_term']);

          fetchedLoans.add({
            'ref': loanId,
            'memName': memName.isNotEmpty ? memName : 'Unknown Member',
            'amt': (loan['loan_amount'] ?? 0),
            'interest': 0,
            'start': startDate.toString().split(' ')[0],
            'due': dueDate.toString().split(' ')[0],
            'instType': loan['repayment_term'] != null ? loan['repayment_term'].toString() : 'N/A',
            'totalInst': repaymentMonths ?? 0,
            'instAmt': (repaymentMonths != null && repaymentMonths > 0)
                ? ((loan['loan_amount'] ?? 0) / repaymentMonths).toString()
                : '0.00',
            'status': loan['status'] ?? 'unknown',
          });
        } catch (e, st) {
          debugPrint('[AdminLoanPayRec] Error mapping row $i: $e');
          debugPrint(st.toString());
        }
      }

      if (mounted) setState(() {
        loans = fetchedLoans;
        filteredLoans = List.from(fetchedLoans);
      });
    } catch (e) {
      debugPrint('Error fetching loans: $e');
      if (mounted) setState(() => loans = []);
    }
  }

  Future<void> _fetchPayments() async {
    try {
      final response = await Supabase.instance.client
          .from('payments')
          .select('''
            payment_id,
            approved_loan_id,
            staff_id,
            amount,
            payment_date,
            installment_number,
            payment_type,
            gcash_reference,
            gcash_screenshot_path,
            bank_name,
            bank_deposit_date,
            status,
            approved_loans(application_id, member_id, member_first_name, member_last_name, repayment_term)
          ''')
          .order('payment_date', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      final List<Map<String, dynamic>> fetchedPayments = [];

      // Fetch staff names for any staff_id present
      final staffIds = data.map((p) => p['staff_id']).where((id) => id != null).toSet().toList();
      Map<int, String> staffNames = {};
      if (staffIds.isNotEmpty) {
        final staffResp = await Supabase.instance.client
            .from('staff')
            .select('id, first_name, last_name')
            .inFilter('id', staffIds);
        for (final s in staffResp as List<dynamic>) {
          staffNames[s['id']] = '${s['first_name']} ${s['last_name']}';
        }
      }

      for (final payment in data) {
        final loanData = payment['approved_loans'];

        fetchedPayments.add({
          'payment_id': (payment['payment_id'] ?? 0).toString(),
          'approved_loan_id': loanData != null ? (loanData['application_id'] ?? '-') : '-',
          'memName': loanData != null ? '${loanData['member_first_name'] ?? ''} ${loanData['member_last_name'] ?? ''}'.trim() : '-',
          'memID': loanData != null ? (loanData['member_id'] ?? '-').toString() : '-',
          'loanID': loanData != null ? 'LN-${DateTime.now().year}-${(loanData['application_id'] ?? 0).toString().padLeft(4, '0')}' : '-',
          'payment_date': payment['payment_date'] != null ? DateTime.parse(payment['payment_date']).toString().split(' ')[0] : '-',
          'payment_type': payment['payment_type'] ?? payment['payment_method'] ?? '-',
          'amount': payment['amount'] ?? 0,
          'installment_number': payment['installment_number'] ?? payment['installmentNo'] ?? '-',
          'gcash_reference': payment['gcash_reference'] ?? '',
          'bank_name': payment['bank_name'] ?? '',
          'status': payment['status'] ?? '',
          'collectedBy': payment['staff_id'] != null ? (staffNames[payment['staff_id']] ?? 'Staff #${payment['staff_id']}') : 'Online',
        });
      }

      if (mounted) setState(() {
        payments = fetchedPayments;
        filteredPayments = List.from(fetchedPayments);
      });
    } catch (e) {
      debugPrint('Error fetching payments: $e');
      if (mounted) setState(() {
        payments = [];
        filteredPayments = [];
      });
    }
  }

  int? _repaymentTermToMonths(dynamic repaymentTerm) {
    if (repaymentTerm == null) return null;
    if (repaymentTerm is int) return repaymentTerm;
    if (repaymentTerm is num) return repaymentTerm.toInt();

    final s = repaymentTerm.toString().toLowerCase().trim();
    // direct integer like "3" or "3 months"
    final direct = int.tryParse(s);
    if (direct != null) return direct;

    final digitMatch = RegExp(r"(\d+)").firstMatch(s);
    if (digitMatch != null) return int.tryParse(digitMatch.group(1)!);

    if (s.contains('monthly')) return 1;
    if (s.contains('bimonth') || s.contains('bimonthly')) return 2;
    if (s.contains('quarter')) return 3;
    if (s.contains('semi')) return 6;
    if (s.contains('12') || s.contains('year') || s.contains('annual')) return 12;

    return null;
  }

  DateTime _calculateDueDate(DateTime startDate, dynamic repaymentTerm) {
    final months = _repaymentTermToMonths(repaymentTerm);
    if (months == null || months == 0) return startDate.add(Duration(days: 30));
    return DateTime(startDate.year, startDate.month + months, startDate.day);
  }

  void onSort<T>(
    int columnIndex,
    bool ascending,
    List<Map<String, dynamic>> data,
    String key,
  ) {
    if (!mounted) return;
    setState(() {
      sortColumnIndex = columnIndex;
      isAscending = ascending;

      data.sort((a, b) {
        final valueA = a[key];
        final valueB = b[key];

        if (valueA == null || valueB == null) return 0;

        if (valueA is num && valueB is num) {
          return ascending ? valueA.compareTo(valueB) : valueB.compareTo(valueA);
        } else if (valueA is DateTime && valueB is DateTime) {
          return ascending ? valueA.compareTo(valueB) : valueB.compareTo(valueA);
        } else {
          return ascending
              ? valueA.toString().compareTo(valueB.toString())
              : valueB.toString().compareTo(valueA.toString());
        }
      });
    });
  }

  void _applyLoanFilters() {
    if (!mounted) return;
    setState(() {
      filteredLoans = loans.where((loan) {
        // Filter by ref number
        if (_loanRefController.text.isNotEmpty) {
          final ref = loan['ref']?.toString().toLowerCase() ?? '';
          if (!ref.contains(_loanRefController.text.toLowerCase())) return false;
        }

        // Filter by member name
        if (_loanMemberController.text.isNotEmpty) {
          final memName = loan['memName']?.toString().toLowerCase() ?? '';
          if (!memName.contains(_loanMemberController.text.toLowerCase())) return false;
        }

        // Filter by start date range
        if (_loanStartDate != null || _loanEndDate != null) {
          final startDateStr = loan['start']?.toString();
          if (startDateStr != null) {
            final loanDate = DateTime.tryParse(startDateStr);
            if (loanDate != null) {
              if (_loanStartDate != null && loanDate.isBefore(_loanStartDate!)) return false;
              if (_loanEndDate != null && loanDate.isAfter(_loanEndDate!.add(Duration(days: 1)))) return false;
            }
          }
        }

        return true;
      }).toList();
    });
  }

  void _applyPaymentFilters() {
    if (!mounted) return;
    setState(() {
      filteredPayments = payments.where((payment) {
        // Filter by payment ID
        if (_paymentIdController.text.isNotEmpty) {
          final payId = payment['payment_id']?.toString().toLowerCase() ?? '';
          if (!payId.contains(_paymentIdController.text.toLowerCase())) return false;
        }

        // Filter by date range
        if (_paymentStartDate != null || _paymentEndDate != null) {
          final payDateStr = payment['payment_date']?.toString();
          if (payDateStr != null && payDateStr != '-') {
            final payDate = DateTime.tryParse(payDateStr);
            if (payDate != null) {
              if (_paymentStartDate != null && payDate.isBefore(_paymentStartDate!)) return false;
              if (_paymentEndDate != null && payDate.isAfter(_paymentEndDate!.add(Duration(days: 1)))) return false;
            }
          }
        }

        return true;
      }).toList();
    });
  }

  // Loan tab things

  Widget loanFilters() {
    return Container(
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
      child: Row(
        children: [
          // Reference number search
          SizedBox(
            width: 160,
            height: buttonHeight,
            child: TextField(
              controller: _loanRefController,
              decoration: InputDecoration(
                labelText: "Ref. No.",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
              onChanged: (value) => _applyLoanFilters(),
            ),
          ),
          SizedBox(width: 16),

          // Member name search
          SizedBox(
            width: 160,
            height: buttonHeight,
            child: TextField(
              controller: _loanMemberController,
              decoration: InputDecoration(
                labelText: "Member Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
              onChanged: (value) => _applyLoanFilters(),
            ),
          ),
          SizedBox(width: 16),

          // Start date
          SizedBox(
            width: 120,
            height: buttonHeight,
            child: TextField(
              decoration: InputDecoration(
                labelText: "Start Date",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
              controller: TextEditingController(text: _loanStartDate != null ? _loanStartDate!.toString().split(' ')[0] : ''),
              readOnly: true,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _loanStartDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => _loanStartDate = picked);
                  _applyLoanFilters();
                }
              },
            ),
          ),
          SizedBox(width: 16),

          // End date
          SizedBox(
            width: 120,
            height: buttonHeight,
            child: TextField(
              decoration: InputDecoration(
                labelText: "End Date",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
              controller: TextEditingController(text: _loanEndDate != null ? _loanEndDate!.toString().split(' ')[0] : ''),
              readOnly: true,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _loanEndDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => _loanEndDate = picked);
                  _applyLoanFilters();
                }
              },
            ),
          ),
          SizedBox(width: 16),

          // refresh button
          SizedBox(
            height: buttonHeight,
            child: ElevatedButton(
              onPressed: () {}, //_fetchPaymentHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: Size(80, buttonHeight),
                padding: EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                "Refresh",
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
                rows: loans,
                title: 'Loan Records',
                filename: 'loan_records_${DateTime.now().millisecondsSinceEpoch}.pdf',
                columnOrder: ['ref', 'memName', 'amt', 'interest', 'start', 'due', 'instType', 'totalInst', 'instAmt', 'status'],
                columnHeaders: {
                  'ref': 'Loan ID',
                  'memName': 'Member Name',
                  'amt': 'Amount',
                  'interest': 'Interest',
                  'start': 'Start Date',
                  'due': 'Due Date',
                  'instType': 'Installment Type',
                  'totalInst': 'Total Installments',
                  'instAmt': 'Installment Amount',
                  'status': 'Status',
                },
              );
            },
            onExportXlsx: () async {
              await ExportService.exportAndShareExcel(
                context: context,
                rows: loans,
                filename: 'loan_records_${DateTime.now().millisecondsSinceEpoch}.xlsx',
                sheetName: 'Loan Records',
                columnOrder: ['ref', 'memName', 'amt', 'interest', 'start', 'due', 'instType', 'totalInst', 'instAmt', 'status'],
                columnHeaders: {
                  'ref': 'Loan ID',
                  'memName': 'Member Name',
                  'amt': 'Amount',
                  'interest': 'Interest',
                  'start': 'Start Date',
                  'due': 'Due Date',
                  'instType': 'Installment Type',
                  'totalInst': 'Total Installments',
                  'instAmt': 'Installment Amount',
                  'status': 'Status',
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget loansTable(List<Map<String, dynamic>> loans) {
    const boldStyle = TextStyle(fontWeight: FontWeight.bold);

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
              controller: _loansVertController,
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                controller: _loansHorizController,
                scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: DataTable(
                        sortColumnIndex: sortColumnIndex,
                        sortAscending: isAscending,
                        columnSpacing: 58,
                        columns: [
                          DataColumn(label: Text("Ref No.", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "ref")),
                          DataColumn(label: Text("Member Name", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "memName")),
                          DataColumn(label: Text("Amt.", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "amt")),
                          DataColumn(label: Text("Interest", style: boldStyle), numeric: true, onSort: (i, asc) => onSort(i, asc, loans, "interest")),
                          DataColumn(label: Text("Start Date", style: boldStyle), numeric: true, onSort: (i, asc) => onSort(i, asc, loans, "start")),
                          DataColumn(label: Text("Due Date", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "due")),
                          DataColumn(label: Text("Inst. Type", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "instType")),
                          DataColumn(label: Text("Total Inst.", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "totalInst")),
                          DataColumn(label: Text("Inst. Amt.", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "instAmt")),
                          DataColumn(label: Text("Status", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "status")),
                        ],
                        rows: loans.map((loan) {
                          return DataRow(cells: [
                            DataCell(Text(loan["ref"])),
                            DataCell(Text(loan["memName"])),
                            DataCell(Text(ExportService.safeCurrency(loan["amt"]))),
                            DataCell(Text("${loan["interest"]}%")),
                            DataCell(Text(loan["start"])),
                            DataCell(Text(loan["due"])),
                            DataCell(Text(loan["instType"])),
                            DataCell(Text("${loan["totalInst"]}")),
                            DataCell(Text(ExportService.safeCurrency(loan["instAmt"]))),
                            DataCell(Text(loan["status"])),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                );
          },
        ),
      ),
    );
  }


  // Payment tab things

  Widget payFilters() {
    return Container(
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
      child: Row(
        children: [
          // payment id search
          SizedBox(
            width: 160,
            height: buttonHeight,
            child: TextField(
              controller: _paymentIdController,
              decoration: InputDecoration(
                labelText: "Payment ID",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
              onChanged: (value) => _applyPaymentFilters(),
            ),
          ),
          SizedBox(width: 16),

          // start date
          SizedBox(
            width: 120,
            height: buttonHeight,
            child: TextField(
              decoration: InputDecoration(
                labelText: "Start Date",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
              controller: TextEditingController(text: _paymentStartDate != null ? _paymentStartDate!.toString().split(' ')[0] : ''),
              readOnly: true,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _paymentStartDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => _paymentStartDate = picked);
                  _applyPaymentFilters();
                }
              },
            ),
          ),
          SizedBox(width: 16),

          // end date
          SizedBox(
            width: 120,
            height: buttonHeight,
            child: TextField(
              decoration: InputDecoration(
                labelText: "End Date",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
              controller: TextEditingController(text: _paymentEndDate != null ? _paymentEndDate!.toString().split(' ')[0] : ''),
              readOnly: true,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _paymentEndDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => _paymentEndDate = picked);
                  _applyPaymentFilters();
                }
              },
            ),
          ),
          SizedBox(width: 16),

          // refresh button
          SizedBox(
            height: buttonHeight,
            child: ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: Size(80, buttonHeight),
                padding: EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                "Refresh",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),

          Spacer(),

          // download button
          ExportDropdownButton(
            height: buttonHeight,
            minWidth: 100,
            onExportPdf: () async {
              await ExportService.exportAndSharePdf(
                context: context,
                rows: filteredPayments,
                title: 'Payment Records',
                filename: 'payment_records_${DateTime.now().millisecondsSinceEpoch}.pdf',
                columnOrder: ['payment_id', 'payment_date', 'amount', 'payment_type', 'status'],
                columnHeaders: {
                  'payment_id': 'Payment ID',
                  'payment_date': 'Payment Date',
                  'amount': 'Amount',
                  'payment_type': 'Payment Type',
                  'status': 'Status',
                },
              );
            },
            onExportXlsx: () async {
              await ExportService.exportAndShareExcel(
                context: context,
                rows: filteredPayments,
                filename: 'payment_records_${DateTime.now().millisecondsSinceEpoch}.xlsx',
                sheetName: 'Payment Records',
                columnOrder: ['payment_id', 'payment_date', 'amount', 'payment_type', 'status'],
                columnHeaders: {
                  'payment_id': 'Payment ID',
                  'payment_date': 'Payment Date',
                  'amount': 'Amount',
                  'payment_type': 'Payment Type',
                  'status': 'Status',
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget payTable(List<Map<String, dynamic>> loans) {
    const boldStyle = TextStyle(fontWeight: FontWeight.bold);

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
              controller: _paymentsVertController,
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                controller: _paymentsHorizController,
                scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: DataTable(
                        sortColumnIndex: sortColumnIndex,
                        sortAscending: isAscending,
                        columnSpacing: 58,
                        columns: [
                          DataColumn(label: Text("Payment ID", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "payment_id")),
                          DataColumn(label: Text("Loan ID", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "approved_loan_id")),
                          DataColumn(label: Text("Inst. No.", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "installment_number")),
                          DataColumn(label: Text("Amt.", style: boldStyle), numeric: true, onSort: (i, asc) => onSort(i, asc, loans, "amount")),
                          DataColumn(label: Text("Payment Type", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "payment_type")),
                          DataColumn(label: Text("GCash Ref No.", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "gcash_reference")),
                          DataColumn(label: Text("Bank Name", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "bank_name")),
                          DataColumn(label: Text("Pay Date", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "payment_date")),
                          DataColumn(label: Text("Status", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "status")),
                        ],
                        rows: filteredPayments.map((pay) {
                          return DataRow(cells: [
                            DataCell(Text("${pay["payment_id"] ?? ""}")),
                            DataCell(Text("${pay["approved_loan_id"] ?? ""}")),
                            DataCell(Text("${pay["installment_number"] ?? ""}")),
                            DataCell(Text(ExportService.safeCurrency(pay["amount"]))),
                            DataCell(Text("${pay["payment_type"] ?? ""}")),
                            DataCell(Text("${pay["gcash_reference"] ?? ""}")),
                            DataCell(Text("${pay["bank_name"] ?? ""}")),
                            DataCell(Text("${pay["payment_date"] ?? ""}")),
                            DataCell(Text("${pay["status"] ?? ""}")),
                          ]);
                        }).toList(),
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
      body: Column(
        children: [

          // top nav bar
          TopNavBar(splash: "Admin"),

          // main area
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // sidebar
                SideMenu(role: "Admin"),

                // main content
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(left: 16),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 900),
                      child: DefaultTabController(
                        length: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // title
                            Text(
                              "Loan & Payment Records",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppThemes.pageTitle
                              ),
                            ),
                            Text(
                              "View and filter through all loan and payment records here.",
                              style: TextStyle(color: AppThemes.pageSubtitle, fontSize: 14),
                            ),
                            SizedBox(height: 24),

                            // tabs
                            TabBar(
                              labelColor: AppThemes.outerformButton,
                              indicatorColor: AppThemes.outerformButton,
                              tabs: [
                                Tab(text: "Loans"),
                                Tab(text: "Payments"),
                              ],
                            ),
                            SizedBox(height: 16),

                            // tab content
                            Expanded(
                              child: TabBarView(
                                children: [
                                  // ===== Loans Tab =====
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      loanFilters(),
                                      SizedBox(height: 24),
                                      // Diagnostic: show how many loans were loaded
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
                                        child: Text('Loaded loans: ${loans.length}', style: TextStyle(color: Colors.grey)),
                                      ),
                                      loansTable(filteredLoans),
                                    ],
                                  ),

                                  // ===== Payments Tab =====
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      payFilters(),
                                      SizedBox(height: 24),
                                      payTable(filteredPayments),
                                    ],
                                  ),
                                ],
                              ),
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