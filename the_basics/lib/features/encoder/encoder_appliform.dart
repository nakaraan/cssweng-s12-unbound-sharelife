import 'package:flutter/material.dart';
import 'package:the_basics/core/widgets/top_navbar.dart';
import 'package:the_basics/core/widgets/side_menu.dart';
import 'package:the_basics/core/widgets/input_fields.dart';
import 'package:the_basics/core/widgets/export_dropdown_button.dart';
import 'package:the_basics/core/utils/export_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_basics/features/encoder/encoder_member_register.dart';
import 'package:the_basics/core/utils/themes.dart';

class EncAppliform extends StatefulWidget {
  const EncAppliform({super.key});

  @override
  State<EncAppliform> createState() => _EncAppliformState();
}

class _EncAppliformState extends State<EncAppliform> {

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  final TextEditingController appliDateController = TextEditingController();
  
  // loan info
  final TextEditingController loanAmtController = TextEditingController();
  final TextEditingController anlIncController = TextEditingController();
  final TextEditingController instController = TextEditingController();
  final TextEditingController termController = TextEditingController();
  final TextEditingController businessController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
  
  // personal info
  final TextEditingController fNameController = TextEditingController();
  final TextEditingController lNameController = TextEditingController();
  final TextEditingController bDateController = TextEditingController();
  
  // loan co-maker
  final TextEditingController spouseFNameController = TextEditingController();
  final TextEditingController spouseLNameController = TextEditingController();
  final TextEditingController childFNameController = TextEditingController();
  final TextEditingController childLNameController = TextEditingController();
  final TextEditingController comakerContactController = TextEditingController();
  final TextEditingController groupController = TextEditingController();
  
  // contact info
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneNumController = TextEditingController();
  final TextEditingController addrController = TextEditingController();
  bool agreeTerms = false;

  // member search controllers / state
  final TextEditingController searchEmailController = TextEditingController();
  final TextEditingController searchFNameController = TextEditingController();
  final TextEditingController searchLNameController = TextEditingController();
  final TextEditingController searchBDateController = TextEditingController();
  int? selectedMemberId;
  String? selectedMemberName;
  String? staffSearchError;
  bool _selectedMemberHasPending = false;
  bool _selectedMemberHasActive = false;
  bool _checkingSelectedMemberStatus = false;

  // validation limits (adjust as needed)
  static const int minLoanAmount = 1000;
  static const int maxLoanAmount = 3000;
  static const int minAnnualIncome = 0;
  static const int maxAnnualIncome = 10000000;

