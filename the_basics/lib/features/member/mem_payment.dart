import 'package:flutter/material.dart';
import 'package:the_basics/core/widgets/top_navbar.dart';
import 'package:the_basics/core/widgets/side_menu.dart';
import 'package:the_basics/core/widgets/input_fields.dart';
import 'package:the_basics/core/widgets/export_dropdown_button.dart';
import 'package:the_basics/core/utils/export_service.dart';
import 'package:the_basics/core/utils/themes.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MemberPaymentForm extends StatefulWidget {
  const MemberPaymentForm({super.key});

  @override
  State<MemberPaymentForm> createState() => _MemberPaymentFormState();
}

class _MemberPaymentFormState extends State<MemberPaymentForm> {

  // payment information
  String? selectedPaymentMethod;
  final TextEditingController amountPaidController = TextEditingController();
  final TextEditingController paymentDateController = TextEditingController();

  // payment information
  final TextEditingController staffController = TextEditingController();
  final TextEditingController refNoController = TextEditingController();
  final TextEditingController receiptController = TextEditingController();
  final TextEditingController bankNameController = TextEditingController();
    
  // file upload
  final ImagePicker _picker = ImagePicker();
  XFile? proofOfPaymentFile;
  
  // staff search (for cash)
  final TextEditingController searchStaffEmailController = TextEditingController();
  final TextEditingController searchStaffFNameController = TextEditingController();
  final TextEditingController searchStaffLNameController = TextEditingController();
  int? selectedStaffId;
  String? selectedStaffName;
  
  bool _isSubmitting = false;


  Widget buttonsRow() {
    return Row(
      children: [
        Spacer(),
        ExportDropdownButton(
          height: 28,
          minWidth: 100,
          onExportPdf: () async {
            // Export payment form data
            final paymentData = [{
              'Field': 'Amount',
              'Value': amountPaidController.text,
            }, {
              'Field': 'Payment Date',
              'Value': paymentDateController.text,
            }, {
              'Field': 'Payment Type',
              'Value': selectedPaymentMethod ?? 'N/A',
            }];
            await ExportService.exportAndSharePdf(
              context: context,
              title: 'Payment Information',
              rows: paymentData,
              filename: 'payment_info.pdf',
            );
          },
          onExportXlsx: () async {
            final paymentData = [{
              'Field': 'Amount',
              'Value': amountPaidController.text,
            }, {
              'Field': 'Payment Date',
              'Value': paymentDateController.text,
            }, {
              'Field': 'Payment Type',
              'Value': selectedPaymentMethod ?? 'N/A',
            }];
            await ExportService.exportAndShareExcel(
              context: context,
              rows: paymentData,
              filename: 'payment_info.xlsx',
              sheetName: 'Payment',
            );
          },
        ),
      ]
    );
  }

  Widget paymentInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Payment Information",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),

        // Payment Method Dropdown
        SizedBox(
          width: 250,
          child: DropdownNonInputField(
            label: "Payment Method", 
            value: selectedPaymentMethod, 
            items: [
              "Cash",
              "Gcash",
              "Bank_Transfer",
            ],
            onChanged: (value) {
              setState(() {
                selectedPaymentMethod = value;
              });
            },
          ),
        ),

