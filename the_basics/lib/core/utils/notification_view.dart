import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:the_basics/core/utils/themes.dart';

class NotificationViewPage extends StatelessWidget {
  const NotificationViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notif = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    
    final title = notif["title"] as String? ?? "Notification";
    final body = notif["body"] as String? ?? "";
    final date = notif["date"] as String? ?? "";
    final notifType = notif["type"] as String? ?? "unknown";
    final loanRef = notif["loanRef"] as String? ?? "N/A";

    // Determine notification color and icon based on type
    final (Color bgColor, Color accentColor, IconData icon) = _getNotificationStyle(notifType);

    return Scaffold(
      backgroundColor: AppThemes.lightcreme,
      appBar: AppBar(
        title: const Text(
          "Notification",
          style: TextStyle(color: AppThemes.lightcreme, fontSize: 26),
        ),
        backgroundColor: AppThemes.darkgreen,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppThemes.lightcreme),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and status badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: accentColor, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(notifType),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  _getStatusLabel(notifType),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                date,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "Ref: $loanRef",
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                                fontFamily: 'Courier',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Divider(color: Colors.grey[200], thickness: 1),
                const SizedBox(height: 24),

                // Email-style notification body
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subject line
                      Text(
                        _getEmailSubject(notifType, loanRef),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Divider(color: Colors.grey[300], thickness: 0.5),
                      const SizedBox(height: 16),

                      // Email body
                      Text(
                        body,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.7,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Action buttons based on notification type
                if (notifType == 'loan_approved') ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.green[700], size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "What Happens Next?",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "• A representative will contact you shortly with disbursement details\n"
                          "• Log in to your account to view approved loan details\n"
                          "• Keep your contact information updated for further communications",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.green[900],
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (notifType == 'loan_rejected') ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red[700], size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "What Can You Do?",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "• Please contact us to discuss this decision or explore future options\n"
                          "• You may reapply after addressing the concerns\n"
                          "• Our team is here to assist you with any questions",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red[900],
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (notifType == 'payment_valid') ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue[700], size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Payment Recorded",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "• Your payment has been verified and processed\n"
                          "• Log in to view your updated payment records and remaining balance\n"
                          "• Thank you for your prompt payment",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[900],
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/member-payment-history'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "View Payment Records",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ] else if (notifType == 'payment_invalid') ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange[700], size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Action Required",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "• Please resubmit a valid proof of payment\n"
                          "• Ensure all payment details are clearly visible\n"
                          "• Contact our office if you need further assistance",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange[900],
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Go Back",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final Uri emailUri = Uri(
                              scheme: 'mailto',
                              path: 'support@sharelife.coop',
                              query: 'subject=Support Request&body=Hello ShareLife Support Team,%0D%0A%0D%0AI need assistance with:%0D%0A',
                            );
                            if (await canLaunchUrl(emailUri)) {
                              await launchUrl(emailUri);
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Could not open email client')),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Contact Support",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Returns (backgroundColor, accentColor, icon) based on notification type
  (Color, Color, IconData) _getNotificationStyle(String type) {
    switch (type) {
      case 'loan_approved':
        return (Colors.green[50]!, Colors.green[700]!, Icons.check_circle);
      case 'loan_rejected':
        return (Colors.red[50]!, Colors.red[700]!, Icons.cancel);
      case 'payment_valid':
        return (Colors.blue[50]!, Colors.blue[700]!, Icons.payment);
      case 'payment_invalid':
        return (Colors.orange[50]!, Colors.orange[700]!, Icons.warning);
      case 'missed_payment':
        return (Colors.orange[50]!, Colors.deepOrange, Icons.report_problem);
      case 'loan_overdue':
        return (Colors.red[50]!, Colors.red[700]!, Icons.error);
      default:
        return (Colors.blue[50]!, Colors.blue[700]!, Icons.notifications);
    }
  }

  Color _getStatusColor(String type) {
    switch (type) {
      case 'loan_approved':
        return Colors.green;
      case 'loan_rejected':
        return Colors.red;
      case 'payment_valid':
        return Colors.blue;
      case 'payment_invalid':
        return Colors.orange;
      case 'missed_payment':
        return Colors.orange;
      case 'loan_overdue':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _getStatusLabel(String type) {
    switch (type) {
      case 'loan_approved':
        return 'APPROVED';
      case 'loan_rejected':
        return 'REJECTED';
      case 'payment_valid':
        return 'CONFIRMED';
      case 'payment_invalid':
        return 'VERIFICATION ISSUE';
      case 'missed_payment':
        return 'MISSED PAYMENT';
      case 'loan_overdue':
        return 'OVERDUE';
      default:
        return 'NEW';
    }
  }

  /// Get formatted email subject based on type and reference
  String _getEmailSubject(String type, String reference) {
    switch (type) {
      case 'loan_approved':
        return 'Subject: Loan Application Approval - [$reference]';
      case 'loan_rejected':
        return 'Subject: Loan Application Update - [$reference]';
      case 'payment_valid':
        return 'Subject: Payment Confirmation - [$reference]';
      case 'payment_invalid':
        return 'Subject: Payment Verification Issue - [$reference]';
      case 'missed_payment':
        return 'Subject: Missed Payment Notice - [$reference]';
      case 'loan_overdue':
        return 'Subject: Overdue Loan Notice - [$reference]';
      default:
        return 'Subject: Notification';
    }
  }
}