  final RegExp _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  bool _isValidPhilippinePhone(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11 && digits.startsWith('09')) return true;
    if (digits.length == 12 && digits.startsWith('63')) return true; // +63 9XXXXXXXXX -> digits start with 63
    return false;
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final year = now.year.toString();
    appliDateController.text = "$month-$day-$year";
  }

  // Safely parse numeric-like strings into a number (double). Returns 0 on failure.
  num _toNum(dynamic v) {
    if (v == null) return 0;
    final s = v.toString();
    final cleaned = s.replaceAll(RegExp(r"[^0-9.\-]"), '');
    if (cleaned.isEmpty) return 0;
    return double.tryParse(cleaned) ?? 0;
  }


  Widget buttonsRow() {
    return Row(
      children: [
        Spacer(),
        ExportDropdownButton(
          height: 28,
          minWidth: 100,
          onExportPdf: () async {
            // Build loan application data from form
              final Map<String, dynamic> applicationData = {
              'application_date': appliDateController.text,
              'first_name': fNameController.text,
              'last_name': lNameController.text,
              'middle_name': '',
              'date_of_birth': bDateController.text,
              'address': addrController.text,
              'phone': phoneNumController.text,
              'email': emailController.text,
              'loan_amount': _toNum(loanAmtController.text),
              'annual_income': _toNum(anlIncController.text),
              'loan_type': instController.text,
              'loan_purpose': reasonController.text,
              'payment_term': termController.text,
              'business_name': businessController.text,
              'comaker_contact_no': comakerContactController.text,
              'spouse_first_name': spouseFNameController.text,
              'spouse_last_name': spouseLNameController.text,
              'child_first_name': childFNameController.text,
              'child_last_name': childLNameController.text,
              'group_affiliation': groupController.text,
            };
            
            try {
              final bytes = await ExportService.buildLoanApplicationPdf(applicationData);
              final result = await ExportService.sharePdf(bytes, 
                filename: 'loan_application_${fNameController.text}_${lNameController.text}_${DateTime.now().millisecondsSinceEpoch}.pdf'
              );
              if (result.contains('/') || result.contains('\\')) {
                ExportService.showExportMessage(context, 'Loan Application PDF saved to: $result');
              } else {
                ExportService.showExportMessage(context, 'Loan Application PDF exported successfully');
              }
            } catch (e) {
              ExportService.showExportMessage(context, 'Export failed: $e');
            }
          },
          onExportXlsx: () async {
            final rows = [{
              'field': 'Application Date',
              'value': appliDateController.text,
            }, {
              'field': 'First Name',
              'value': fNameController.text,
            }, {
              'field': 'Last Name',
              'value': lNameController.text,
            }, {
              'field': 'Date of Birth',
              'value': bDateController.text,
            }, {
              'field': 'Address',
              'value': addrController.text,
            }, {
              'field': 'Phone Number',
              'value': phoneNumController.text,
            }, {
              'field': 'Email',
              'value': emailController.text,
            }, {
              'field': 'Loan Amount',
              'value': _toNum(loanAmtController.text),
            }, {
              'field': 'Annual Income',
              'value': _toNum(anlIncController.text),
            }, {
              'field': 'Installment Type',
              'value': instController.text,
            }, {
              'field': 'Repayment Term',
              'value': termController.text,
            }, {
              'field': 'Business Name',
              'value': businessController.text,
            }, {
              'field': 'Loan Reason/Purpose',
              'value': reasonController.text,
            }, {
              'field': 'Co-maker Contact',
              'value': comakerContactController.text,
            }, {
              'field': 'Spouse First Name',
              'value': spouseFNameController.text,
            }, {
              'field': 'Spouse Last Name',
              'value': spouseLNameController.text,
            }, {
              'field': 'Child First Name',
              'value': childFNameController.text,
            }, {
              'field': 'Child Last Name',
              'value': childLNameController.text,
            }, {
              'field': 'Group Affiliation',
              'value': groupController.text,
            }];
            
            await ExportService.exportAndShareExcel(
              context: context,
              rows: rows,
              filename: 'loan_application_${fNameController.text}_${lNameController.text}_${DateTime.now().millisecondsSinceEpoch}.xlsx',
              sheetName: 'Loan Application',
              columnOrder: ['field', 'value'],
              columnHeaders: {'field': 'Field', 'value': 'Value'},
            );
          },
        ),
      ]
    );
  }

  Widget memberSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Member Lookup",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // Email search row
        Row(
          children: [
            Expanded(
              child: TextInputField(
                label: "Member Email (search)",
                controller: searchEmailController,
                hint: "e.g. member@example.com",
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(onPressed: _onSearchByEmail, child: const Text('Search')),
          ],
        ),

        // small subtext to show staff-related error
        if (staffSearchError != null) ...[
          const SizedBox(height: 6),
          Text(
            staffSearchError!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],

        const SizedBox(height: 12),

        // Name + DOB search row
        Row(
          children: [
            Expanded(
              child: TextInputField(
                label: "First Name",
                controller: searchFNameController,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextInputField(
                label: "Last Name",
                controller: searchLNameController,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 200,
              child: DateInputField(
                label: "Birth Date (search)",
                controller: searchBDateController,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(onPressed: _onSearchByNameDob, child: const Text('Search')),
          ],
        ),

        const SizedBox(height: 12),

        if (selectedMemberId != null) ...[
          Row(
            children: [
              Expanded(child: Text('Selected member: ${selectedMemberName ?? "ID#${selectedMemberId!}"}')),
              TextButton(onPressed: () { setState(() { selectedMemberId = null; selectedMemberName = null; phoneNumController.text = ''; }); }, child: const Text('Clear')),
            ],
          ),
        ],

        const Divider(),
      ],
    );
  }

  // --- Member search helpers
  Future<Map<String, dynamic>?> _findMemberByEmail(String email) async {
    if (email.trim().isEmpty) return null;
    try {
      final rec = await Supabase.instance.client
          .from('members')
          .select('id, first_name, last_name, date_of_birth, email_address, contact_no')
          .eq('email_address', email.trim().toLowerCase())
          .maybeSingle();
      if (rec == null) return null;
      return Map<String, dynamic>.from(rec as Map);
    } catch (e) {
      debugPrint('Error searching member by email: $e');
      return null;
    }
  }

  Future<void> _onSearchByEmail() async {
    final email = searchEmailController.text.trim().toLowerCase();
    setState(() { staffSearchError = null; });
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter an email to search.')));
      return;
    }

    // Check staff table specifically — staff cannot have loans
    try {
      final staffRec = await Supabase.instance.client.from('staff').select('id').eq('email_address', email).maybeSingle();
      if (staffRec != null) {
        setState(() {
          staffSearchError = 'This email belongs to a staff account — staff cannot have loans.';
        });
        return;
      }
    } catch (e) {
      debugPrint('Error checking staff table: $e');
    }

    // Not staff — try to find member
    final rec = await _findMemberByEmail(email);
    if (rec != null) {
      await _showFoundMemberDialog(rec);
    } else {
      final create = await _showNotFoundDialog();
      if (create == true) await _navigateToCreateMember();
    }
  }

  Future<Map<String, dynamic>?> _findMemberByNameDob(String first, String last, String dobText) async {
    if (first.trim().isEmpty || last.trim().isEmpty || dobText.trim().isEmpty) return null;
    try {
      String iso = dobText;
      try {
        final parts = dobText.split('/');
        if (parts.length == 3) {
          final m = int.parse(parts[0]);
          final d = int.parse(parts[1]);
          final y = int.parse(parts[2]);
          iso = DateTime(y, m, d).toIso8601String().split('T').first;
        }
      } catch (_) {}

      final rec = await Supabase.instance.client
          .from('members')
          .select('id, first_name, last_name, date_of_birth, email_address, contact_no')
          .eq('first_name', first.trim())
          .eq('last_name', last.trim())
          .eq('date_of_birth', iso)
          .maybeSingle();
      if (rec == null) return null;
      return Map<String, dynamic>.from(rec as Map);
    } catch (e) {
      debugPrint('Error searching member by name/dob: $e');
      return null;
    }
  }

  Future<void> _onSearchByNameDob() async {
    final first = searchFNameController.text.trim();
    final last = searchLNameController.text.trim();
    final dob = searchBDateController.text.trim();
    if (first.isEmpty || last.isEmpty || dob.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Provide first name, last name and birth date to search.')));
      return;
    }
    final rec = await _findMemberByNameDob(first, last, dob);
    if (rec != null) {
      await _showFoundMemberDialog(rec);
    } else {
      final create = await _showNotFoundDialog();
      if (create == true) await _navigateToCreateMember();
    }
  }

  Future<void> _showFoundMemberDialog(Map<String, dynamic> rec) async {
    final id = rec['id'];
    final fname = rec['first_name'] ?? '';
    final lname = rec['last_name'] ?? '';
    final email = rec['email_address'] ?? '';
    final contact = rec['contact_no'] ?? '';
    final dobRaw = rec['date_of_birth'];
    String dobPretty = '';
    try {
      if (dobRaw != null) {
        final dt = DateTime.parse(dobRaw.toString());
        dobPretty = "${dt.month}/${dt.day}/${dt.year}";
      }
    } catch (_) {}

    final use = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Existing member found'),
        content: Text('Existing member: $fname $lname — ID#$id\n$email\nPhone: $contact\nDOB: $dobPretty\n\nUse this record?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Create new')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Use this')),
        ],
      ),
    );

    if (use == true) {
      setState(() {
        selectedMemberId = id is int ? id : int.tryParse(id.toString());
        selectedMemberName = '$fname $lname';
        // autofill fields including contact number
        fNameController.text = fname;
        lNameController.text = lname;
        if (dobPretty.isNotEmpty) bDateController.text = dobPretty;
        emailController.text = email;
        phoneNumController.text = contact;
      });
      debugPrint('[EncoderAppliform] Selected member: id=$selectedMemberId name=$selectedMemberName email=$email');
      // check loan status for this selected member and show frontend error if needed
      if (selectedMemberId != null) {
        setState(() { _checkingSelectedMemberStatus = true; });
        await _checkLoanStatusForMember(selectedMemberId!);
        debugPrint('[EncoderAppliform] Finished loan status check for member: $selectedMemberId (pending=$_selectedMemberHasPending active=$_selectedMemberHasActive)');
        if (mounted) setState(() { _checkingSelectedMemberStatus = false; });
      }
    }
  }

  Future<void> _checkLoanStatusForMember(int memberId) async {
    try {
      debugPrint('[EncoderAppliform] Checking loan status for memberId=$memberId');

      // Mirror mem_appliform: use limit(1) to get a list and check isNotEmpty
      final pending = await Supabase.instance.client
          .from('loan_application')
          .select('application_id')
          .eq('member_id', memberId)
          .eq('status', 'Pending')
          .limit(1) as List<dynamic>;

      final active = await Supabase.instance.client
          .from('approved_loans')
          .select('application_id')
          .eq('member_id', memberId)
          .eq('status', 'active')
          .limit(1) as List<dynamic>;

      debugPrint('[EncoderAppliform] loan_application query returned ${pending.length} rows for memberId=$memberId');
      if (pending.isNotEmpty) debugPrint('[EncoderAppliform] pending record: ${pending.first}');
      debugPrint('[EncoderAppliform] approved_loans query returned ${active.length} rows for memberId=$memberId');
      if (active.isNotEmpty) debugPrint('[EncoderAppliform] active record: ${active.first}');

      if (mounted) setState(() {
        _selectedMemberHasPending = pending.isNotEmpty;
        _selectedMemberHasActive = active.isNotEmpty;
      });

    } catch (e) {
      debugPrint('Error checking loan status for member $memberId: $e');
      if (mounted) setState(() {
        _selectedMemberHasPending = false;
        _selectedMemberHasActive = false;
      });
    }
  }

  Future<bool?> _showNotFoundDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Member not found'),
        content: const Text('No existing member found. Would you like to create a new member account?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Create new'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToCreateMember() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const EncoderMemberRegisterPage()),
    );

    if (result != null && result['member_id'] != null) {
      // autofill fields
      setState(() {
        selectedMemberId = result['member_id'];
        selectedMemberName = '${result['first_name']} ${result['last_name']}';
        fNameController.text = result['first_name'] ?? '';
        lNameController.text = result['last_name'] ?? '';
        bDateController.text = result['date_of_birth'] ?? '';
        emailController.text = result['email_address'] ?? '';
        phoneNumController.text = result['contact_no'] ?? '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Member "$selectedMemberName" created and selected.')),
      );
    }
  }

  // submit handler: insert into temporary_loan_information
  Future<void> submitForm() async {
    // Validate form fields first
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all required fields.')));
      return;
    }
    // require selected member
    if (selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select or create a member before submitting an application.')));
      return;
    }

    // Validate application date is not in the past
    try {
      final appDateParts = appliDateController.text.split('-');
      if (appDateParts.length == 3) {
        final appDate = DateTime(int.parse(appDateParts[2]), int.parse(appDateParts[0]), int.parse(appDateParts[1]));
        final today = DateTime.now();
        final todayMidnight = DateTime(today.year, today.month, today.day);
        if (appDate.isBefore(todayMidnight)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Application date cannot be in the past.'))
          );
          return;
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid application date format.'))
      );
      return;
    }

    // Validate loan amount is positive (minimum 1)
    final loanAmountText = loanAmtController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final loanAmount = int.tryParse(loanAmountText);
    if (loanAmount == null || loanAmount < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loan amount must be at least 1.'))
      );
      return;
    }

    // Validate email format
    if (!_emailRegExp.hasMatch(emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.'))
      );
      return;
    }

    // Validate annual income (must be at least 1 peso)
    final anlIncText = anlIncController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (anlIncText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Annual income must be at least 1.'))
      );
      return;
    }
    final anlInc = double.tryParse(anlIncText) ?? 0.0;
    if (anlInc < 1.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Annual income must be at least 1.'))
      );
      return;
    }

    // get current signed-in user's email to resolve staff id
    final currentEmail = Supabase.instance.client.auth.currentUser?.email;
    if (currentEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to determine current user. Please sign in as staff.')));
      return;
    }

    int? staffId;
    try {
      final staffRec = await Supabase.instance.client.from('staff').select('id').eq('email_address', currentEmail).maybeSingle();
      if (staffRec != null && staffRec['id'] != null) {
        staffId = staffRec['id'] is int ? staffRec['id'] : int.tryParse(staffRec['id'].toString());
      }
    } catch (e) {
      debugPrint('Error resolving staff id: $e');
    }

    if (staffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to resolve staff id for current user. Ensure you are signed in as staff.')));
      return;
    }

    // Validate consent like other forms
    if (!agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must agree to the terms before submitting.')));
      return;
    }

    // Prevent duplicate pending applications for the same member
    // Enforce max loan amount based on whether this is the member's first loan
    int maxLoanAllowed = 3000; // default for first loan
    try {
      final prev = await Supabase.instance.client
          .from('member_loans')
          .select('application_id')
          .eq('member_id', selectedMemberId!)
          .limit(1) as List<dynamic>;
      if (prev.isNotEmpty) maxLoanAllowed = 50000;
    } catch (e) {
      debugPrint('Error checking prior loans for member: $e');
      maxLoanAllowed = 3000;
    }

    if (loanAmount > maxLoanAllowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loan amount exceeds allowed maximum of Php $maxLoanAllowed for this member.'))
      );
      return;
    }

    try {
      final existing = await Supabase.instance.client
          .from('loan_application')
          .select('application_id,status')
          .eq('member_id', selectedMemberId!)
          .limit(1) as List<dynamic>;
      if (existing.isNotEmpty) {
        final rec = Map<String, dynamic>.from(existing.first as Map);
        final status = rec['status'];
        if (status == null || status.toString().toLowerCase() == 'pending') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('There is already a pending loan application for this member.')));
          return;
        }
      }
    } catch (e) {
      debugPrint('Error checking existing loan application: $e');
    }

    // Prevent if there's an active approved loan for this member
    try {
      final approved = await Supabase.instance.client
          .from('approved_loans')
          .select('application_id,status')
          .eq('member_id', selectedMemberId!)
          .eq('status', 'active')
          .limit(1) as List<dynamic>;
      if (approved.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This member already has an active approved loan and cannot apply for another.')));
        return;
      }
    } catch (e) {
      debugPrint('Error checking approved loans: $e');
    }


    // convert birthdate to ISO (YYYY-MM-DD) for DB date field
    String dobIso = '';
    final bDate = bDateController.text.trim();
    if (bDate.isNotEmpty) {
      try {
        final parts = bDate.split('/');
        if (parts.length == 3) {
          final m = int.parse(parts[0]);
          final d = int.parse(parts[1]);
          final y = int.parse(parts[2]);
          dobIso = DateTime(y, m, d).toIso8601String().split('T').first;
        }
      } catch (_) {}
    }

    final payload = {
      'member_id': selectedMemberId,
      'installment': instController.text,
      // Send repayment term as provided by the UI (do not force lowercase)
      'repayment_term': termController.text,
      'comaker_contact_no': comakerContactController.text,
      'loan_amount': int.tryParse(loanAmtController.text) ?? 0,
      'annual_income': int.tryParse(anlIncController.text) ?? 0,
      'business_type': businessController.text,
      'reason': reasonController.text,
      'member_first_name': fNameController.text,
      'member_last_name': lNameController.text,
      'member_birth_date': dobIso,
      'member_email': emailController.text,
      'member_phone': phoneNumController.text,
      'address': addrController.text,
      'consent': agreeTerms,
      'comaker_spouse_first_name': spouseFNameController.text,
      'comaker_spouse_last_name': spouseLNameController.text,
      'comaker_child_first_name': childFNameController.text,
      'comaker_child_last_name': childLNameController.text,
      'group_affiliation': groupController.text,
    };

    try {
      await Supabase.instance.client.from('loan_application').insert(payload);

      // clear page after submission
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Loan Application Submitted'),
          content: const Text('The application has been submitted successfully.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => EncAppliform()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit application: $e')));
    }
  }

  Widget appliDate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [ 
        Text(
          "Date of Application",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        SizedBox(
          width: 250,
          child: TextFormField(
            controller: appliDateController,
            decoration: const InputDecoration(
              labelText: 'Date of Application',
            ),
            readOnly: true,
            enabled: true,
          ),
        ),
      ],
    );
  }

  Widget loanInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Loan Information",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: NumberInputField(
                label: "Desired Loan Amount",
                controller: loanAmtController,
                hint: ExportService.currencyFormat.format(0),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  final n = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
                  if (n == null) return 'Must be a number';
                  if (n < minLoanAmount) return 'Minimum loan is ₱$minLoanAmount';
                  if (n > maxLoanAmount) return 'Maximum loan is ₱$maxLoanAmount';
                  return null;
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: NumberInputField(
                label: "Annual Income",
                controller: anlIncController,
                hint: ExportService.currencyFormat.format(0),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  final n = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
                  if (n == null) return 'Must be a number';
                  if (n < minAnnualIncome) return 'Income must be at least $minAnnualIncome';
                  if (n > maxAnnualIncome) return 'Income must be at most $maxAnnualIncome';
                  return null;
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: DropdownInputField(
                label: "Desired Installments",
                controller: instController,
                items: [
                  "3 months",
                  "6 months",
                  "12 months",
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  return null;
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: DropdownInputField(
                label: "Repayment Term",
                controller: termController,
                items: [
                  "Monthly",
                  "Bimonthly",
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  return null;
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: TextInputField(
                label: "Business Type",
                controller: businessController,
                hint: "e.g. Retail, Sari-sari store, etc.", 
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  return null;
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextInputField(
              label: "Reason", 
              controller: reasonController
              ,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                return null;
              }
              ),
            ),
          ],
        ),

      ],
    );
  }

  Widget personalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
      "Personal Information",
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
    SizedBox(height: 16),

    Row(
      children: [
        Expanded(
          child: TextInputField(
            label: "First Name/s",
            controller: fNameController,
            hint: "e.g. Mark Anthony",
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              return null;
            },
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: TextInputField(
            label: "Last Name",
            controller: lNameController,
            hint: "e.g. Garcia",
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              return null;
            },
          ),
        ),
      ],
    ),
    SizedBox(height: 16),
    Row(
      children: [
        SizedBox(
          width: 250,
          child: DateInputField(
            label: "Birth Date",
            controller: bDateController,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              return null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextInputField(
            label: "Group Name",
            controller: groupController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              return null;
            },
          ),
        ),
      ],
    ),
      ],
    );
  }

  Widget coMakers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Loan Co-maker",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextInputField(
                label: "Spouse First Name/s",
                controller: spouseFNameController,
                hint: "e.g. Maricel Ariel",
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextInputField(
                label: "Spouse Last Name",
                controller: spouseLNameController,
                hint: "e.g. Garcia",
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextInputField(
                label: "Child First Name/s",
                controller: childFNameController,
                hint: "e.g. Maricel Ariel",
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextInputField(
                label: "Child Last Name",
                controller: childLNameController,
                hint: "e.g. Garcia",
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextInputField(
                label: "Co-maker Contact No",
                controller: comakerContactController,
                hint: "+63 912 345 6789",
              ),
            ),
            SizedBox(width: 16),
            Expanded(child: SizedBox.shrink()),
          ],
        ),
        SizedBox(height: 16),
        
      ],
    );
  }

  Widget contactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Contact Information",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextInputField(
                label: "Email",
                controller: emailController,
                hint: "e.g. markanthony@email.com",
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (!_emailRegExp.hasMatch(value.trim())) return 'Invalid email address';
                  return null;
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextInputField(
                label: "Phone Number",
                controller: phoneNumController,
                hint: "+63 912 345 6789",
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (!_isValidPhilippinePhone(value.trim())) {
                      final digits = value.replaceAll(RegExp(r'\D'), '');
                      if (digits.length != 11 && !(digits.length == 12 && digits.startsWith('63'))) {
                        return 'Invalid contact number. Must be 11 digits starting with 09.';
                      }
                      return 'Contact number format is incorrect.';
                    }
                    return null;
                  },
                ),
            ),
          ],
        ),
        SizedBox(height: 16),
        TextInputField(
          label: "Home Address",
          controller: addrController,
          hint: "e.g. Malate, Manila, Philippines",
          validator: (value) {
            if (value == null || value.isEmpty) return 'Required';
            return null;
          },
        ),
      ],
    );
  }

  Widget consentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Consent",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Text(
          "I authorize prospective Credit Grantors/Lending/Leasing Companies to obtain personal and credit information about me from my employer and credit bureau, or credit reporting agency, any person who has or may have any financial dealing with me, or from any references I have provided. This information, as well as that provided by me in the application, will be referred to in connection with this lease and any other relationships we may establish from time to time. Any personal and credit information obtained may be disclosed from time to time to other lenders, credit bureaus or other credit reporting agencies.",
          style: TextStyle(fontSize: 14, color: Colors.black),
        ),
        CheckboxListTile(
          title: Text(
            "I hereby agree that the information given is true, accurate and complete as of the date of this application submission.",
            style: TextStyle(fontSize: 14, color: Colors.black),
            ),
          value: agreeTerms,
          onChanged: (value) {
            setState(() {
              agreeTerms = value!;
            });
          },
          activeColor: Colors.black,
          checkColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
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
    child:  Column(
        children: [

          // top nav bar
          const TopNavBar(splash: "Encoder"),

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
                            "Loan Applications",
                            style: TextStyle(fontSize: 28, 
                            fontWeight: FontWeight.bold,
                            color: AppThemes.pageTitle),
                          ),
                          const Text(
                            "Apply for a loan.",
                            style: TextStyle(color: AppThemes.pageTitle, fontSize: 14),
                          ),

                        // classes for form fields
                          // download button
                          buttonsRow(),

                          // application form area: always show member lookup, then either an info panel or the form
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
                                key: _formKey,
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Member Search (always visible)
                                      memberSearchSection(),
                                      const SizedBox(height: 12),

                                      // If we're currently checking the selected member's loan status, show a loader
                                      if (_checkingSelectedMemberStatus) ...[
                                        const SizedBox(height: 12),
                                        Center(child: CircularProgressIndicator()),
                                        const SizedBox(height: 12),
                                      ] else
                                      // If a member is selected and they have a pending or active loan,
                                      // show the same informational panel used in the member form.
                                      if (selectedMemberId != null && (_selectedMemberHasPending || _selectedMemberHasActive)) ...[
                                        Center(
                                          child: Column(
                                            children: [
                                              const SizedBox(height: 12),
                                              Icon(Icons.info_outline, size: 48, color: Colors.orange),
                                              const SizedBox(height: 12),
                                              if (_selectedMemberHasPending) ...[
                                                const Text('User already has a pending loan application!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 8),
                                                const Text('Cannot submit another loan application for the user while a pending application exists.', textAlign: TextAlign.center),
                                              ] else if (_selectedMemberHasActive) ...[
                                                const Text('User already has an active approved loan.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 8),
                                                const Text('Cannot apply for another loan for the user while an active loan exists.', textAlign: TextAlign.center),
                                              ],
                                              const SizedBox(height: 12),
                                            ],
                                          ),
                                        ),
                                      ] else ...[
                                        // Date of Application
                                        appliDate(),
                                        const SizedBox(height: 40),

                                        // Loan Information
                                        loanInfo(),
                                        const SizedBox(height: 40),

                                        // Personal Information
                                        personalInfo(),
                                        const SizedBox(height: 40),

                                        // Loan Co-maker
                                        coMakers(),
                                        const SizedBox(height: 40),

                                        // Contact Information
                                        contactInfo(),
                                        const SizedBox(height: 40),

                                        // Consent
                                        consentForm(),
                                        const SizedBox(height: 18),

                                        // Submit button
                                        Center(
                                          child: ElevatedButton.icon(
                                            onPressed: submitForm,
                                            icon: const SizedBox.shrink(),
                                            label: const Text(
                                              "Submit Application",
                                              style: TextStyle(color: AppThemes.buttonText),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                                              backgroundColor: AppThemes.outerformButton,
                                              minimumSize: const Size(100, 28),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
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
        ],
      ),
      
    )
    );
  }

}