        // Payment Fields
        SizedBox(height: 16),
        ...paymentMethodSpecificFields(selectedPaymentMethod ?? ""),
      ],
    );
  }

  List<Widget> paymentMethodSpecificFields(String method) {
    switch (method) {
      case "Cash":
        return [
          // Staff search section
          staffSearchSection(),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: NumberInputField(
                  label: "Amount Paid",
                  controller: amountPaidController,
                  hint: ExportService.currencyFormat.format(0),
                ),
              ),              
              SizedBox(width: 16),

              Expanded(
                child: DateTimeInputField(
                  label: "Date of Payment",
                  controller: paymentDateController,
                ),
              ),
              SizedBox(width: 16),

              Expanded(
                child: TextInputField(
                  label: "Staff Handling Payment",
                  controller: staffController,
                  hint: "Use search above to select staff",
                ),
              ),
            ],
          ),
        ];



      case "Gcash":
        return [
          Row(
            children: [
              Expanded(
                child: NumberInputField(
                  label: "Amount Paid",
                  controller: amountPaidController,
                  hint: ExportService.currencyFormat.format(0),
                ),
              ),              
              SizedBox(width: 16),

              Expanded(
                child: DateTimeInputField(
                  label: "Date of Payment",
                  controller: paymentDateController,
                ),
              ),
              SizedBox(width: 16),

              Expanded(
                child: TextInputField(
                  label: "Reference Number", 
                  controller: refNoController,
                  hint: "",
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FileUploadField(
                  label: "Screenshot of Receipt", 
                  hint: "Upload PNG or JPEG",
                  fileName: receiptController.text,
                  onTap: () async {
                      final XFile? file = await _picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      
                      if (file != null) {
                        setState(() {
                          proofOfPaymentFile = file;
                          receiptController.text = file.name; // Update controller to show filename
                        });
                      }
                    },
                )
              ),
            ],
          ),
        ];



      case "Bank_Transfer":
        return [
          Row(
            children: [
              Expanded(
                child: NumberInputField(
                  label: "Amount Paid",
                  controller: amountPaidController,
                  hint: ExportService.currencyFormat.format(0),
                ),
              ),              
              SizedBox(width: 16),

              Expanded(
                child: DateTimeInputField(
                  label: "Date of Bank Deposit",
                  controller: paymentDateController,
                ),
              ),
              SizedBox(width: 16),

              Expanded(
                child: TextInputField(
                  label: "Bank Name",
                  controller: bankNameController,
                  hint: "e.g. BPI",
                ),
              )

            ],
          ),
        ];
      default:
        return [];
    }
  }

  // --- Staff search helpers ---
  Future<Map<String, dynamic>?> _findStaffByEmail(String email) async {
    if (email.trim().isEmpty) return null;
    try {
      final rec = await Supabase.instance.client
          .from('staff')
          .select('id, first_name, last_name, email_address')
          .eq('email_address', email.trim().toLowerCase())
          .maybeSingle();
      if (rec == null) return null;
      return Map<String, dynamic>.from(rec as Map);
    } catch (e) {
      debugPrint('Error searching staff by email: $e');
      return null;
    }
  }

  Future<void> _onSearchStaffByEmail() async {
    final email = searchStaffEmailController.text.trim().toLowerCase();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an email to search for staff.')),
      );
      return;
    }

    final rec = await _findStaffByEmail(email);
    if (rec != null) {
      setState(() {
        selectedStaffId = rec['id'] as int;
        selectedStaffName = '${rec['first_name']} ${rec['last_name']}';
        staffController.text = selectedStaffName!;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Staff found: $selectedStaffName')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No staff member found with that email.')),
      );
    }
  }

  Future<Map<String, dynamic>?> _findStaffByName(String first, String last) async {
    if (first.trim().isEmpty || last.trim().isEmpty) return null;
    try {
      final rec = await Supabase.instance.client
          .from('staff')
          .select('id, first_name, last_name, email_address')
          .eq('first_name', first.trim())
          .eq('last_name', last.trim())
          .maybeSingle();
      if (rec == null) return null;
      return Map<String, dynamic>.from(rec as Map);
    } catch (e) {
      debugPrint('Error searching staff by name: $e');
      return null;
    }
  }

  Future<void> _onSearchStaffByName() async {
    final first = searchStaffFNameController.text.trim();
    final last = searchStaffLNameController.text.trim();
    if (first.isEmpty || last.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Provide both first and last name to search.')),
      );
      return;
    }

    final rec = await _findStaffByName(first, last);
    if (rec != null) {
      setState(() {
        selectedStaffId = rec['id'] as int;
        selectedStaffName = '${rec['first_name']} ${rec['last_name']}';
        staffController.text = selectedStaffName!;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Staff found: $selectedStaffName')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No staff member found with that name.')),
      );
    }
  }

  Widget staffSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Staff Lookup (for Cash Payments)",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // email search row
        Row(
          children: [
            Expanded(
              child: TextInputField(
                label: "Staff Email (search)",
                controller: searchStaffEmailController,
                hint: "e.g. staff@example.com",
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 36,
              child: ElevatedButton(
                onPressed: _onSearchStaffByEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Search', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // name search row
        Row(
          children: [
            Expanded(
              child: TextInputField(
                label: "First Name",
                controller: searchStaffFNameController,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextInputField(
                label: "Last Name",
                controller: searchStaffLNameController,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 36,
              child: ElevatedButton(
                onPressed: _onSearchStaffByName,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Search', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (selectedStaffId != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Selected staff: $selectedStaffName (ID: $selectedStaffId)',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedStaffId = null;
                      selectedStaffName = null;
                      staffController.clear();
                      searchStaffEmailController.clear();
                      searchStaffFNameController.clear();
                      searchStaffLNameController.clear();
                    });
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),
        const Divider(),
      ],
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
    child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/imgs/bg_in.png"),
            fit: BoxFit.cover,
          )
        ),
        child: Column(
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
                            "Payment Form",
                            style: TextStyle(fontSize: 28, 
                            fontWeight: FontWeight.bold,
                            color: AppThemes.pageTitle),
                          ),
                          const Text(
                            "Log your Payment",
                            style: TextStyle(color: AppThemes.pageSubtitle, fontSize: 14),
                          ),

                          // download button
                          buttonsRow(),

                          // payment form
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

                            // form content
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  
                                  // Payment Information
                                  paymentInfo(),                                    
                                  SizedBox(height: 40),

                                  // Submit button
                                  Center( 
                                    child: ElevatedButton.icon(
                                      onPressed: _isSubmitting ? null : submitPayment,
                                      label: _isSubmitting
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : const Text(
                                              "Submit Payment",
                                              style: TextStyle(color: Colors.white),
                                            ),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                                        backgroundColor: Colors.black,
                                        minimumSize: const Size(100, 28),
                                      ),
                                    ),
                                  )

                                ],
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
      ),
      
      
    )
    );
  }

  // submit payment button
  Future<void> submitPayment() async {
    if (_isSubmitting) return;
    
    setState(() => _isSubmitting = true);

    try {
      debugPrint('=== [MemberPayment] Starting payment submission ===');
      
      // Validation
      if (selectedPaymentMethod == null) {
        _showError("Please select a payment method");
        return;
      }
      debugPrint('[MemberPayment] Payment method: $selectedPaymentMethod');

      final amountText = amountPaidController.text.trim();
      if (amountText.isEmpty) {
        _showError("Please enter the payment amount");
        return;
      }

      final amount = double.tryParse(amountText);
      if (amount == null || amount <= 0) {
        _showError("Please enter a valid amount");
        return;
      }
  debugPrint('[MemberPayment] Payment amount: ${ExportService.safeCurrency(amount)}');

      // Method-specific validation
      if (selectedPaymentMethod == 'Cash') {
        if (paymentDateController.text.trim().isEmpty) {
          _showError("Please enter the date of payment");
          return;
        }
        // Validate payment date is not in the past
        try {
          final dateParts = paymentDateController.text.split('/');
          if (dateParts.length == 3) {
            final payDate = DateTime(int.parse(dateParts[2]), int.parse(dateParts[0]), int.parse(dateParts[1]));
            final today = DateTime.now();
            final todayMidnight = DateTime(today.year, today.month, today.day);
            if (payDate.isBefore(todayMidnight)) {
              _showError("Payment date cannot be in the past.");
              return;
            }
          }
        } catch (e) {
          _showError("Invalid payment date format. Use MM/DD/YYYY");
          return;
        }
        if (selectedStaffId == null) {
          _showError("Please search and select a staff member handling the payment");
          return;
        }
        debugPrint('[MemberPayment] Cash payment - date: ${paymentDateController.text}, staff: $selectedStaffName (ID: $selectedStaffId)');
      } else if (selectedPaymentMethod == 'Gcash') {
        if (paymentDateController.text.trim().isEmpty) {
          _showError("Please enter the date of payment");
          return;
        }
        // Validate payment date is not in the past
        try {
          final dateParts = paymentDateController.text.split('/');
          if (dateParts.length == 3) {
            final payDate = DateTime(int.parse(dateParts[2]), int.parse(dateParts[0]), int.parse(dateParts[1]));
            final today = DateTime.now();
            final todayMidnight = DateTime(today.year, today.month, today.day);
            if (payDate.isBefore(todayMidnight)) {
              _showError("Payment date cannot be in the past.");
              return;
            }
          }
        } catch (e) {
          _showError("Invalid payment date format. Use MM/DD/YYYY");
          return;
        }
        if (refNoController.text.trim().isEmpty) {
          _showError("Please enter the GCash reference number");
          return;
        }
        // Validate GCash reference number (must be at least 13 digits)
        final refDigits = refNoController.text.replaceAll(RegExp(r'\D'), '');
        if (refDigits.length < 13) {
          _showError("GCash reference number must be at least 13 digits.");
          return;
        }
        if (proofOfPaymentFile == null) {
          _showError("Please upload screenshot of receipt");
          return;
        }
        debugPrint('[MemberPayment] GCash payment - date: ${paymentDateController.text}, ref: ${refNoController.text}');
      } else if (selectedPaymentMethod == 'Bank_Transfer') {
        if (paymentDateController.text.trim().isEmpty) {
          _showError("Please enter the bank deposit date");
          return;
        }
        // Validate bank deposit date is not in the past
        try {
          final dateParts = paymentDateController.text.split('/');
          if (dateParts.length == 3) {
            final depositDate = DateTime(int.parse(dateParts[2]), int.parse(dateParts[0]), int.parse(dateParts[1]));
            final today = DateTime.now();
            final todayMidnight = DateTime(today.year, today.month, today.day);
            if (depositDate.isBefore(todayMidnight)) {
              _showError("Bank deposit date cannot be in the past.");
              return;
            }
          }
        } catch (e) {
          _showError("Invalid bank deposit date format. Use MM/DD/YYYY");
          return;
        }
        if (bankNameController.text.trim().isEmpty) {
          _showError("Please enter the bank name");
          return;
        }
        debugPrint('[MemberPayment] Bank transfer - date: ${paymentDateController.text}, bank: ${bankNameController.text}');
      }

      // Get current user's member ID
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        _showError("No authenticated user found");
        return;
      }
      debugPrint('[MemberPayment] Current user email: ${currentUser.email}');

      // Fetch member record
      debugPrint('[MemberPayment] Querying members table for email: ${currentUser.email}');
      final memberRecord = await Supabase.instance.client
          .from('members')
          .select('id')
          .eq('email_address', currentUser.email!)
          .maybeSingle();

      if (memberRecord == null) {
        debugPrint('[MemberPayment] ❌ Member record NOT FOUND for email: ${currentUser.email}');
        _showError("Member record not found");
        return;
      }

      final memberId = memberRecord['id'] as int;
      debugPrint('[MemberPayment] ✓ Found member ID: $memberId');

      // Fetch member's active approved loan from approved_loans
      // Note: RLS policies automatically filter by user's email (member_email = get_auth_email())
      // So we don't need to filter by member_id - RLS does it for us
      debugPrint('[MemberPayment] Querying approved_loans with status=active (RLS filters by email automatically)');
      
      // Use .select() instead of .maybeSingle() to handle multiple active loans
      final loanRecords = await Supabase.instance.client
          .from('approved_loans')
          .select('application_id, repayment_term, loan_amount, status, member_id')
          .eq('status', 'active');

      debugPrint('[MemberPayment] Loan query result: $loanRecords');

      if ((loanRecords as List).isEmpty) {
        debugPrint('[MemberPayment] ❌ NO ACTIVE APPROVED LOAN found (after RLS filtering by email)');
        debugPrint('[MemberPayment] Checking if ANY approved loans exist for current user (any status)...');
        
        final anyLoans = await Supabase.instance.client
            .from('approved_loans')
            .select('application_id, status, member_id');
        
        debugPrint('[MemberPayment] All approved loans for current user: $anyLoans');
        
        _showError("No active approved loan found for this member");
        return;
      }

      // If multiple active loans, use the first one (or you could show a selection dialog)
      final loanList = loanRecords as List;
      if (loanList.length > 1) {
        debugPrint('[MemberPayment] ⚠️ WARNING: Found ${loanList.length} active loans. Using the first one.');
      }
      
      final loanRecord = loanList[0] as Map<String, dynamic>;
      final approvedLoanId = loanRecord['application_id'] as int;
      final loanMemberId = loanRecord['member_id'] as int;
      debugPrint('[MemberPayment] ✓ Found active approved loan: application_id=$approvedLoanId, member_id=$loanMemberId, amount=${loanRecord['loan_amount']}, term=${loanRecord['repayment_term']}');
      
      // Verify the loan belongs to the current member (sanity check)
      if (loanMemberId != memberId) {
        debugPrint('[MemberPayment] ⚠️ WARNING: Loan member_id ($loanMemberId) does not match current member_id ($memberId)');
      }
      // Note: repayment_term and loan_amount can be used for validation if needed

      // Calculate installment number based on existing payments
      // Note: DB trigger handles this automatically, but we'll query for verification
      debugPrint('[MemberPayment] Counting existing payments for approved_loan_id=$approvedLoanId');
      final existingPaymentsResp = await Supabase.instance.client
          .from('payments')
          .select('payment_id')
          .eq('approved_loan_id', approvedLoanId);      final installmentNumber = (existingPaymentsResp as List).length + 1;
      debugPrint('[MemberPayment] Existing payments count: ${(existingPaymentsResp as List).length}, next installment: $installmentNumber');

      // Parse payment date (for Cash and Bank_Transfer)
      DateTime? paymentDate;
      if (selectedPaymentMethod == 'Cash' || selectedPaymentMethod == 'Bank_Transfer') {
        try {
          final dateParts = paymentDateController.text.split('/');
          if (dateParts.length == 3) {
            paymentDate = DateTime(
              int.parse(dateParts[2]),
              int.parse(dateParts[0]),
              int.parse(dateParts[1]),
            );
          }
        } catch (_) {
          _showError("Invalid date format. Use MM/DD/YYYY");
          return;
        }
      }

      // Handle GCash screenshot upload
      String? gcashScreenshotPath;
      if (selectedPaymentMethod == 'Gcash' && proofOfPaymentFile != null) {
        // Get authenticated user ID
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId == null) {
          _showError('User authentication required for file upload');
          return;
        }

        // Sanitize filename: lowercase, replace spaces, remove special chars
        String sanitizedFilename = proofOfPaymentFile!.name
            .toLowerCase()
            .replaceAll(' ', '_')
            .replaceAll(RegExp(r'[^a-z0-9._-]'), '');
        
        // Add timestamp to prevent collisions
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        
        // Build path: USER_UUID/receipts/TIMESTAMP_filename.ext
        final filePath = '$userId/receipts/${timestamp}_$sanitizedFilename';
        
        debugPrint('[MemberPayment] Uploading receipt to: $filePath');
        
        final bytes = await proofOfPaymentFile!.readAsBytes();

        try {
          // Upload binary to user-specific folder
          await Supabase.instance.client.storage
              .from('payment_receipts')
              .uploadBinary(filePath, bytes);

          debugPrint('[MemberPayment] ✓ File uploaded successfully');
          
          // Store the path for database reference
          gcashScreenshotPath = filePath;

          // Try to get public URL (works if bucket is public). Be defensive about return types.
          try {
            final publicUrlRes = Supabase.instance.client.storage
                .from('payment_receipts')
                .getPublicUrl(filePath);
            
            debugPrint('[MemberPayment] Public URL: $publicUrlRes');
            // Store public URL if available, otherwise use path
            if (publicUrlRes.isNotEmpty) {
              gcashScreenshotPath = publicUrlRes;
            }
          } catch (e) {
            debugPrint('[MemberPayment] Could not get public URL, using path instead: $e');
            // Keep using filePath as fallback
          }
        } catch (e) {
          debugPrint('[MemberPayment] Upload error details: $e');
          _showError('Failed to upload screenshot: $e');
          return;
        }
      }

      // Lookup staff ID for Cash payments
      int? staffId;
      if (selectedPaymentMethod == 'Cash') {
        staffId = selectedStaffId; // Use the staff ID from search
        debugPrint('[MemberPayment] Using selected staff_id=$staffId ($selectedStaffName)');
      }

      // Prepare payment payload
      final Map<String, dynamic> paymentPayload = {
        'approved_loan_id': approvedLoanId,
        'amount': amount,
        'installment_number': installmentNumber,
        'payment_type': selectedPaymentMethod,
        'status': 'Pending Approval',
      };

      if (staffId != null) {
        paymentPayload['staff_id'] = staffId;
        debugPrint('[MemberPayment] Added staff_id=$staffId to payload');
      }

      if (paymentDate != null) {
        paymentPayload['payment_date'] = paymentDate.toIso8601String();
        debugPrint('[MemberPayment] Added payment_date=${paymentDate.toIso8601String()}');
      }

      if (selectedPaymentMethod == 'Bank_Transfer') {
        paymentPayload['bank_deposit_date'] = paymentDate?.toIso8601String();
        paymentPayload['bank_name'] = bankNameController.text.trim();
        debugPrint('[MemberPayment] Added bank transfer details');
      }

      if (selectedPaymentMethod == 'Gcash') {
        paymentPayload['gcash_reference'] = refNoController.text.trim();
        paymentPayload['bank_deposit_date'] = paymentDate?.toIso8601String();
        paymentPayload['bank_name'] = 'GCash';
        if (gcashScreenshotPath != null) {
          paymentPayload['gcash_screenshot_path'] = gcashScreenshotPath;
          debugPrint('[MemberPayment] Added GCash screenshot path: $gcashScreenshotPath');
        }
        debugPrint('[MemberPayment] Added GCash details: date=${paymentDate?.toIso8601String()}, bank_name=GCash');
      }

      // Insert payment record
      debugPrint('[MemberPayment] Inserting payment record into payments table...');
      debugPrint('[MemberPayment] Payload: $paymentPayload');
      
      final insertResult = await Supabase.instance.client
          .from('payments')
          .insert(paymentPayload)
          .select();
      
      debugPrint('[MemberPayment] ✓ Payment inserted successfully: $insertResult');
      debugPrint('=== [MemberPayment] Payment submission completed ===');

      // Show success dialog
      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: const Text('Payment submitted successfully and is pending validation.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Reset form
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MemberPaymentForm()),
                );
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );

    } catch (e) {
      debugPrint('Payment submission error: $e');
      _showError('Failed to submit payment: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

}