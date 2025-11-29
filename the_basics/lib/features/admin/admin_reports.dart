import 'package:flutter/material.dart';
import 'package:the_basics/core/widgets/top_navbar.dart';
import 'package:the_basics/core/widgets/side_menu.dart';
import 'package:the_basics/core/widgets/input_fields.dart';
import 'package:the_basics/core/widgets/export_dropdown_button.dart';
import 'package:the_basics/core/utils/export_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_basics/core/utils/themes.dart';

class AdminReports extends StatefulWidget {
  const AdminReports({super.key});

  @override
  State<AdminReports> createState() => _AdminReportsState();
}

class _AdminReportsState extends State<AdminReports> {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  int? sortColumnIndex;
  bool isAscending = true;
  String? selectedReportType;
  double buttonHeight = 28;

  // Loading states
  bool _isLoading = false;
  
  // Fetched data from Supabase
  List<Map<String, dynamic>> _activeLoansData = [];
  List<Map<String, dynamic>> _overdueLoansData = [];
  List<Map<String, dynamic>> _memberLoansData = [];
  List<Map<String, dynamic>> _paymentCollectionData = [];
  Map<String, dynamic> _voucherRevenueData = {};
  // Filtered views (based on the "Filter by..." selector)
  String? selectedTimeFilter;
  List<Map<String, dynamic>> _filteredActiveLoans = [];
  List<Map<String, dynamic>> _filteredOverdueLoans = [];
  List<Map<String, dynamic>> _filteredMemberLoans = [];
  List<Map<String, dynamic>> _filteredPaymentCollection = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Load all reports on init
    await Future.wait([
      _fetchActiveLoans(),
      _fetchOverdueLoans(),
      _fetchMemberLoanSummary(),
      _fetchPaymentCollections(),
      _fetchVoucherRevenue(),
    ]);
    _applyTimeFilter();
  }

  void _applyTimeFilter() {
    // If no filter selected, show original lists
    if (selectedTimeFilter == null || selectedTimeFilter!.isEmpty) {
      setState(() {
        _filteredActiveLoans = List.from(_activeLoansData);
        _filteredOverdueLoans = List.from(_overdueLoansData);
        _filteredMemberLoans = List.from(_memberLoansData);
        _filteredPaymentCollection = List.from(_paymentCollectionData);
      });
      return;
    }

    final now = DateTime.now();
    bool withinFilter(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty || dateStr == '-') return false;
      final parsed = DateTime.tryParse(dateStr);
      if (parsed == null) return false;

      if (selectedTimeFilter == 'Month') {
        return parsed.year == now.year && parsed.month == now.month;
      } else if (selectedTimeFilter == 'Quarter') {
        int q(int m) => ((m - 1) ~/ 3) + 1;
        return parsed.year == now.year && q(parsed.month) == q(now.month);
      } else if (selectedTimeFilter == 'Year') {
        return parsed.year == now.year;
      }
      return true;
    }

    setState(() {
      _filteredActiveLoans = _activeLoansData.where((r) => withinFilter(r['startDate'] as String?)).toList();
      _filteredOverdueLoans = _overdueLoansData.where((r) => withinFilter(r['dueDate'] as String?)).toList();
      _filteredMemberLoans = _memberLoansData.where((r) => withinFilter(r['lastPaid'] as String?)).toList();
      _filteredPaymentCollection = _paymentCollectionData.where((r) => withinFilter(r['payDate'] as String?)).toList();
    });
  }

  Future<void> _fetchActiveLoans() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('approved_loans')
          .select('application_id, member_id, member_first_name, member_last_name, member_email, member_phone, loan_amount, created_at, outstanding_balance, status, amount_paid, repayment_term, installment')
          .eq('status', 'active')
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      
      setState(() {
        _activeLoansData = data.map((loan) {
          // Generate loan ID format: LN-YYYY-XXXX
          final appId = loan['application_id'] ?? 0;
          final createdAt = loan['created_at'] != null 
              ? DateTime.parse(loan['created_at']) 
              : DateTime.now();
          final loanId = 'LN-${createdAt.year}-${appId.toString().padLeft(4, '0')}';
          
          return {
            'loanID': loanId,
            'memName': '${loan['member_first_name'] ?? ''} ${loan['member_last_name'] ?? ''}'.trim(),
            'loanType': loan['installment'] ?? '-',
            'startDate': createdAt.toString().split(' ')[0],
            'dueDate': _calculateDueDate(createdAt, loan['repayment_term']),
            'principalAmt': (loan['loan_amount'] ?? 0).toString(),
            'remainBal': (loan['outstanding_balance'] ?? 0).toString(),
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Error fetching active loans: $e');
      // Keep placeholder data on error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchOverdueLoans() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('approved_loans')
          .select('application_id, member_id, member_first_name, member_last_name, member_phone, loan_amount, created_at, outstanding_balance, status, repayment_term, installment')
          .eq('status', 'overdue')
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      
      setState(() {
        _overdueLoansData = data.map((loan) {
          final appId = loan['application_id'] ?? 0;
          final createdAt = loan['created_at'] != null 
              ? DateTime.parse(loan['created_at']) 
              : DateTime.now();
          final loanId = 'LN-${createdAt.year}-${appId.toString().padLeft(4, '0')}';
          final dueDate = _calculateDueDate(createdAt, loan['repayment_term']);
          final dueDateObj = DateTime.tryParse(dueDate) ?? DateTime.now();
          final daysOverdue = DateTime.now().difference(dueDateObj).inDays;
          
          return {
            'loanID': loanId,
            'memName': '${loan['member_first_name'] ?? ''} ${loan['member_last_name'] ?? ''}'.trim(),
            'loanType': loan['installment'] ?? '-',
            'dueDate': dueDate,
            'daysOverdue': daysOverdue > 0 ? daysOverdue : 0,
            'amountDue': (loan['outstanding_balance'] ?? 0).toString(),
            'lateFees': '0', // Not in schema
            'contactNo': loan['member_phone'] ?? '-',
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Error fetching overdue loans: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMemberLoanSummary() async {
    setState(() => _isLoading = true);
    try {
      // Fetch all approved loans grouped by member
        final response = await _supabase
          .from('approved_loans')
          .select('application_id, member_id, member_first_name, member_last_name, loan_amount, amount_paid, outstanding_balance, status, created_at');

      final List<dynamic> data = response as List<dynamic>;
      
      // Group by member_id
      final Map<int, List<dynamic>> groupedByMember = {};
      for (final loan in data) {
        final memberId = loan['member_id'] as int;
        groupedByMember.putIfAbsent(memberId, () => []).add(loan);
      }

      // Fetch last payment dates for each member
      final paymentResponse = await _supabase
          .from('payments')
          .select('approved_loan_id, payment_date')
          .order('payment_date', ascending: false);
      
      final payments = paymentResponse as List<dynamic>;
      final Map<int, String> lastPaymentDates = {};
      for (final payment in payments) {
        final loanId = payment['approved_loan_id'] as int;
        if (!lastPaymentDates.containsKey(loanId)) {
          lastPaymentDates[loanId] = payment['payment_date'] ?? '';
        }
      }

      setState(() {
        _memberLoansData = groupedByMember.entries.map((entry) {
          final loans = entry.value;
          final firstLoan = loans.first;
          
          num totalBorrowed = 0;
          num totalPaid = 0;
          num outstandingBalance = 0;
          String lastPaymentDate = '-';
          String loanStatus = 'active';
          // Find the most recent payment date for this member across their loans
          DateTime? latest;
          for (final loan in loans) {
            final loanId = loan['application_id'];
            if (loanId == null) continue;
            final lp = lastPaymentDates[loanId as int];
            if (lp == null || lp.toString().isEmpty) continue;
            final parsed = DateTime.tryParse(lp.toString());
            if (parsed == null) continue;
            if (latest == null || parsed.isAfter(latest)) latest = parsed;
          }
          if (latest != null) {
            lastPaymentDate = latest.toString().split(' ')[0];
          }
          
          for (final loan in loans) {
            totalBorrowed += (loan['loan_amount'] ?? 0) as num;
            totalPaid += (loan['amount_paid'] ?? 0) as num;
            outstandingBalance += (loan['outstanding_balance'] ?? 0) as num;
            
            if (loan['status'] == 'overdue') {
              loanStatus = 'overdue';
            } else if (loan['status'] == 'paid' && loanStatus == 'active') {
              loanStatus = 'paid';
            }
          }

          return {
            'memName': '${firstLoan['member_first_name'] ?? ''} ${firstLoan['member_last_name'] ?? ''}'.trim(),
            'memID': entry.key.toString(),
            'totalLoans': loans.length.toString(),
            'totalBorrowed': totalBorrowed.toString(),
            'totalPaid': totalPaid.toString(),
            'outBal': outstandingBalance.toString(),
            'lastPaid': lastPaymentDate,
            'loanStatus': loanStatus,
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Error fetching member loan summary: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchPaymentCollections() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('payments')
          .select('''
            payment_id,
            approved_loan_id,
            staff_id,
            amount,
            payment_date,
            installment_number,
            payment_type,
            status,
            approved_loans(application_id, member_id, member_first_name, member_last_name, repayment_term)
          ''')
          .order('payment_date', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      
      // Fetch staff names
      final staffIds = data.map((p) => p['staff_id']).where((id) => id != null).toSet().toList();
      Map<int, String> staffNames = {};
      if (staffIds.isNotEmpty) {
        final staffResponse = await _supabase
            .from('staff')
            .select('id, first_name, last_name')
            .inFilter('id', staffIds);
        for (final staff in staffResponse as List<dynamic>) {
          staffNames[staff['id']] = '${staff['first_name']} ${staff['last_name']}';
        }
      }

      setState(() {
        _paymentCollectionData = data.map((payment) {
          final loanData = payment['approved_loans'];
          final staffId = payment['staff_id'];
          
          return {
            'payID': (payment['payment_id'] ?? 0).toString(),
            'memName': loanData != null 
                ? '${loanData['member_first_name'] ?? ''} ${loanData['member_last_name'] ?? ''}'.trim()
                : '-',
            'memID': loanData != null ? (loanData['member_id'] ?? '-').toString() : '-',
            'loanID': loanData != null ? 'LN-${DateTime.now().year}-${(loanData['application_id'] ?? 0).toString().padLeft(4, '0')}' : '-',
            'payDate': payment['payment_date'] != null 
                ? DateTime.parse(payment['payment_date']).toString().split(' ')[0]
                : '-',
            'payMethod': payment['payment_type'] ?? '-',
            'amountPaid': (payment['amount'] ?? 0).toString(),
            'collectedBy': staffId != null ? (staffNames[staffId] ?? 'Staff #$staffId') : 'Online',
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Error fetching payment collections: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchVoucherRevenue() async {
    setState(() => _isLoading = true);
    try {
      // Fetch aggregated revenue data
      final loansResponse = await _supabase
          .from('approved_loans')
          .select('loan_amount, outstanding_balance, amount_paid, status');

      final paymentsResponse = await _supabase
          .from('payments')
          .select('amount, status');

      final loans = loansResponse as List<dynamic>;
      final payments = paymentsResponse as List<dynamic>;

      num totalLoansApproved = loans.length;
      num totalDisbursed = 0;
      num totalOutstanding = 0;
      num totalAmountPaid = 0;
      num totalOverdue = 0;

      for (final loan in loans) {
        totalDisbursed += (loan['loan_amount'] ?? 0) as num;
        totalOutstanding += (loan['outstanding_balance'] ?? 0) as num;
        totalAmountPaid += (loan['amount_paid'] ?? 0) as num;
        if ((loan['status'] ?? '') == 'overdue') {
          totalOverdue += (loan['outstanding_balance'] ?? 0) as num;
        }
      }

      num totalPaymentsReceived = 0;
      for (final payment in payments) {
        final status = (payment['status'] ?? '').toString().toLowerCase();
        if (status != 'pending approval') {
          totalPaymentsReceived += (payment['amount'] ?? 0) as num;
        }
      }

      setState(() {
        _voucherRevenueData = {
          'totalLoansApproved': totalLoansApproved.toString(),
          'totalDisbursed': totalDisbursed.toString(),
          'totalPaymentsReceived': totalPaymentsReceived.toString(),
          'totalAmountPaid': totalAmountPaid.toString(),
          'totalOutstanding': totalOutstanding.toString(),
          'totalOverdue': totalOverdue.toString(),
          'totalInterestEarned': '0', // Not in schema
        };
      });
    } catch (e) {
      debugPrint('Error fetching voucher revenue: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _calculateDueDate(DateTime startDate, dynamic repaymentTerm) {
    // repaymentTerm could be "3 months", "6 months", "12 months", etc.
    if (repaymentTerm == null) return startDate.toString().split(' ')[0];
    
    final termStr = repaymentTerm.toString().toLowerCase();
    int months = 3; // default
    
    if (termStr.contains('3')) {
      months = 3;
    } else if (termStr.contains('6')) {
      months = 6;
    } else if (termStr.contains('12')) {
      months = 12;
    }
    
    final dueDate = DateTime(startDate.year, startDate.month + months, startDate.day);
    return dueDate.toString().split(' ')[0];
  }

  Widget buttonsAndFiltersRow() {
    return Row(
      children: [
        SizedBox(
          width: 250,
          child: DropdownInputField(
            label: "Report Type",
            items: [
              "Active Loans",
              "Overdue Loans",
              "Member Loan Summary",
              "Payment Collection",
              "Missed Payments",
              "Voucher & Revenue Summary"
            ],
            onChanged: (value) {
              setState(() {
                selectedReportType = value;
              });
            },
          ),
        ),
        SizedBox(width: 16),

        SizedBox(
          width: 250,
          child: DropdownInputField(
            label: "Filter by...",
            items: [
              "Month",
              "Quarter",
              "Year",
            ],
            onChanged: (value) {
              setState(() {
                selectedTimeFilter = value;
              });
              _applyTimeFilter();
            },
          ),
        ),
        SizedBox(width: 16),

        Spacer(),
        
        ExportDropdownButton(
          height: 28,
          minWidth: 100,
          onExportPdf: () async {
            List<Map<String, dynamic>> reportData = [];
            String reportTitle = '';
            List<String> columnOrder = [];
            Map<String, String> columnHeaders = {};
            
            // Determine which report is currently selected (normalize value)
            final _sel = selectedReportType?.trim().toLowerCase();
            if (_sel == 'active loans') {
              reportData = _filteredActiveLoans;
              reportTitle = 'Active Loans Report';
              columnOrder = ['loanID', 'memName', 'loanType', 'startDate', 'dueDate', 'principalAmt', 'remainBal'];
              columnHeaders = {
                'loanID': 'Loan ID',
                'memName': 'Member Name',
                'loanType': 'Loan Type',
                'startDate': 'Start Date',
                'dueDate': 'Due Date',
                'principalAmt': 'Principal Amount',
                'remainBal': 'Remaining Balance',
              };
            } else if (_sel == 'overdue loans') {
              reportData = _filteredOverdueLoans;
              reportTitle = 'Overdue Loans Report';
              columnOrder = ['loanID', 'memName', 'contactNo', 'daysOverdue', 'amountDue', 'lateFees'];
              columnHeaders = {
                'loanID': 'Loan ID',
                'memName': 'Member Name',
                'contactNo': 'Contact Number',
                'daysOverdue': 'Days Overdue',
                'amountDue': 'Amount Due',
                'lateFees': 'Late Fees',
              };
            } else if (_sel == 'member loan summary') {
              reportData = _filteredMemberLoans;
              reportTitle = 'Member Loan Summary';
              columnOrder = ['memName', 'memID', 'totalLoans', 'totalBorrowed', 'totalPaid', 'outBal', 'loanStatus'];
              columnHeaders = {
                'memName': 'Member Name',
                'memID': 'Member ID',
                'totalLoans': 'Total Loans',
                'totalBorrowed': 'Total Borrowed',
                'totalPaid': 'Total Paid',
                'outBal': 'Outstanding Balance',
                'loanStatus': 'Status',
              };
            } else if (_sel == 'payment collection') {
              reportData = _filteredPaymentCollection;
              reportTitle = 'Payment Collections Report';
              columnOrder = ['payDate', 'memName', 'amountPaid', 'payMethod', 'loanID'];
              columnHeaders = {
                'payDate': 'Payment Date',
                'memName': 'Member Name',
                'amountPaid': 'Amount Paid',
                'payMethod': 'Payment Method',
                'loanID': 'Loan ID',
              };
            } else if (_sel == 'voucher & revenue summary' || _sel == 'voucher and revenue summary') {
              reportTitle = 'Voucher & Revenue Summary';
              columnOrder = ['metric', 'value'];
              columnHeaders = {'metric': 'Metric', 'value': 'Value'};
              reportData = [
                {'metric': 'Total Loans Approved', 'value': _voucherRevenueData['totalLoansApproved'] ?? '0'},
                {'metric': 'Total Disbursed', 'value': ExportService.safeCurrency(_voucherRevenueData['totalDisbursed'])},
                {'metric': 'Total Payments Received', 'value': ExportService.safeCurrency(_voucherRevenueData['totalPaymentsReceived'])},
                {'metric': 'Total Amount Paid', 'value': ExportService.safeCurrency(_voucherRevenueData['totalAmountPaid'])},
                {'metric': 'Total Outstanding', 'value': ExportService.safeCurrency(_voucherRevenueData['totalOutstanding'])},
                {'metric': 'Total Overdue', 'value': ExportService.safeCurrency(_voucherRevenueData['totalOverdue'])},
                {'metric': 'Total Interest Earned', 'value': ExportService.safeCurrency(_voucherRevenueData['totalInterestEarned'])},
              ];
            } else {
              ExportService.showExportMessage(context, 'Please select a report type first');
              return;
            }
            
            await ExportService.exportAndSharePdf(
              context: context,
              rows: reportData,
              title: reportTitle,
              filename: '${reportTitle.toLowerCase().replaceAll(' ', '_')}.pdf',
              columnOrder: columnOrder,
              columnHeaders: columnHeaders,
            );
          },
          onExportXlsx: () async {
            List<Map<String, dynamic>> reportData = [];
            String reportTitle = '';
            List<String> columnOrder = [];
            Map<String, String> columnHeaders = {};
            
            // Determine which report is currently selected (normalize value)
            final _sel2 = selectedReportType?.trim().toLowerCase();
            if (_sel2 == 'active loans') {
              reportData = _filteredActiveLoans;
              reportTitle = 'Active Loans Report';
              columnOrder = ['loanID', 'memName', 'loanType', 'startDate', 'dueDate', 'principalAmt', 'remainBal'];
              columnHeaders = {
                'loanID': 'Loan ID',
                'memName': 'Member Name',
                'loanType': 'Loan Type',
                'startDate': 'Start Date',
                'dueDate': 'Due Date',
                'principalAmt': 'Principal Amount',
                'remainBal': 'Remaining Balance',
              };
            } else if (_sel2 == 'overdue loans') {
              reportData = _filteredOverdueLoans;
              reportTitle = 'Overdue Loans Report';
              columnOrder = ['loanID', 'memName', 'contactNo', 'daysOverdue', 'amountDue', 'lateFees'];
              columnHeaders = {
                'loanID': 'Loan ID',
                'memName': 'Member Name',
                'contactNo': 'Contact Number',
                'daysOverdue': 'Days Overdue',
                'amountDue': 'Amount Due',
                'lateFees': 'Late Fees',
              };
            } else if (_sel2 == 'member loan summary') {
              reportData = _filteredMemberLoans;
              reportTitle = 'Member Loan Summary';
              columnOrder = ['memName', 'memID', 'totalLoans', 'totalBorrowed', 'totalPaid', 'outBal', 'loanStatus'];
              columnHeaders = {
                'memName': 'Member Name',
                'memID': 'Member ID',
                'totalLoans': 'Total Loans',
                'totalBorrowed': 'Total Borrowed',
                'totalPaid': 'Total Paid',
                'outBal': 'Outstanding Balance',
                'loanStatus': 'Status',
              };
            } else if (_sel2 == 'payment collection') {
              reportData = _filteredPaymentCollection;
              reportTitle = 'Payment Collections Report';
              columnOrder = ['payDate', 'memName', 'amountPaid', 'payMethod', 'loanID'];
              columnHeaders = {
                'payDate': 'Payment Date',
                'memName': 'Member Name',
                'amountPaid': 'Amount Paid',
                'payMethod': 'Payment Method',
                'loanID': 'Loan ID',
              };
            } else if (_sel2 == 'voucher & revenue summary' || _sel2 == 'voucher and revenue summary') {
              reportTitle = 'Voucher & Revenue Summary';
              columnOrder = ['metric', 'value'];
              columnHeaders = {'metric': 'Metric', 'value': 'Value'};
              reportData = [
                {'metric': 'Total Loans Approved', 'value': _voucherRevenueData['totalLoansApproved'] ?? '0'},
                {'metric': 'Total Disbursed', 'value': ExportService.safeCurrency(_voucherRevenueData['totalDisbursed'])},
                {'metric': 'Total Payments Received', 'value': ExportService.safeCurrency(_voucherRevenueData['totalPaymentsReceived'])},
                {'metric': 'Total Amount Paid', 'value': ExportService.safeCurrency(_voucherRevenueData['totalAmountPaid'])},
                {'metric': 'Total Outstanding', 'value': ExportService.safeCurrency(_voucherRevenueData['totalOutstanding'])},
                {'metric': 'Total Overdue', 'value': ExportService.safeCurrency(_voucherRevenueData['totalOverdue'])},
                {'metric': 'Total Interest Earned', 'value': ExportService.safeCurrency(_voucherRevenueData['totalInterestEarned'])},
              ];
            } else {
              ExportService.showExportMessage(context, 'Please select a report type first');
              return;
            }
            
            await ExportService.exportAndShareExcel(
              context: context,
              rows: reportData,
              filename: '${reportTitle.toLowerCase().replaceAll(' ', '_')}.xlsx',
              sheetName: reportTitle,
              columnOrder: columnOrder,
              columnHeaders: columnHeaders,
            );
          },
        ),
      ],
    );
  }

  void onSort<T>(
    int columnIndex,
    bool ascending,
    List<Map<String, dynamic>> data,
    String key,
  ) {
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

  // all loans currently being paid (not yet completed or overdue).
  Widget activeLoansTable(List<Map<String, dynamic>> loans) {
    const boldStyle = TextStyle(fontWeight: FontWeight.bold);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  sortColumnIndex: sortColumnIndex,
                  sortAscending: isAscending,
                  columnSpacing: 58,
                  columns: [
                    DataColumn(label: Text("Loan ID", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "loanID")),
                    DataColumn(label: Text("Member Name", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "memName")),
                    DataColumn(label: Text("Loan Type", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "loanType")),
                    DataColumn(label: Text("Start Date", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "startDate")),
                    DataColumn(label: Text("Due Date", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "dueDate")),
                    DataColumn(label: Text("Principal Amount", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "principalAmt")),
                    DataColumn(label: Text("Remaining Balance", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "remainBal")),
                  ],
                  rows: loans.map((loan) {
                    return DataRow(cells: [
                    DataCell(Text("${loan["loanID"] ?? "-"}")),
                    DataCell(Text("${loan["memName"] ?? "-"}")),
                    DataCell(Text("${loan["loanType"] ?? "-"}")),
                    DataCell(Text("${loan["startDate"] ?? "-"}")),
                    DataCell(Text("${loan["dueDate"] ?? "-"}")),
                    DataCell(Text(ExportService.safeCurrency(loan["principalAmt"]))),
                    DataCell(Text(ExportService.safeCurrency(loan["remainBal"]))),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // loans with missed or late payments.
  Widget overdueLoansTable(List<Map<String, dynamic>> loans) {
    const boldStyle = TextStyle(fontWeight: FontWeight.bold);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  sortColumnIndex: sortColumnIndex,
                  sortAscending: isAscending,
                  columnSpacing: 58,
                  columns: [
                    DataColumn(label: Text("Loan ID", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "loanID")),
                    DataColumn(label: Text("Member Name", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "memName")),
                    DataColumn(label: Text("Loan Type", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "loanType")),
                    DataColumn(label: Text("Due Date", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "dueDate")),
                    DataColumn(label: Text("Days Overdue", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "daysOverdue")),
                    DataColumn(label: Text("Amount Due", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "amountDue")),
                    DataColumn(label: Text("Accumulated Late Fees", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "lateFees")),
                    DataColumn(label: Text("Contact No.", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "contactNo")),
                  ],
                  rows: loans.map((loan) {
                    return DataRow(cells: [
                      DataCell(Text("${loan["loanID"] ?? "-"}")),
                      DataCell(Text("${loan["memName"] ?? "-"}")),
                      DataCell(Text("${loan["loanType"] ?? "-"}")),
                      DataCell(Text("${loan["dueDate"] ?? "-"}")),
                      DataCell(Text("${loan["daysOverdue"] ?? "0"}")),
                      DataCell(Text(ExportService.safeCurrency(loan["amountDue"]))),
                      DataCell(Text(ExportService.safeCurrency(loan["lateFees"]))),
                      DataCell(Text("${loan["contactNo"] ?? "-"}")),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // each member’s total loan activity.
  Widget memberLoansTable(List<Map<String, dynamic>> loans) {
    const boldStyle = TextStyle(fontWeight: FontWeight.bold);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  sortColumnIndex: sortColumnIndex,
                  sortAscending: isAscending,
                  columnSpacing: 58,
                  columns: [
                    DataColumn(label: Text("Member Name", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "memName")),
                    DataColumn(label: Text("Member ID", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "memID")),
                    DataColumn(label: Text("Total Loans", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "totalLoans")),
                    DataColumn(label: Text("Total Borrowed", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "totalBorrowed")),
                    DataColumn(label: Text("Total Paid", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "totalPaid")),
                    DataColumn(label: Text("Outstanding Balance", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "outBal")),
                    DataColumn(label: Text("Last Payment Date", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "lastPaid")),
                    DataColumn(label: Text("Loan Status", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "loanStatus")),
                  ],
                  rows: loans.map((loan) {
                    return DataRow(cells: [
                      DataCell(Text("${loan["memName"] ?? "-"}")),
                      DataCell(Text("${loan["memID"] ?? "-"}")),
                      DataCell(Text("${loan["totalLoans"] ?? "0"}")),
                      DataCell(Text(ExportService.safeCurrency(loan["totalBorrowed"]))),
                      DataCell(Text(ExportService.safeCurrency(loan["totalPaid"]))),
                      DataCell(Text(ExportService.safeCurrency(loan["outBal"]))),
                      DataCell(Text("${loan["lastPaid"] ?? "-"}")),
                      DataCell(Text("${loan["loanStatus"] ?? "-"}")),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Track all payments received
  Widget payCollectionTable(List<Map<String, dynamic>> loans) {
    const boldStyle = TextStyle(fontWeight: FontWeight.bold);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  sortColumnIndex: sortColumnIndex,
                  sortAscending: isAscending,
                  columnSpacing: 58,
                  columns: [
                    DataColumn(label: Text("Payment ID", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "payID")),
                    DataColumn(label: Text("Member Name", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "memName")),
                    DataColumn(label: Text("Member ID", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "memID")),
                    DataColumn(label: Text("Loan ID", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "loanID")),
                    DataColumn(label: Text("Payment Date", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "payDate")),
                    DataColumn(label: Text("Payment Method", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "payMethod")),
                    DataColumn(label: Text("Amount Paid", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "amountPaid")),
                    DataColumn(label: Text("Collected By", style: boldStyle), onSort: (i, asc) => onSort(i, asc, loans, "collectedBy")),
                  ],
                  rows: loans.map((loan) {
                    return DataRow(cells: [
                      DataCell(Text("${loan["payID"] ?? "-"}")),
                      DataCell(Text("${loan["memName"] ?? "-"}")),
                      DataCell(Text("${loan["memID"] ?? "-"}")),
                      DataCell(Text("${loan["loanID"] ?? "-"}")),
                      DataCell(Text("${loan["payDate"] ?? "-"}")),
                      DataCell(Text("${loan["payMethod"] ?? "-"}")),
                      DataCell(Text(ExportService.safeCurrency(loan["amountPaid"]))),
                      DataCell(Text("${loan["collectedBy"] ?? "-"}")),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Show income from fees, interest, and voucher-based transactions.
  Widget voucherRevenueSummary(Map<String, dynamic> data) {
    if (data.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Financial Summary',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _summaryRow('Total Loans Approved', data['totalLoansApproved'] ?? '0'),
          _summaryRow('Total Disbursed Amount', ExportService.safeCurrency(data['totalDisbursed'])),
          _summaryRow('Total Payments Received', ExportService.safeCurrency(data['totalPaymentsReceived'])),
          _summaryRow('Total Amount Paid', ExportService.safeCurrency(data['totalAmountPaid'])),
          _summaryRow('Outstanding Balances', ExportService.safeCurrency(data['totalOutstanding'])),
          _summaryRow('Total Overdue Amounts', ExportService.safeCurrency(data['totalOverdue'])),
          _summaryRow('Total Interest Earned', ExportService.safeCurrency(data['totalInterestEarned'])),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_circle,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
    decoration: BoxDecoration(
      image: DecorationImage(
        image: AssetImage("assets/imgs/bg_in.png"),
        fit: BoxFit.cover,
      ),
    ),
    child: Column(
        children: [

          // top nav bar
          const TopNavBar(splash: "Admin"),

          // main area
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // sidebar
                const SideMenu(role: "Admin"),

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
                            "Reports Dashboard",
                            style: TextStyle(
                              fontSize: 28, 
                              fontWeight: FontWeight.bold,
                              color: AppThemes.pageTitle
                            ),
                          ),
                          const Text(
                            "Review various types of reports.",
                            style: TextStyle(color: AppThemes.pageSubtitle, fontSize: 14),
                          ),
                          SizedBox(height: 24),

                          // buttons + filters row
                          buttonsAndFiltersRow(),

                          // table generated by filters
                          Expanded( 
                            child: Container(
                              margin: const EdgeInsets.only(top: 16),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),

                              child: Form(
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      
                                      // main table (sorting by time period not yet implemented)
                                      if (_isLoading)
                                        const Center(child: CircularProgressIndicator())
                                      else if (selectedReportType == "Active Loans")
                                        _filteredActiveLoans.isEmpty 
                                          ? _emptyState('No active loans found')
                                          : activeLoansTable(_filteredActiveLoans)
                                      else if (selectedReportType == "Overdue Loans")
                                        _filteredOverdueLoans.isEmpty
                                          ? _emptyState('No overdue loans found')
                                          : overdueLoansTable(_filteredOverdueLoans)
                                      else if (selectedReportType == "Member Loan Summary")
                                        _filteredMemberLoans.isEmpty
                                          ? _emptyState('No member loan data found')
                                          : memberLoansTable(_filteredMemberLoans)
                                      else if (selectedReportType == "Payment Collection")
                                        _filteredPaymentCollection.isEmpty
                                          ? _emptyState('No payment collections found')
                                          : payCollectionTable(_filteredPaymentCollection)
                                      else if (selectedReportType == "Missed Payments")
                                        _emptyState('Missed Payments feature coming soon')
                                      else if (selectedReportType == "Voucher & Revenue Summary")
                                        voucherRevenueSummary(_voucherRevenueData.isNotEmpty ? _voucherRevenueData : {})
                                      else
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(CupertinoIcons.chart_bar_alt_fill, size: 64, color: Colors.grey),
                                            SizedBox(height: 16),
                                            Text(
                                              'No Report Selected',
                                              style: TextStyle(fontSize: 18, color: Colors.grey),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Reports will appear here once you have chosen a report',
                                              style: TextStyle(fontSize: 12, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                    ]
                                  ),
                                ),
                              )

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
    )
    );
  }
}