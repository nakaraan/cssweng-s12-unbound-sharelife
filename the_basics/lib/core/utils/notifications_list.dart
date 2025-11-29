import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_basics/core/utils/themes.dart';

class NotificationsListPage extends StatefulWidget {
  const NotificationsListPage({super.key});

  @override
  State<NotificationsListPage> createState() => _NotificationsListPageState();
}

class _NotificationsListPageState extends State<NotificationsListPage> {
  String searchQuery = "";
  String selectedDateFilter = "All";
  List<Map<String, dynamic>> notifications = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  // Helper: format loan reference as LN-YEAR-ID
  String _formatLoanReference(int loanId, DateTime date) {
    return 'LN-${date.year}-$loanId';
  }

  // Helper: format payment reference as PMT-YEAR-ID
  String _formatPaymentReference(int paymentId, DateTime date) {
    return 'PMT-${date.year}-$paymentId';
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      setState(() {
        notifications = [];
        _isLoading = false;
      });
      return;
    }
    final userId = user.id;
    final userEmail = user.email;

    try {
      final memberResp = await client
          .from('members')
          .select('id, user_id, email_address')
          .or('user_id.eq.$userId,email_address.eq.$userEmail')
          .maybeSingle();

      int? memberId;
      if (memberResp != null) {
        final rawId = memberResp['id'];
        if (rawId is int) {
          memberId = rawId;
        } else {
          memberId = int.tryParse(rawId?.toString() ?? '');
        }
      }

      // Building the notifications list
      final List<Map<String, dynamic>> notifsList = [];

      // Helper: parse various date representations into local DateTime
      DateTime _parseDateDynamic(dynamic value) {
        if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
        if (value is DateTime) return value.toLocal();
        if (value is int) return DateTime.fromMillisecondsSinceEpoch(value).toLocal();
        final s = value.toString();
        final dt = DateTime.tryParse(s);
        if (dt != null) return dt.toLocal();
        final asInt = int.tryParse(s);
        if (asInt != null) return DateTime.fromMillisecondsSinceEpoch(asInt).toLocal();
        return DateTime.fromMillisecondsSinceEpoch(0);
      }

      // Helper: format DateTime to 'Mon d, yyyy h:mm AM/PM'
      String _formatDateTime(DateTime dt) {
        if (dt.millisecondsSinceEpoch == 0) return '';
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final month = months[dt.month - 1];
        final day = dt.day;
        final year = dt.year;
        int hour = dt.hour;
        final minute = dt.minute.toString().padLeft(2, '0');
        final period = hour >= 12 ? 'PM' : 'AM';
        if (hour == 0) hour = 12;
        else if (hour > 12) hour -= 12;
        return '$month $day, $year $hour:$minute $period';
      }

      // Query approved loans
      if (memberId != null) {
        try {
          final approvedResp = await client
              .from('approved_loans')
              .select('application_id, member_id, created_at, member_first_name')
              .eq('member_id', memberId);

          for (final row in approvedResp) {
            final loanId = (row['application_id'] as int?) ?? 0;
            final rawDate = row['created_at'] ?? '';
            final firstName = row['member_first_name'] ?? 'Member';
            final dt = _parseDateDynamic(rawDate);
            final loanRef = _formatLoanReference(loanId, dt);
            
            notifsList.add({
              "title": "Loan Approved",
              "body": "Dear $firstName,\n\nWe are pleased to inform you that your loan application with reference number [$loanRef] has been approved.\n\nPlease wait for further instructions regarding the next steps of your disbursement. A representative will contact you shortly with the necessary details.\n\nYou may now also view the details of your approved loan by logging in to your account and clicking \"My Loans.\" If you have any questions or require assistance, please don't hesitate to contact us.\n\nThank you for your continued trust and support.\n\nBest regards,\nSharelife Consumers Cooperative",
              "date": _formatDateTime(dt),
              "type": "loan_approved",
              "status": "read",
              "_ts": dt.millisecondsSinceEpoch.toString(),
              "loanRef": loanRef,
            });
          }
        } catch (e) {
          debugPrint('Error fetching approved loans: $e');
        }
      }

      // Query rejected loan applications
      if (memberId != null) {
        try {
          final rejectedResp = await client
              .from('loan_application')
              .select('application_id, member_id, remarks, date_reviewed, member_first_name, status')
              .eq('member_id', memberId)
              .eq('status', 'Rejected');

          for (final row in rejectedResp) {
            final loanId = (row['application_id'] as int?) ?? 0;
            final rawDate = row['date_reviewed'] ?? '';
            final remarks = (row['remarks'] ?? 'N/A').toString();
            final firstName = row['member_first_name'] ?? 'Member';
            final dt = _parseDateDynamic(rawDate);
            final loanRef = _formatLoanReference(loanId, dt);
            
            notifsList.add({
              "title": "Loan Rejected",
              "body": "Dear $firstName,\n\nWe thank you once again for applying for a loan with Sharelife Consumers Cooperative. However, after careful consideration, we regret to inform you that we are unable to approve your loan application with reference number [$loanRef] at this time.\n\n Due to this Reason: $remarks\n\nWe understand that this may be disappointing news. If you have any questions about this decision or would like to discuss future options, please do not hesitate to contact us.\n\nOnce again, thank you for your understanding and continued interest.\n\nBest regards,\nSharelife Consumers Cooperative",
              "date": _formatDateTime(dt),
              "type": "loan_rejected",
              "status": "read",
              "_ts": dt.millisecondsSinceEpoch.toString(),
              "loanRef": loanRef,
            });
          }
        } catch (e) {
          debugPrint('Error fetching rejected loans: $e');
        }
      }

      // Query valid payments
      if (memberId != null) {
        try {
          final validPaymentsResp = await client
              .from('payments')
              .select('payment_id, approved_loan_id, amount, payment_date, created_at, status')
              .eq('status', 'Validated')
              .order('created_at', ascending: false);

          for (final row in validPaymentsResp) {
            final paymentId = (row['payment_id'] as int?) ?? 0;
            final rawDate = row['created_at'] ?? row['payment_date'] ?? '';
            final amount = (row['amount'] ?? 0).toString();
            final dt = _parseDateDynamic(rawDate);
            final paymentRef = _formatPaymentReference(paymentId, dt);
            
            notifsList.add({
              "title": "Payment Confirmation",
              "body": "Dear Member,\n\nWe have successfully received and verified your payment for your loan.\n\nYour account has been updated accordingly. You may view your latest payment details and remaining balance by logging in to your member account and clicking \"Payment Records\".\n\nThank you for your prompt payment and continued trust.\n\nBest regards,\nSharelife Consumers Cooperative",
              "date": _formatDateTime(dt),
              "type": "payment_valid",
              "status": "read",
              "_ts": dt.millisecondsSinceEpoch.toString(),
              "loanRef": paymentRef,
              "amount": amount,
            });
          }
        } catch (e) {
          debugPrint('Error fetching valid payments: $e');
        }
      }

      // Query invalid payments
      if (memberId != null) {
        final statusFilter = 'Invalidated';
        try {
          final invalidPaymentsResp = await client
              .from('payments')
              .select('payment_id, approved_loan_id, amount, payment_date, created_at, status')
              .eq('status', statusFilter)
              .order('created_at', ascending: false);

          for (final row in invalidPaymentsResp) {
            final paymentId = (row['payment_id'] as int?) ?? 0;
            final rawDate = row['created_at'] ?? row['payment_date'] ?? '';
            final amount = (row['amount'] ?? 0).toString();
            final dt = _parseDateDynamic(rawDate);
            final paymentRef = _formatPaymentReference(paymentId, dt);
            
            notifsList.add({
              "title": "Payment Verification Issue",
              "body": "Dear Member,\n\nWe have received your submitted proof of payment for your loan. However, upon verification, we were unable to validate the payment details.\n\nTo complete your payment processing, please resubmit a valid proof of payment or contact our office for assistance.\n\nThank you for your understanding and cooperation.\n\nBest regards,\nSharelife Consumers Cooperative",
              "date": _formatDateTime(dt),
              "type": "payment_invalid",
              "status": "read",
              "_ts": dt.millisecondsSinceEpoch.toString(),
              "loanRef": paymentRef,
              "amount": amount,
            });
          }
        } catch (e) {
          debugPrint('Error fetching invalid payments: $e');
        }
      } else if (userEmail != null) {
        // Fallback: query by email if memberId not found
        try {
          final approvedResp = await client
              .from('approved_loans')
              .select('application_id, member_id, created_at, member_first_name')
              .eq('member_email', userEmail);

          for (final row in approvedResp) {
            final loanId = (row['application_id'] as int?) ?? 0;
            final rawDate = row['created_at'] ?? '';
            final firstName = row['member_first_name'] ?? 'Member';
            final dt = _parseDateDynamic(rawDate);
            final loanRef = _formatLoanReference(loanId, dt);
            
            notifsList.add({
              "title": "Loan Approved",
              "body": "Dear $firstName,\n\nWe are pleased to inform you that your loan application with reference number [$loanRef] has been approved.\n\nPlease wait for further instructions regarding the next steps of your disbursement. A representative will contact you shortly with the necessary details.\n\nYou may now also view the details of your approved loan by logging in to your account and clicking \"My Loans.\" If you have any questions or require assistance, please don't hesitate to contact us.\n\nThank you for your continued trust and support.\n\nBest regards,\nSharelife Consumers Cooperative",
              "date": _formatDateTime(dt),
              "type": "loan_approved",
              "status": "read",
              "_ts": dt.millisecondsSinceEpoch.toString(),
              "loanRef": loanRef,
            });
          }

          final rejectedResp = await client
              .from('loan_application')
              .select('application_id, member_id, reason, created_at, member_first_name, status')
              .eq('member_email', userEmail)
              .eq('status', 'Rejected');

          for (final row in rejectedResp) {
            final loanId = (row['application_id'] as int?) ?? 0;
            final rawDate = row['created_at'] ?? '';
            final reason = (row['reason'] ?? 'N/A').toString();
            final firstName = row['member_first_name'] ?? 'Member';
            final dt = _parseDateDynamic(rawDate);
            final loanRef = _formatLoanReference(loanId, dt);
            
            notifsList.add({
              "title": "Loan Rejected",
              "body": "Dear $firstName,\n\nWe thank you once again for applying for a loan with Sharelife Consumers Cooperative. However, after careful consideration, we regret to inform you that we are unable to approve your loan application with reference number [$loanRef] at this time.\n\nReason: $reason\n\nWe understand that this may be disappointing news. If you have any questions about this decision or would like to discuss future options, please do not hesitate to contact us.\n\nOnce again, thank you for your understanding and continued interest.\n\nBest regards,\nSharelife Consumers Cooperative",
              "date": _formatDateTime(dt),
              "type": "loan_rejected",
              "status": "read",
              "_ts": dt.millisecondsSinceEpoch.toString(),
              "loanRef": loanRef,
            });
          }
        } catch (e) {
          debugPrint('Error fetching notifications by email: $e');
        }
      }

      // Sort by timestamp descending
      notifsList.sort((a, b) {
        final aTs = int.tryParse(a['_ts'] ?? '') ?? 0;
        final bTs = int.tryParse(b['_ts'] ?? '') ?? 0;
        return bTs.compareTo(aTs);
      });

      // --- Overdue / Missed payment detection ---
      try {
        if (memberId != null) {
            final activeLoans = await client
              .from('approved_loans')
              .select('application_id, created_at, installment, repayment_term, outstanding_balance, loan_amount, member_first_name, missed_notification_sent, overdue_notification_sent')
              .eq('member_id', memberId)
              .eq('status', 'active');

          DateTime now = DateTime.now().toUtc();

          Duration _parseDuration(String? s) {
            if (s == null || s.isEmpty) return const Duration(days: 30);
            final value = s.toLowerCase();
            final numMatch = RegExp(r'(\d+)').firstMatch(value);
            final intN = numMatch != null ? int.tryParse(numMatch.group(0) ?? '') ?? 1 : 1;

            if (value.contains('year')) return Duration(days: 365 * intN);
            if (value.contains('month')) return Duration(days: 30 * intN);
            if (value.contains('week')) return Duration(days: 7 * intN);
            if (value.contains('day')) return Duration(days: intN);
            // fallback assume months
            return Duration(days: 30 * intN);
          }

          for (final loan in activeLoans) {
            final loanId = (loan['application_id'] as int?) ?? 0;
            final rawCreated = loan['created_at'] ?? '';
            final createdDt = _parseDateDynamic(rawCreated);
            final installmentStr = (loan['installment'] ?? '1 month').toString();
            final repaymentStr = (loan['repayment_term'] ?? '0 months').toString();
            final outstanding = (loan['outstanding_balance'] ?? loan['loan_amount'] ?? 0).toString();
            final firstName = loan['member_first_name'] ?? 'Member';

            final installmentDur = _parseDuration(installmentStr);
            final termDur = _parseDuration(repaymentStr);

            // get last validated payment for this loan
            List<dynamic> lastPaymentResp = [];
            try {
              lastPaymentResp = await client
                  .from('payments')
                  .select('payment_date, created_at, amount, status')
                  .eq('approved_loan_id', loanId)
                  .eq('status', 'Validated')
                  .order('payment_date', ascending: false)
                  .limit(1);
            } catch (e) {
              // ignore fetch errors for payments
            }

            DateTime lastPaid = createdDt;
            if (lastPaymentResp.isNotEmpty) {
              final p = lastPaymentResp[0];
              lastPaid = _parseDateDynamic(p['payment_date'] ?? p['created_at'] ?? createdDt);
            }

            // Determine next due date
            final nextDue = lastPaid.add(installmentDur);

            // Consider a 7-day grace period for missed payment
            final grace = const Duration(days: 7);
            final missedFlag = (loan['missed_notification_sent'] ?? false) as bool;
            if (now.isAfter(nextDue.add(grace)) && !missedFlag) {
              final daysOverdue = now.difference(nextDue).inDays;
              final loanRef = _formatLoanReference(loanId, createdDt);
              notifsList.add({
                "title": "Missed Payment",
                "body": "Dear $firstName,\n\nIt appears that a scheduled payment for your loan [$loanRef] is overdue by $daysOverdue day(s). Your current outstanding balance is ₱$outstanding. Please make the payment as soon as possible or contact us to arrange a payment plan.",
                "date": _formatDateTime(now.toLocal()),
                "type": "missed_payment",
                "status": "unread",
                "_ts": now.millisecondsSinceEpoch.toString(),
                "loanRef": loanRef,
                "outstanding": outstanding,
              });

              // Persist the missed notification flag so it remains across sessions
              try {
                await client
                    .from('approved_loans')
                    .update({'missed_notification_sent': true})
                    .eq('application_id', loanId);
              } catch (e) {
                debugPrint('Failed to persist missed_notification_sent for $loanId: $e');
              }
            }

            // Check if loan repayment term has passed and still has outstanding balance
            if (termDur.inDays > 0) {
              final termEnd = createdDt.add(termDur);
              final overdueFlag = (loan['overdue_notification_sent'] ?? false) as bool;
              if (now.isAfter(termEnd) && (loan['outstanding_balance'] ?? 0) != 0 && !overdueFlag) {
                final daysPast = now.difference(termEnd).inDays;
                final loanRef = _formatLoanReference(loanId, createdDt);
                notifsList.add({
                  "title": "Overdue Loan",
                  "body": "Dear $firstName,\n\nYour loan with reference [$loanRef] has passed its repayment term by $daysPast day(s) and still has an outstanding balance of ₱$outstanding. Please contact our office immediately to discuss settlement options.",
                  "date": _formatDateTime(now.toLocal()),
                  "type": "loan_overdue",
                  "status": "unread",
                  "_ts": now.millisecondsSinceEpoch.toString(),
                  "loanRef": loanRef,
                  "outstanding": outstanding,
                });

                // Persist the overdue notification flag so it remains across sessions
                try {
                  await client
                      .from('approved_loans')
                      .update({'overdue_notification_sent': true})
                      .eq('application_id', loanId);
                } catch (e) {
                  debugPrint('Failed to persist overdue_notification_sent for $loanId: $e');
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error detecting overdue/missed payments: $e');
      }

      setState(() {
        notifications = notifsList;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading notifications: $e'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemes.lightcreme,
      appBar: AppBar(
        backgroundColor: AppThemes.darkgreen,
        elevation: 1,
        title: const Text("Notifications", style: TextStyle(color: AppThemes.creme, fontSize: 26)),
        iconTheme: const IconThemeData(color: AppThemes.creme),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Row(
              children: [
                // Search bar
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: "Search notifications...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      onChanged: (value) => setState(() => searchQuery = value),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Date filter
                Row(
                  children: [
                    const Text("Date Filter: "),
                    DropdownButton<String>(
                      value: selectedDateFilter,
                      items: const [
                        DropdownMenuItem(value: "All", child: Text("All")),
                        DropdownMenuItem(value: "Today", child: Text("Today")),
                        DropdownMenuItem(value: "This Week", child: Text("This Week")),
                        DropdownMenuItem(value: "This Month", child: Text("This Month")),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => selectedDateFilter = value);
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Notification List
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : notifications.isEmpty
                        ? const Center(child: Text("No notifications"))
                        : ListView.builder(
                            itemCount: notifications.length,
                            itemBuilder: (context, index) {
                              final notif = notifications[index];

                              // Apply search filter
                              final title = notif["title"]!.toLowerCase();
                              final body = notif["body"]!.toLowerCase();
                              if (!title.contains(searchQuery.toLowerCase()) &&
                                  !body.contains(searchQuery.toLowerCase())) {
                                return const SizedBox.shrink();
                              }

                              // Determine icon based on type
                              IconData leadingIcon;
                              Color leadingColor;
                              switch (notif["type"]) {
                                case 'loan_approved':
                                  leadingIcon = Icons.check_circle;
                                  leadingColor = Colors.green;
                                  break;
                                case 'loan_rejected':
                                  leadingIcon = Icons.cancel;
                                  leadingColor = Colors.red;
                                  break;
                                case 'payment_valid':
                                  leadingIcon = Icons.payment;
                                  leadingColor = Colors.blue;
                                  break;
                                case 'payment_invalid':
                                  leadingIcon = Icons.warning;
                                  leadingColor = Colors.orange;
                                  break;
                                case 'missed_payment':
                                  leadingIcon = Icons.report_problem;
                                  leadingColor = Colors.orange;
                                  break;
                                case 'loan_overdue':
                                  leadingIcon = Icons.error;
                                  leadingColor = Colors.red;
                                  break;
                                default:
                                  leadingIcon = Icons.notifications;
                                  leadingColor = Colors.grey;
                              }

                              return Column(
                                children: [
                                  ListTile(
                                    tileColor: (notif["status"] == 'unread') ? Colors.blue[50] : null,
                                    leading: Icon(leadingIcon, color: leadingColor),
                                    title: Text(notif["title"]!),
                                    subtitle: Text(
                                      notif["body"]!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Text(notif["date"] ?? "", style: TextStyle(fontSize: 12)),
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/notification-view',
                                        arguments: notif,
                                      );
                                    },
                                  ),
                                  Divider(height: 0.5, color: Colors.grey[300]),
                                ],
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}