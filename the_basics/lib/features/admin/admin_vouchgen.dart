import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:the_basics/core/widgets/top_navbar.dart';
import 'package:the_basics/core/widgets/side_menu.dart';
import 'package:the_basics/core/widgets/export_dropdown_button.dart';
import 'package:the_basics/core/widgets/input_fields.dart';
import 'package:the_basics/core/utils/export_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_basics/core/utils/themes.dart';

class AdminFinanceManagement extends StatefulWidget {
  const AdminFinanceManagement({super.key});

  @override
  State<AdminFinanceManagement> createState() => _AdminFinanceManagementState();
}

class _AdminFinanceManagementState extends State<AdminFinanceManagement> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();

  // Voucher Application fields
  final TextEditingController refNumberController = TextEditingController();
  final TextEditingController payToController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController satelliteOfficeController = TextEditingController();
  final TextEditingController bankController = TextEditingController();
  final TextEditingController checkNumberController = TextEditingController();
  final TextEditingController receivedSumController = TextEditingController();

  // Dynamic rows
  List<Map<String, dynamic>> particularsRows = [
    {'particular': TextEditingController(), 'amount': TextEditingController()}
  ];
  List<Map<String, dynamic>> accountRows = [
    {'title': TextEditingController(), 'debit': TextEditingController(), 'credit': TextEditingController()}
  ];

  // Signature fields
  final TextEditingController preparedNameController = TextEditingController();
  final TextEditingController preparedDateController = TextEditingController();
  final TextEditingController checkedNameController = TextEditingController();
  final TextEditingController checkedDateController = TextEditingController();
  final TextEditingController approvedNameController = TextEditingController();
  final TextEditingController approvedDateController = TextEditingController();
  final TextEditingController receivedNameController = TextEditingController();
  final TextEditingController receivedDateController = TextEditingController();

  XFile? preparedSignature;
  XFile? checkedSignature;
  XFile? approvedSignature;
  XFile? receivedSignature;

  // Voucher Search
  String? searchType = 'Reference Number';
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> vouchers = [];
  List<Map<String, dynamic>> filteredVouchers = [];
  bool isLoadingVouchers = false;
  String? vouchersError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchVouchers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    refNumberController.dispose();
    payToController.dispose();
    dateController.dispose();
    satelliteOfficeController.dispose();
    bankController.dispose();
    checkNumberController.dispose();
    receivedSumController.dispose();
    searchController.dispose();
    
    for (var row in particularsRows) {
      row['particular'].dispose();
      row['amount'].dispose();
    }
    for (var row in accountRows) {
      row['title'].dispose();
      row['debit'].dispose();
      row['credit'].dispose();
    }
    
    preparedNameController.dispose();
    preparedDateController.dispose();
    checkedNameController.dispose();
    checkedDateController.dispose();
    approvedNameController.dispose();
    approvedDateController.dispose();
    receivedNameController.dispose();
    receivedDateController.dispose();
    
    super.dispose();
  }

  void _addParticularsRow() {
    setState(() {
      particularsRows.add({
        'particular': TextEditingController(),
        'amount': TextEditingController(),
      });
    });
  }

  void _removeParticularsRow(int index) {
    if (particularsRows.length > 1) {
      setState(() {
        particularsRows[index]['particular'].dispose();
        particularsRows[index]['amount'].dispose();
        particularsRows.removeAt(index);
      });
    }
  }

  void _addAccountRow() {
    setState(() {
      accountRows.add({
        'title': TextEditingController(),
        'debit': TextEditingController(),
        'credit': TextEditingController(),
      });
    });
  }

  void _removeAccountRow(int index) {
    if (accountRows.length > 1) {
      setState(() {
        accountRows[index]['title'].dispose();
        accountRows[index]['debit'].dispose();
        accountRows[index]['credit'].dispose();
        accountRows.removeAt(index);
      });
    }
  }

  Future<void> _pickSignature(String type) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          switch (type) {
            case 'prepared':
              preparedSignature = image;
              break;
            case 'checked':
              checkedSignature = image;
              break;
            case 'approved':
              approvedSignature = image;
              break;
            case 'received':
              receivedSignature = image;
              break;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting signature: $e')),
      );
    }
  }

  Future<void> _submitVoucher() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Not authenticated'), backgroundColor: Colors.red),
        );
        return;
      }

      // Validate all required fields (everything except prepared_by fields)
      List<String> missingFields = [];
      
      if (refNumberController.text.isEmpty) missingFields.add('Reference Number');
      if (payToController.text.isEmpty) missingFields.add('Pay To');
      if (dateController.text.isEmpty) missingFields.add('Date Issued');
      if (satelliteOfficeController.text.isEmpty) missingFields.add('Satellite Office Unit');
      if (bankController.text.isEmpty) missingFields.add('Bank');
      if (checkNumberController.text.isEmpty) missingFields.add('Check Number');
      if (receivedSumController.text.isEmpty) missingFields.add('Received Sum');
      
      // Validate particulars (at least one row)
      if (particularsRows.isEmpty || 
          (particularsRows.length == 1 && 
           particularsRows[0]['particular'].text.isEmpty && 
           particularsRows[0]['amount'].text.isEmpty)) {
        missingFields.add('At least one Particular entry');
      }
      
      // Validate that each particular row has both fields filled if either is filled
      for (int i = 0; i < particularsRows.length; i++) {
        String particular = particularsRows[i]['particular'].text.trim();
        String amount = particularsRows[i]['amount'].text.trim();
        
        if ((particular.isNotEmpty && amount.isEmpty) || 
            (particular.isEmpty && amount.isNotEmpty)) {
          missingFields.add('Particular row ${i + 1}: Both particular and amount must be filled');
        }
      }
      
      // Validate account rows (at least one row)
      if (accountRows.isEmpty || 
          (accountRows.length == 1 && 
           accountRows[0]['title'].text.isEmpty && 
           accountRows[0]['debit'].text.isEmpty && 
           accountRows[0]['credit'].text.isEmpty)) {
        missingFields.add('At least one Account entry');
      }
      
      // Validate that account title is filled if debit or credit has value
      for (int i = 0; i < accountRows.length; i++) {
        String title = accountRows[i]['title'].text.trim();
        String debit = accountRows[i]['debit'].text.trim();
        String credit = accountRows[i]['credit'].text.trim();
        
        if ((debit.isNotEmpty || credit.isNotEmpty) && title.isEmpty) {
          missingFields.add('Account row ${i + 1}: Title must be filled when debit or credit has value');
        }
      }
      
      // Validate checked_by fields (name, signature, date)
      if (checkedNameController.text.isEmpty) missingFields.add('Checked By Name');
      if (checkedSignature == null) missingFields.add('Checked By Signature');
      if (checkedDateController.text.isEmpty) missingFields.add('Checked By Date');
      
      // Validate approved_by fields (name, signature, date)
      if (approvedNameController.text.isEmpty) missingFields.add('Approved By Name');
      if (approvedSignature == null) missingFields.add('Approved By Signature');
      if (approvedDateController.text.isEmpty) missingFields.add('Approved By Date');
      
      // Validate received_by fields (name, signature, date)
      if (receivedNameController.text.isEmpty) missingFields.add('Received By Name');
      if (receivedSignature == null) missingFields.add('Received By Signature');
      if (receivedDateController.text.isEmpty) missingFields.add('Received By Date');
      
      if (missingFields.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Missing required fields: ${missingFields.join(", ")}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }

      // Convert particulars and account rows to JSON
      final particularsJson = particularsRows
          .map((row) => {
            'particular': row['particular'].text,
            'amount': row['amount'].text,
          })
          .toList();

      final accountRowsJson = accountRows
          .map((row) => {
            'title': row['title'].text,
            'debit': row['debit'].text,
            'credit': row['credit'].text,
          })
          .toList();

      // Insert into database
      await client.from('vouchers').insert({
        'ref_number': refNumberController.text,
        'pay_to': payToController.text,
        'date_issued': dateController.text.isNotEmpty ? dateController.text : null,
        'satellite_office': satelliteOfficeController.text,
        'bank': bankController.text,
        'check_number': checkNumberController.text,
        'received_sum': receivedSumController.text.isNotEmpty 
            ? double.tryParse(receivedSumController.text) 
            : null,
        'particulars': particularsJson,
        'account_rows': accountRowsJson,
        'prepared_name': preparedNameController.text,
        'prepared_date': preparedDateController.text.isNotEmpty ? preparedDateController.text : null,
        'checked_name': checkedNameController.text,
        'checked_date': checkedDateController.text.isNotEmpty ? checkedDateController.text : null,
        'approved_name': approvedNameController.text,
        'approved_date': approvedDateController.text.isNotEmpty ? approvedDateController.text : null,
        'received_name': receivedNameController.text,
        'received_date': receivedDateController.text.isNotEmpty ? receivedDateController.text : null,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Voucher created successfully'), backgroundColor: Colors.green),
      );

      // Clear form
      _clearForm();
      _fetchVouchers();
    } catch (e) {
      print('Error submitting voucher: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _clearForm() {
    refNumberController.clear();
    payToController.clear();
    dateController.clear();
    satelliteOfficeController.clear();
    bankController.clear();
    checkNumberController.clear();
    receivedSumController.clear();
    
    for (var row in particularsRows) {
      row['particular'].clear();
      row['amount'].clear();
    }
    for (var row in accountRows) {
      row['title'].clear();
      row['debit'].clear();
      row['credit'].clear();
    }
    
    preparedNameController.clear();
    preparedDateController.clear();
    checkedNameController.clear();
    checkedDateController.clear();
    approvedNameController.clear();
    approvedDateController.clear();
    receivedNameController.clear();
    receivedDateController.clear();
  }

  Future<void> _fetchVouchers() async {
    setState(() => isLoadingVouchers = true);

    try {
      final client = Supabase.instance.client;
      
      final response = await client
          .from('vouchers')
          .select('voucher_id, ref_number, pay_to, date_issued, bank, check_number, received_sum, created_at')
          .order('created_at', ascending: false);

      setState(() {
        vouchers = List<Map<String, dynamic>>.from(response);
        filteredVouchers = vouchers;
        isLoadingVouchers = false;
      });
    } catch (e) {
      print('Error fetching vouchers: $e');
      setState(() {
        vouchersError = e.toString();
        isLoadingVouchers = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading vouchers: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _filterVouchers() {
    final query = searchController.text.toLowerCase();
    
    setState(() {
      if (query.isEmpty) {
        filteredVouchers = vouchers;
      } else {
        filteredVouchers = vouchers.where((voucher) {
          switch (searchType) {
            case 'Reference Number':
              return (voucher['ref_number'] ?? '').toString().toLowerCase().contains(query);
            case 'Date':
              return (voucher['date_issued'] ?? '').toString().contains(query);
            case 'Member Name':
              return (voucher['pay_to'] ?? '').toString().toLowerCase().contains(query);
            default:
              return false;
          }
        }).toList();
      }
    });
  }

  Widget _buildSignatureField(String label, String type, XFile? signature, 
  TextEditingController nameController, TextEditingController dateController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        SizedBox(
          width: 150,
          child: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: "Name",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
          ),
        ),
        SizedBox(height: 8),
        InkWell(
          onTap: () => _pickSignature(type),
          child: Container(
            width: 150,
            height: 60,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: signature != null
                  ? Text('Signature', style: TextStyle(fontSize: 12))
                  : Text('Upload Signature', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          ),
        ),
        SizedBox(height: 8),
        SizedBox(
          width: 150,
          child: DateInputField(
            label: "Date",
            controller: dateController,
          ),
        ),
      ],
    );
  }

  Widget voucherInfo() {
    return Column(
      children: [
        Row(
          children: [
            Flexible(
              child: TextField(
                controller: refNumberController,
                decoration: InputDecoration(
                  labelText: "Reference Number",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            SizedBox(width: 12),
            Flexible(
              child: TextField(
                controller: payToController,
                decoration: InputDecoration(
                  labelText: "Pay to",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            SizedBox(width: 12),
            Flexible(
              child: DateInputField(
                label: "Date",
                controller: dateController,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Row 2: Satellite Office, Bank, Check #
        Row(
          children: [
            Flexible(
              child: TextField(
                controller: satelliteOfficeController,
                decoration: InputDecoration(
                  labelText: "Satellite Office Unit",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            SizedBox(width: 12),
            Flexible(
              child: TextField(
                controller: bankController,
                decoration: InputDecoration(
                  labelText: "Bank",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            SizedBox(width: 12),
            Flexible(
              child: TextField(
                controller: checkNumberController,
                decoration: InputDecoration(
                  labelText: "Check Number",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget particulars() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Particulars", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(
              icon: Icon(Icons.add_circle, color: AppThemes.green),
              onPressed: _addParticularsRow,
            ),
          ],
        ),
        SizedBox(height: 8),
        ...particularsRows.asMap().entries.map((entry) {
          int index = entry.key;
          var row = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Flexible(
                  flex: 2,
                  child: TextField(
                    controller: row['particular'],
                    decoration: InputDecoration(
                      labelText: "Particular",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Flexible(
                  child: TextField(
                    controller: row['amount'],
                    decoration: InputDecoration(
                      labelText: "Amount",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                if (particularsRows.length > 1)
                  IconButton(
                    icon: Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => _removeParticularsRow(index),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget accountTitle() {
    return Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Account Title", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(
              icon: Icon(Icons.add_circle, color: AppThemes.green),
              onPressed: _addAccountRow,
            ),
          ],
        ),
        SizedBox(height: 8),
        ...accountRows.asMap().entries.map((entry) {
          int index = entry.key;
          var row = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: row['title'],
                    decoration: InputDecoration(
                      labelText: "Title",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: row['debit'],
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      labelText: "Debit",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: row['credit'],
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      labelText: "Credit",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                if (accountRows.length > 1)
                  IconButton(
                    icon: Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => _removeAccountRow(index),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget sumAndSignatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        // Received Sum
        TextField(
          controller: receivedSumController,
          decoration: InputDecoration(
            labelText: "Received from K-Coop the sum of",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        SizedBox(height: 30),

        // Signatures Section
        Text("Signatures", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(child: _buildSignatureField("Prepared by", "prepared", preparedSignature, preparedNameController, preparedDateController)),
            SizedBox(width: 16),
            Flexible(child: _buildSignatureField("Checked by", "checked", checkedSignature, checkedNameController, checkedDateController)),
            SizedBox(width: 16),
            Flexible(child: _buildSignatureField("Approved by", "approved", approvedSignature, approvedNameController, approvedDateController)),
            SizedBox(width: 16),
            Flexible(child: _buildSignatureField("Received by", "received", receivedSignature, receivedNameController, receivedDateController)),
          ],
        ),
      ]
    );
  }

  Widget vouchSearchBar() {
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                initialValue: searchType,
                decoration: InputDecoration(
                  labelText: "Search by",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: [
                  DropdownMenuItem(value: "Reference Number", child: Text("Reference No.")),
                  DropdownMenuItem(value: "Date", child: Text("Date")),
                  DropdownMenuItem(value: "Member Name", child: Text("Member Name")),
                ],
                onChanged: (value) {
                  setState(() {
                    searchType = value;
                    _filterVouchers();
                  });
                },
              ),
            ),
            SizedBox(width: 16),
            Flexible(
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: "Search",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (_) => _filterVouchers(),
              ),
            ),
            SizedBox(width: 16),
            ElevatedButton(
              onPressed: _filterVouchers,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              child: Text("Search", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ],
    );
  }

  Widget vouchSearchTable() {
    return Container(
      width: double.infinity,
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
      child: () {
        // compute content in a local variable to avoid complex nested conditional expressions
        Widget content;
        if (isLoadingVouchers) {
          content = Center(child: CircularProgressIndicator());
        } else if (vouchersError != null) {
          content = Center(
            child: Text(
              'Error loading vouchers: ${vouchersError}',
              style: TextStyle(color: Colors.red),
            ),
          );
        } else if (filteredVouchers.isEmpty) {
          content = Center(child: Text('No vouchers found'));
        } else {
          content = SingleChildScrollView(
            child: Builder(builder: (context) {
              try {
                final rows = filteredVouchers.map((voucher) {
                  return DataRow(cells: [
                    DataCell(Text(voucher['voucher_id']?.toString() ?? '')),
                    DataCell(Text(voucher['ref_number']?.toString() ?? '')),
                    DataCell(Text(voucher['pay_to']?.toString() ?? '')),
                    DataCell(Text((voucher['received_sum'] ?? 0).toString())),
                    DataCell(Text(voucher['date_issued']?.toString() ?? '')),
                  ]);
                }).toList();

                return DataTable(
                  columns: [
                    DataColumn(label: Text("Voucher ID", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Reference #", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Pay To", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Amount", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Date Issued", style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: rows,
                );
              } catch (e, st) {
                debugPrint('Error building voucher rows: $e\n$st');
                return Container(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('Error rendering vouchers', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text(e.toString()),
                    ],
                  ),
                );
              }
            }),
          );
        }

        return content;
      }(),
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
          TopNavBar(splash: "Admin"),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SideMenu(role: "Admin"),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(left: 16),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title
                        Text(
                          "Voucher Generation",
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppThemes.pageTitle),
                        ),
                        Text(
                          "Create and manage check vouchers",
                          style: TextStyle(color: AppThemes.pageSubtitle, fontSize: 14,),
                        ),
                        SizedBox(height: 24),
                        
                        // Tabs
                        Container(
                          child: TabBar(
                            controller: _tabController,
                            labelColor: AppThemes.outerformButton,
                            unselectedLabelColor: AppThemes.pageSubtitle,
                            indicatorColor: AppThemes.outerformButton,
                            tabs: [
                              Tab(text: "Voucher Application"),
                              Tab(text: "Voucher Search"),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),
                        
                        // Tab Content
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [



                              
                              // TAB 1: VOUCHER APPLICATION
                              SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    
                                    // Header with download button
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        
                                        Text(
                                          "Check Voucher",
                                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppThemes.buttonText),
                                        ),
                                        ExportDropdownButton(
                                          height: 40,
                                          minWidth: 180,
                                          onExportPdf: () async {
                                            // Build voucher data from form
                                            final Map<String, dynamic> voucherData = {
                                              'voucher_id': refNumberController.text.isNotEmpty ? refNumberController.text : 'N/A',
                                              'date_issued': dateController.text.isNotEmpty ? dateController.text : DateTime.now().toString().split(' ')[0],
                                              'pay_to': payToController.text.isNotEmpty ? payToController.text : 'N/A',
                                              'satellite_office': satelliteOfficeController.text,
                                              'bank': bankController.text,
                                              'check_number': checkNumberController.text,
                                              'received_sum': double.tryParse(receivedSumController.text) ?? 0.0,
                                              'particulars': particularsRows.map((row) => {
                                                'description': (row['particular'] as TextEditingController).text,
                                                'amount': double.tryParse((row['amount'] as TextEditingController).text) ?? 0.0,
                                              }).toList(),
                                              'account_rows': accountRows.map((row) => {
                                                'account': (row['title'] as TextEditingController).text,
                                                'debit': double.tryParse((row['debit'] as TextEditingController).text) ?? 0.0,
                                                'credit': double.tryParse((row['credit'] as TextEditingController).text) ?? 0.0,
                                              }).toList(),
                                              'prepared_name': preparedNameController.text,
                                              'prepared_date': preparedDateController.text,
                                              'checked_name': checkedNameController.text,
                                              'checked_date': checkedDateController.text,
                                              'approved_name': approvedNameController.text,
                                              'approved_date': approvedDateController.text,
                                              'received_name': receivedNameController.text,
                                              'received_date': receivedDateController.text,
                                            };
                                            
                                            try {
                                              final bytes = await ExportService.buildCheckVoucherPdf(voucherData);
                                              final result = await ExportService.sharePdf(bytes, 
                                                filename: 'check_voucher_${refNumberController.text.isNotEmpty ? refNumberController.text : DateTime.now().millisecondsSinceEpoch}.pdf'
                                              );
                                              if (result.contains('/') || result.contains('\\')) {
                                                ExportService.showExportMessage(context, 'Check Voucher PDF saved to: $result');
                                              } else {
                                                ExportService.showExportMessage(context, 'Check Voucher PDF exported successfully');
                                              }
                                            } catch (e) {
                                              ExportService.showExportMessage(context, 'Export failed: $e');
                                            }
                                          },
                                          onExportXlsx: () async {
                                            // Export voucher as table data
                                            final rows = [
                                              {
                                                'voucher_number': refNumberController.text,
                                                'date': dateController.text,
                                                'pay_to': payToController.text,
                                                'bank': bankController.text,
                                                'check_number': checkNumberController.text,
                                                'received_sum': receivedSumController.text,
                                                'satellite_office': satelliteOfficeController.text,
                                                'prepared_by': preparedNameController.text,
                                                'approved_by': approvedNameController.text,
                                                'received_by': receivedNameController.text,
                                              }
                                            ];
                                            
                                            await ExportService.exportAndShareExcel(
                                              context: context,
                                              rows: rows,
                                              filename: 'check_voucher_${refNumberController.text.isNotEmpty ? refNumberController.text : DateTime.now().millisecondsSinceEpoch}.xlsx',
                                              sheetName: 'Check Voucher',
                                              columnOrder: ['voucher_number', 'date', 'pay_to', 'bank', 'check_number', 'received_sum', 'satellite_office', 'prepared_by', 'approved_by', 'received_by'],
                                              columnHeaders: {
                                                'voucher_number': 'Voucher Number',
                                                'date': 'Date',
                                                'pay_to': 'Pay To',
                                                'bank': 'Bank',
                                                'check_number': 'Check Number',
                                                'received_sum': 'Received Sum',
                                                'satellite_office': 'Satellite Office',
                                                'prepared_by': 'Prepared By',
                                                'approved_by': 'Approved By',
                                                'received_by': 'Received By',
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16),

                                    // Main Form Card
                                    Container(
                                      padding: EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          
                                          // Header
                                          Text(
                                            "Sharelife Multi-Purpose Cooperative",
                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            "Visayas St., Phase 4, Lupang Pangako, Payatas, Quezon City",
                                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                          ),
                                          SizedBox(height: 24),

                                          // First block
                                          voucherInfo(),
                                          SizedBox(height: 24),

                                          // Particulars Section
                                          particulars(),
                                          SizedBox(height: 24),

                                          // Account Title Section
                                          accountTitle(),
                                          SizedBox(height: 24),

                                          // Received sum + signatures
                                          sumAndSignatures(),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 24),

                                    // Submit Button
                                    Center(
                                      child: ElevatedButton(
                                        onPressed: _submitVoucher,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppThemes.outerformButton,
                                          padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: Text("Submit Voucher", style: TextStyle(color: AppThemes.buttonText, fontSize: 16)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),




                              // TAB 2: VOUCHER SEARCH
                              // Use a scrollable column instead of Expanded inside TabBarView
                              SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    
                                    // Search Bar
                                    vouchSearchBar(),
                                    SizedBox(height: 24),

                                    // Vouchers Table
                                    // vouchSearchTable handles its own scrolling; don't wrap with Expanded here
                                    vouchSearchTable(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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