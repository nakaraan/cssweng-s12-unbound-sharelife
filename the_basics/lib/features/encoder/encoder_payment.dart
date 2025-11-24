import 'package:flutter/material.dart';
import 'package:the_basics/core/widgets/top_navbar.dart';
import 'package:the_basics/core/widgets/side_menu.dart';
import 'package:the_basics/core/widgets/input_fields.dart';
import 'package:the_basics/core/widgets/export_dropdown_button.dart';
import 'package:the_basics/core/utils/export_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_basics/core/utils/themes.dart';


class EncoderPaymentForm extends StatefulWidget {
  const EncoderPaymentForm({super.key});

  @override
  State<EncoderPaymentForm> createState() => _EncoderPaymentFormState();
}

class _EncoderPaymentFormState extends State<EncoderPaymentForm> {
  
  // Payment Information
  String? selectedPaymentMethod;
  final TextEditingController amountPaidController = TextEditingController();
  final TextEditingController paymentDateController = TextEditingController();

  // Payment Information
  final TextEditingController staffController = TextEditingController();
  final TextEditingController refNoController = TextEditingController();
  final TextEditingController receiptController = TextEditingController();
  final TextEditingController bankNameController = TextEditingController();
  
  // Member Information
  final TextEditingController memberNameController = TextEditingController();
  final TextEditingController memberIdController = TextEditingController();
  final TextEditingController memberSearchController = TextEditingController();
  
  // Auto-populated fields
  int? selectedMemberId;
  String? selectedMemberEmail; // Store member email for approved_loans query
  int? currentEncoderStaffId;
  String? currentEncoderName;
  
  // File upload
  final ImagePicker _picker = ImagePicker();
  XFile? proofOfPaymentFile;
  
  bool _isSubmitting = false;
  bool _isSearching = false;
  List<Map<String, dynamic>> memberSearchResults = [];

  @override
  void initState() {
    super.initState();
    _loadEncoderStaffId();
  }

  Future<void> _loadEncoderStaffId() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        final staffRecord = await Supabase.instance.client
            .from('staff')
            .select('id, first_name, last_name')
            .eq('email_address', currentUser.email!)
            .maybeSingle();
        
