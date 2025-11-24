import 'package:flutter/material.dart';
import 'package:the_basics/core/widgets/top_navbar.dart';
import 'package:the_basics/core/widgets/side_menu.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_basics/core/utils/export_service.dart';
import 'package:the_basics/core/utils/themes.dart';
import 'dart:async';

class AdminPaymentReview extends StatefulWidget {
  const AdminPaymentReview({super.key});

  @override
  State<AdminPaymentReview> createState() => _AdminPaymentReviewState();
}

String formatDate(dynamic timestamp) {
  if (timestamp == null) return 'Unknown';
  try {
    if (timestamp is DateTime) {
      final d = timestamp;
      return "${d.month}/${d.day}/${d.year}";
    } else if (timestamp is int) {
      final d = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return "${d.month}/${d.day}/${d.year}";
    } else {
      final d = DateTime.parse(timestamp.toString());
      return "${d.month}/${d.day}/${d.year}";
    }
  } catch (_) {
    return 'Unknown';
  }
}

class _AdminPaymentReviewState extends State<AdminPaymentReview> {
  List<Map<String, dynamic>> payments = [];
  List<Map<String, dynamic>> filteredPayments = [];
  String? selectedPaymentType;
  Timer? _refreshTimer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPayments();
    
    // Set up periodic refresh every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      fetchPayments();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchPayments() async {
    try {
      // Fetch pending payments from payments table
      final paymentsResp = await Supabase.instance.client
          .from('payments')
          .select('''
            payment_id,
            approved_loan_id,
            amount,
            payment_type,
            payment_date,
            status,
            created_at,
            approved_loans(
              member_first_name,
              member_last_name,
              member_id
            )
          ''')
          .eq('status', 'Pending Approval')
          .order('created_at', ascending: false);

      debugPrint('[AdminPaymentReview] paymentsResp runtimeType=${paymentsResp.runtimeType}');
      try {
        final List paymentsList = paymentsResp as List;
        debugPrint('[AdminPaymentReview] paymentsResp length=${paymentsList.length}');
        if (paymentsList.isNotEmpty) debugPrint('[AdminPaymentReview] paymentsResp[0]=${paymentsList.first}');
      } catch (e) {
        debugPrint('[AdminPaymentReview] Error printing paymentsResp preview: $e');
      }

      if (!mounted) return;

      setState(() {
        payments = [];
        
        for (var payment in paymentsResp) {
          final normalizedPayment = Map<String, dynamic>.from(payment);
          
          // Extract member info from the nested approved_loans object
          if (payment['approved_loans'] != null) {
            normalizedPayment['member_first_name'] = payment['approved_loans']['member_first_name'];
            normalizedPayment['member_last_name'] = payment['approved_loans']['member_last_name'];
            normalizedPayment['member_id'] = payment['approved_loans']['member_id'];
          }
          
          payments.add(normalizedPayment);
        }
        
        // Apply filter
        applyFilter();
        debugPrint('[AdminPaymentReview] filteredPayments length after applyFilter=${filteredPayments.length}');
        _isLoading = false;
      });
      
    } catch (e) {
      print('fetchPayments error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading payments: $e'))
        );
      }
    }
  }

  void applyFilter() {
    if (selectedPaymentType == null || selectedPaymentType == 'All') {
      filteredPayments = List.from(payments);
    } else {
      filteredPayments = payments
          .where((payment) => payment['payment_type']?.toString().toLowerCase() == selectedPaymentType?.toLowerCase())
          .toList();
    }
  }

  Widget buildStatus(int number) {
    return Row(
      children: [
        // Filter dropdown
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButton<String>(
            value: selectedPaymentType,
            hint: Text('Filter by Type'),
            underline: SizedBox(),
            items: [
              DropdownMenuItem(value: null, child: Text('All')),
              DropdownMenuItem(value: 'Cash', child: Text('Cash')),
              DropdownMenuItem(value: 'Gcash', child: Text('GCash')),
              // Use enum-style value for DB compatibility, label stays friendly
              DropdownMenuItem(value: 'Bank_Transfer', child: Text('Bank Transfer')),
            ],
            onChanged: (value) {
              setState(() {
                selectedPaymentType = value;
                applyFilter();
              });
            },
          ),
        ),
        SizedBox(width: 16),
        // Counter
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppThemes.brown,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '$number Payment${number == 1 ? '' : 's'} Pending',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppThemes.creme,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget paymentsTable() {
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              columns: [
                DataColumn(label: Text("Member Name", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("Loan ID", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("Amount", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("Payment Type", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("Date Submitted", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("Action", style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: filteredPayments.map((payment) {
                return _buildRow(payment);
              }).toList(),
            ),
          );
        }
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
                      constraints: BoxConstraints(maxWidth: 1200),
                      child: _isLoading
                          ? Center(child: CircularProgressIndicator())
                              : Column( children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [

                                    // title
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Payment Form Review",
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "Review and validate/invalidate pending payment submissions.",
                                          style: TextStyle(color: Colors.grey, fontSize: 14),
                                        ),
                                      ],
                                    ),

                                    // filter and counter
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        buildStatus(filteredPayments.length),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 24),

                                // table
                                Expanded(
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: paymentsTable(),
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

  DataRow _buildRow(Map<String, dynamic> payment) {
    final memberName = "${payment['member_first_name'] ?? ''} ${payment['member_last_name'] ?? ''}".trim();
    final loanId = payment['approved_loan_id']?.toString() ?? 'N/A';
  final amount = ExportService.safeCurrency(payment['amount']);
    final paymentType = payment['payment_type'] ?? 'N/A';
    final date = formatDate(payment['created_at']);

    return DataRow(cells: [
      DataCell(Text(memberName.isEmpty ? 'Unknown' : memberName)),
      DataCell(Text(loanId)),
      DataCell(Text(amount)),
      DataCell(Text(paymentType)),
      DataCell(Text(date)),
      DataCell(ElevatedButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/admin-payment-review-details',
            arguments: payment['payment_id'],
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppThemes.innerformButton,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text("Review", style: TextStyle(color: AppThemes.buttonText)),
      )),
    ]);
  }
}