        if (staffRecord != null) {
          final firstName = staffRecord['first_name'] as String? ?? '';
          final lastName = staffRecord['last_name'] as String? ?? '';
          final fullName = '$firstName $lastName'.trim();
          
          setState(() {
            currentEncoderStaffId = staffRecord['id'] as int;
            currentEncoderName = fullName;
            staffController.text = fullName; // Pre-fill the staff field
          });
          debugPrint('[EncoderPayment] Loaded encoder staff ID: $currentEncoderStaffId, Name: $fullName');
        }
      }
    } catch (e) {
      debugPrint('[EncoderPayment] Error loading encoder staff ID: $e');
    }
  }

  Future<void> _searchMember(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        memberSearchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      debugPrint('[EncoderPayment] Searching for member: $query');
      
      // Search by ID or name
      final results = await Supabase.instance.client
          .from('members')
          .select('id, first_name, last_name, email_address')
          .or('id.eq.${int.tryParse(query) ?? -1},first_name.ilike.%$query%,last_name.ilike.%$query%')
          .limit(10);

      setState(() {
        memberSearchResults = (results as List).cast<Map<String, dynamic>>();
        _isSearching = false;
      });
      
      debugPrint('[EncoderPayment] Found ${memberSearchResults.length} members');
    } catch (e) {
      debugPrint('[EncoderPayment] Error searching members: $e');
      setState(() => _isSearching = false);
    }
  }

  void _selectMember(Map<String, dynamic> member) {
    setState(() {
      selectedMemberId = member['id'] as int;
      selectedMemberEmail = member['email_address'] as String?; // Store email for approved_loans query
      memberIdController.text = selectedMemberId.toString();
      memberNameController.text = '${member['first_name']} ${member['last_name']}';
      memberSearchController.clear();
      memberSearchResults = [];
    });
    debugPrint('[EncoderPayment] Selected member: ID=$selectedMemberId, Email=$selectedMemberEmail, Name=${memberNameController.text}');
  }


  Widget buttonsRow() {
    return Row(
      children: [
        Spacer(),
        ExportDropdownButton(
          height: 28,
          minWidth: 100,
          onExportPdf: () async {
            final rows = [{
              'field': 'Member Name',
              'value': memberNameController.text,
            }, {
              'field': 'Member ID',
              'value': memberIdController.text,
            }, {
              'field': 'Amount Paid',
              'value': amountPaidController.text,
            }, {
              'field': 'Payment Date',
              'value': paymentDateController.text,
            }, {
              'field': 'Payment Method',
              'value': selectedPaymentMethod ?? 'N/A',
            }, {
              'field': 'Staff/Encoder',
              'value': staffController.text,
            }, {
              'field': 'Reference Number',
              'value': refNoController.text,
            }, {
              'field': 'Receipt Number',
              'value': receiptController.text,
            }, {
              'field': 'Bank Name',
              'value': bankNameController.text,
            }];
            
            await ExportService.exportAndSharePdf(
              context: context,
              rows: rows,
              title: 'Payment Form',
              filename: 'payment_form_${DateTime.now().millisecondsSinceEpoch}.pdf',
              columnOrder: ['field', 'value'],
              columnHeaders: {'field': 'Field', 'value': 'Value'},
            );
          },
          onExportXlsx: () async {
            final rows = [{
              'field': 'Member Name',
              'value': memberNameController.text,
            }, {
              'field': 'Member ID',
              'value': memberIdController.text,
            }, {
              'field': 'Amount Paid',
              'value': amountPaidController.text,
            }, {
              'field': 'Payment Date',
              'value': paymentDateController.text,
            }, {
              'field': 'Payment Method',
              'value': selectedPaymentMethod ?? 'N/A',
            }, {
              'field': 'Staff/Encoder',
              'value': staffController.text,
            }, {
              'field': 'Reference Number',
              'value': refNoController.text,
            }, {
              'field': 'Receipt Number',
              'value': receiptController.text,
            }, {
              'field': 'Bank Name',
              'value': bankNameController.text,
            }];
            
            await ExportService.exportAndShareExcel(
              context: context,
              rows: rows,
              filename: 'payment_form_${DateTime.now().millisecondsSinceEpoch}.xlsx',
              sheetName: 'Payment Form',
              columnOrder: ['field', 'value'],
              columnHeaders: {'field': 'Field', 'value': 'Value'},
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
                child: DateInputField(
                  label: "Date of Payment",
                  controller: paymentDateController,
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
                child: TextInputField(
                  label: "Reference Number", 
                  controller: refNoController,
                  hint: "",
                ),
              ),
              SizedBox(width: 16),
              
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
                child: DateInputField(
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

  Widget memberInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Member Information",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),

        // Member Search Field
        Text(
          "Search Member",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8),
        TextField(
          controller: memberSearchController,
          decoration: InputDecoration(
            hintText: "Enter member name or ID",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            suffixIcon: _isSearching 
                ? Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Icon(Icons.search),
          ),
          onChanged: (value) {
            _searchMember(value);
          },
        ),
        
        // Search Results Dropdown
        if (memberSearchResults.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: 4),
            constraints: BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: memberSearchResults.length,
              itemBuilder: (context, index) {
                final member = memberSearchResults[index];
                return ListTile(
                  dense: true,
                  title: Text('${member['first_name']} ${member['last_name']}'),
                  subtitle: Text('ID: ${member['id']} • ${member['email_address']}'),
                  onTap: () => _selectMember(member),
                  hoverColor: Colors.grey.shade100,
                );
              },
            ),
          ),

        SizedBox(height: 16),

        // Member Name & Member ID (Read-only, auto-populated)
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Member Name",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: memberNameController,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: "Auto-populated from search",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Member ID",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: memberIdController,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: "Auto-populated from search",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    child: Column(
        children: [

          // top nav bar
          const TopNavBar(splash: "Encoder"),

          // main area
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // sidebar
                const SideMenu(role: "Encoder"),

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
                            "Encode a Payment",
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

                                  // Member Information
                                  memberInfo(),
                                  SizedBox(height: 18),

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
                                              style: TextStyle(color: AppThemes.buttonText),
                                            ),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                                        backgroundColor: AppThemes.outerformButton,
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
      
    )
    );
  }

  // Submit Payment Function (Encoder version - requires member lookup)
  Future<void> submitPayment() async {
    if (_isSubmitting) return;
    
    setState(() => _isSubmitting = true);

    try {
      debugPrint('=== [EncoderPayment] Starting payment submission ===');
      
      // Validation - Member Info
      if (selectedMemberId == null) {
        _showError("Please search and select a member first");
        return;
      }

      final memberId = selectedMemberId!;
      debugPrint('[EncoderPayment] Target member ID: $memberId');

      // Validation - Payment Info
      if (selectedPaymentMethod == null) {
        _showError("Please select a payment method");
        return;
      }
      debugPrint('[EncoderPayment] Payment method: $selectedPaymentMethod');

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
  debugPrint('[EncoderPayment] Payment amount: ${ExportService.safeCurrency(amount)}');

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
        debugPrint('[EncoderPayment] Cash payment - date: ${paymentDateController.text}');
      } else if (selectedPaymentMethod == 'Gcash') {
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
        debugPrint('[EncoderPayment] GCash payment - ref: ${refNoController.text}');
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
        debugPrint('[EncoderPayment] Bank transfer - date: ${paymentDateController.text}, bank: ${bankNameController.text}');
      }

      // Verify member exists
      debugPrint('[EncoderPayment] Verifying member exists with ID: $memberId');
      final memberRecord = await Supabase.instance.client
          .from('members')
          .select('id')
          .eq('id', memberId)
          .maybeSingle();

      if (memberRecord == null) {
        debugPrint('[EncoderPayment] Member NOT FOUND with ID: $memberId');
        _showError("Member with ID $memberId not found");
        return;
      }
      debugPrint('[EncoderPayment] ✓ Member verified');

      // Fetch member's active approved loan from approved_loans
      // For MEMBERS: RLS auto-filters approved_loans by their email (get_auth_email())
      // For ENCODERS: We're authenticated as staff, so RLS may block. We query by member_id.
      // If RLS blocks this, the DB admin needs to add a policy allowing staff to SELECT approved_loans
      
      debugPrint('[EncoderPayment] Querying approved_loans for member_id=$memberId with status=active');
      
      // Use .select() instead of .maybeSingle() to handle multiple active loans
      final loanRecords = await Supabase.instance.client
          .from('approved_loans')
          .select('application_id, repayment_term, loan_amount, status, member_id, member_email')
          .eq('member_id', memberId)
          .eq('status', 'active');

      debugPrint('[EncoderPayment] Loan query result: $loanRecords');

      if ((loanRecords as List).isEmpty) {
        debugPrint('[EncoderPayment] ❌ NO ACTIVE APPROVED LOAN found for member_id=$memberId');
        debugPrint('[EncoderPayment] This could be due to:');
        debugPrint('[EncoderPayment]   1. Member has no active approved loan');
        debugPrint('[EncoderPayment]   2. RLS policies blocking staff from reading approved_loans');
        debugPrint('[EncoderPayment] Checking if ANY approved loans exist for this member (any status)...');
        
        final anyLoans = await Supabase.instance.client
            .from('approved_loans')
            .select('application_id, status, member_id, member_email')
            .eq('member_id', memberId);
        
        debugPrint('[EncoderPayment] All approved loans for member_id=$memberId: $anyLoans');
        
        if (anyLoans.isEmpty) {
          _showError("No approved loans found for member ID $memberId. Member may need to apply for a loan first.");
        } else {
          _showError("Member has loans but none are 'active'. Check loan statuses or contact admin about RLS policies.");
        }
        return;
      }

      // If multiple active loans, use the first one (or you could show a selection dialog)
      final loanList = loanRecords as List;
      if (loanList.length > 1) {
        debugPrint('[EncoderPayment] ⚠️ WARNING: Found ${loanList.length} active loans for member_id=$memberId. Using the first one.');
      }
      
      final loanRecord = loanList[0] as Map<String, dynamic>;
      final approvedLoanId = loanRecord['application_id'] as int;
      final loanMemberId = loanRecord['member_id'] as int;
      debugPrint('[EncoderPayment] ✓ Found active approved loan: application_id=$approvedLoanId, member_id=$loanMemberId, amount=${loanRecord['loan_amount']}, term=${loanRecord['repayment_term']}');
      
      // Verify the loan belongs to the selected member (sanity check)
      if (loanMemberId != memberId) {
        debugPrint('[EncoderPayment] ⚠️ WARNING: Loan member_id ($loanMemberId) does not match selected member_id ($memberId)');
      }

      // Calculate installment number based on existing payments
      // Note: DB trigger handles this automatically, but we'll query for verification
      debugPrint('[EncoderPayment] Counting existing payments for approved_loan_id=$approvedLoanId');
      final existingPaymentsResp = await Supabase.instance.client
          .from('payments')
          .select('payment_id')
          .eq('approved_loan_id', approvedLoanId);

      final installmentNumber = (existingPaymentsResp as List).length + 1;
      debugPrint('[EncoderPayment] Existing payments count: ${(existingPaymentsResp as List).length}, next installment: $installmentNumber');

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
        // Get authenticated user ID (the encoder/staff user uploading on behalf of member)
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
        
        debugPrint('[EncoderPayment] Uploading receipt to: $filePath');
        
        final bytes = await proofOfPaymentFile!.readAsBytes();
        
        try {
          // Upload binary to user-specific folder
          await Supabase.instance.client.storage
              .from('payment_receipts')
              .uploadBinary(filePath, bytes);

          debugPrint('[EncoderPayment] ✓ File uploaded successfully');
          
          // Store the path for database reference
          gcashScreenshotPath = filePath;

          // Try to get public URL (works if bucket is public)
          try {
            final publicUrlRes = Supabase.instance.client.storage
                .from('payment_receipts')
                .getPublicUrl(filePath);
            
            debugPrint('[EncoderPayment] Public URL: $publicUrlRes');
            // Store public URL if available, otherwise use path
            if (publicUrlRes.isNotEmpty) {
              gcashScreenshotPath = publicUrlRes;
            }
          } catch (e) {
            debugPrint('[EncoderPayment] Could not get public URL, using path instead: $e');
            // Keep using filePath as fallback
          }
        } catch (e) {
          debugPrint('[EncoderPayment] Upload error details: $e');
          _showError('Failed to upload screenshot: $e');
          return;
        }
      }

      // Use current encoder's staff ID
      final staffId = currentEncoderStaffId;
      
      if (staffId != null) {
        debugPrint('[EncoderPayment] Using encoder staff ID: $staffId');
      } else {
        debugPrint('[EncoderPayment] Warning: No staff ID available');
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
        debugPrint('[EncoderPayment] Added staff_id=$staffId to payload');
      }

      if (paymentDate != null) {
        paymentPayload['payment_date'] = paymentDate.toIso8601String();
        debugPrint('[EncoderPayment] Added payment_date=${paymentDate.toIso8601String()}');
      }

      if (selectedPaymentMethod == 'Bank_Transfer') {
        paymentPayload['bank_deposit_date'] = paymentDate?.toIso8601String();
        paymentPayload['bank_name'] = bankNameController.text.trim();
        debugPrint('[EncoderPayment] Added bank transfer details');
      }

      if (selectedPaymentMethod == 'Gcash') {
        paymentPayload['gcash_reference'] = refNoController.text.trim();
        if (gcashScreenshotPath != null) {
          paymentPayload['gcash_screenshot_path'] = gcashScreenshotPath;
          debugPrint('[EncoderPayment] Added GCash screenshot path: $gcashScreenshotPath');
        }
      }

      // Insert payment record
      debugPrint('[EncoderPayment] Inserting payment record into payments table...');
      debugPrint('[EncoderPayment] Payload: $paymentPayload');
      
      final insertResult = await Supabase.instance.client
          .from('payments')
          .insert(paymentPayload)
          .select();
      
      debugPrint('[EncoderPayment] ✓ Payment inserted successfully: $insertResult');
      debugPrint('=== [EncoderPayment] Payment submission completed ===');

      // Show success dialog
      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: Text('Payment for Member ID $memberId submitted successfully and is pending validation.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Reset form
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const EncoderPaymentForm()),
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