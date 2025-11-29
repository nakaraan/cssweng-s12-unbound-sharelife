import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'export_file_share_io.dart' if (dart.library.html) 'export_file_share_web.dart' as file_share;

class ExportService {
  // Currency formatter
  static final NumberFormat currencyFormat = NumberFormat.currency(symbol: 'Php ', decimalDigits: 2);
  static final DateFormat dateFormat = DateFormat('yyyy-MM-dd');

  /// Safely format currency as value for ui
  static String safeCurrency(dynamic value) {
    if (value == null) return currencyFormat.format(0);

    if (value is num) return currencyFormat.format(value);

    if (value is String) {
      final s = value.trim();
      if (s.isEmpty) return currencyFormat.format(0);

      // If already looks like formatted currency or a label, return as-is
      if (s.startsWith('Php') || s.startsWith('₱') || RegExp(r'[A-Za-z]').hasMatch(s)) {
        return s;
      }

      // Clean common group separators and try parse
      final cleaned = s.replaceAll(RegExp(r'[,\s]'), '');
      final parsed = double.tryParse(cleaned);
      if (parsed != null) return currencyFormat.format(parsed);

      return s;
    }

    // fallback
    return value.toString();
  }
  
  /// Helper to format cell values
  static String _formatValue(dynamic value) {
    if (value == null) return '';
    if (value is DateTime) return dateFormat.format(value);
    if (value is num) {
      // Check if it looks like currency (amounts, balances, etc.)
      if (value > 100 || value.toString().contains('.')) {
        return currencyFormat.format(value);
      }
    }
    return value.toString();
  }

  /// Regular PDF export: simple table from row data
  static Future<Uint8List> buildRegularPdf({
    required String title,
    required List<Map<String, dynamic>> rows,
    List<String>? columnOrder,
    Map<String, String>? columnHeaders,
  }) async {
    final pdf = pw.Document();

    if (rows.isEmpty) {
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Center(
            child: pw.Text('No data to export'),
          ),
        ),
      );
      return pdf.save();
    }

    // Use provided column order or all keys from first row
    final headers = columnOrder ?? rows.first.keys.toList();
    final displayHeaders = headers.map((h) => columnHeaders?[h] ?? h).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) {
          return [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'SHARELIFE CONSUMERS COOPERATIVE',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(title, style: pw.TextStyle(fontSize: 14)),
                  pw.Text(
                    'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                  ),
                  pw.Divider(),
                ],
              ),
            ),
            pw.Table.fromTextArray(
              headers: displayHeaders,
              data: rows.map<List<dynamic>>((r) => headers.map((h) => _formatValue(r[h])).toList()).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignment: pw.Alignment.centerLeft,
              border: pw.TableBorder.all(color: PdfColors.grey),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Check Voucher PDF - formatted to match template
  static Future<Uint8List> buildCheckVoucherPdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    // Load a TTF that includes the ₱ glyph (add the font file to assets and pubspec.yaml)
    pw.Font? baseFont;
    try {
      final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      baseFont = pw.Font.ttf(fontData);
    } catch (e) {
      // Fall back to regular font if loading fails
      baseFont = null;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          // Parse particulars and account_rows if they're JSON
          final particulars = data['particulars'] is List ? data['particulars'] : [];
          final accountRows = data['account_rows'] is List ? data['account_rows'] : [];
          
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'SHARELIFE CONSUMERS COOPERATIVE',
                      style: pw.TextStyle(font: baseFont, fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('CHECK VOUCHER', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Voucher details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Voucher No: ${data['voucher_id'] ?? ''}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Date: ${data['date_issued'] ?? ''}'),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                children: [
                  pw.Text('Pay to: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('${data['pay_to'] ?? ''}'),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Satellite Office: ${data['satellite_office'] ?? ''}'),
                  pw.Text('Bank: ${data['bank'] ?? ''}'),
                ],
              ),
              pw.Row(
                children: [
                  pw.Text('Check #: ${data['check_number'] ?? ''}'),
                ],
              ),
              pw.SizedBox(height: 16),
              
              // Particulars table
              if (particulars.isNotEmpty) ...[
                pw.Text('Particulars:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Table.fromTextArray(
                  headers: ['Description', 'Amount'],
                  data: particulars.map<List<dynamic>>((p) => [
                    p['description'] ?? '',
                    currencyFormat.format(p['amount'] ?? 0),
                  ]).toList(),
                  border: pw.TableBorder.all(color: PdfColors.grey),
                  cellAlignment: pw.Alignment.centerLeft,
                  headerStyle: pw.TextStyle(font: baseFont, fontSize: 9, fontWeight: pw.FontWeight.bold),
                  cellStyle: pw.TextStyle(font: baseFont, fontSize: 9),
                ),
                pw.SizedBox(height: 16),
              ],
              
              // Account rows
              if (accountRows.isNotEmpty) ...[
                pw.Table.fromTextArray(
                  headers: ['Account', 'Debit', 'Credit'],
                  data: accountRows.map<List<dynamic>>((a) => [
                    a['account'] ?? '',
                    a['debit'] != null ? currencyFormat.format(a['debit']) : '',
                    a['credit'] != null ? currencyFormat.format(a['credit']) : '',
                  ]).toList(),
                  border: pw.TableBorder.all(color: PdfColors.grey),
                  headerStyle: pw.TextStyle(font: baseFont, fontSize: 9, fontWeight: pw.FontWeight.bold),
                  cellStyle: pw.TextStyle(font: baseFont, fontSize: 9),
                ),
                pw.SizedBox(height: 16),
              ],
              
              // Total amount
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Total Amount: ${currencyFormat.format(data['received_sum'] ?? 0)}',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              
              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildSignatureBlock('Prepared by', data['prepared_name'], data['prepared_date']),
                  _buildSignatureBlock('Checked by', data['checked_name'], data['checked_date']),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildSignatureBlock('Approved by', data['approved_name'], data['approved_date']),
                  _buildSignatureBlock('Received by', data['received_name'], data['received_date']),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSignatureBlock(String label, String? name, String? date) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 20),
        pw.Container(
          width: 150,
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black)),
          ),
          child: pw.Text(name ?? '', style: const pw.TextStyle(fontSize: 10)),
        ),
        pw.SizedBox(height: 2),
        pw.Text(date != null ? 'Date: $date' : '', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
      ],
    );
  }

  /// Loan Application PDF - formatted to match template
  static Future<Uint8List> buildLoanApplicationPdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return [
            // Header
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'SHARELIFE CONSUMERS COOPERATIVE',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'LOAN APPLICATION FORM',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            
            // Mirror the appliform page: Date -> Loan Info -> Personal Info -> Co-maker -> Contact -> Consent -> Purpose
            _buildSectionHeader('Application Information'),
            _buildInfoRow('Date of Application:', '${data['created_at'] ?? data['application_date'] ?? ''}'),
            _buildInfoRow('Application ID:', '${data['application_id'] ?? ''}'),
            _buildInfoRow('Status:', '${data['status'] ?? ''}'),

            pw.SizedBox(height: 12),
            _buildSectionHeader('Loan Information'),
            _buildInfoRow('Loan Amount:', currencyFormat.format(data['loan_amount'] ?? 0)),
            _buildInfoRow('Installment:', '${data['installment'] ?? ''}'),
            _buildInfoRow('Repayment Term:', '${data['repayment_term'] ?? ''}'),
            _buildInfoRow('Business Type:', '${data['business_type'] ?? ''}'),

            pw.SizedBox(height: 12),
            _buildSectionHeader('Personal Information'),
            _buildInfoRow('Name:', '${data['member_first_name'] ?? ''} ${data['member_last_name'] ?? ''}'),
            _buildInfoRow('Date of Birth:', '${data['member_birth_date'] ?? ''}'),
            _buildInfoRow('Group Affiliation:', '${data['group_affiliation'] ?? data['group'] ?? ''}'),

            pw.SizedBox(height: 12),
            _buildSectionHeader('Loan Co-maker'),
            if ((data['comaker_spouse_first_name'] ?? '').toString().isNotEmpty)
              _buildInfoRow('Spouse:', '${data['comaker_spouse_first_name'] ?? ''} ${data['comaker_spouse_last_name'] ?? ''}'),
            if ((data['comaker_child_first_name'] ?? '').toString().isNotEmpty)
              _buildInfoRow('Child:', '${data['comaker_child_first_name'] ?? ''} ${data['comaker_child_last_name'] ?? ''}'),
            _buildInfoRow('Co-maker Contact No:', '${data['comaker_contact_no'] ?? data['comaker_contact_no'] ?? ''}'),

            pw.SizedBox(height: 12),
            _buildSectionHeader('Contact Information'),
            _buildInfoRow('Email:', '${data['member_email'] ?? ''}'),
            _buildInfoRow('Phone:', '${data['member_phone'] ?? ''}'),
            _buildInfoRow('Address:', '${data['address'] ?? ''}'),

            pw.SizedBox(height: 12),
            _buildSectionHeader('Consent'),
            pw.Text(data['consent'] == true
                ? 'Applicant has agreed to the consent statement.'
                : 'Applicant did not indicate consent.'),

            pw.SizedBox(height: 12),
            _buildSectionHeader('Purpose'),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey),
              ),
              child: pw.Text('${data['reason'] ?? data['loan_purpose'] ?? 'N/A'}'),
            ),
            
            if (data['remarks'] != null) ...[
              pw.SizedBox(height: 16),
              _buildSectionHeader('Remarks'),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                ),
                child: pw.Text('${data['remarks']}'),
              ),
            ],
            
            pw.SizedBox(height: 24),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text(
              'I hereby certify that the information provided is true and accurate.',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey300,
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  /// Print or share a generated PDF
  static Future<void> printPdf(Uint8List bytes, {String jobName = 'Document'}) async {
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: jobName,
    );
  }

  /// Share PDF
  static Future<String> sharePdf(Uint8List bytes, {String filename = 'document.pdf'}) async {
    try {
      // Try to use printing package's share first (works on mobile)
      await Printing.sharePdf(bytes: bytes, filename: filename);
      return 'Shared successfully';
    } catch (e) {
      // Fallback: save to temp directory (works on web/desktop)
      final file = await saveFile(bytes, filename);
      return file.path;
    }
  }

  /// Basic Excel export (XLSX)
  static Future<Uint8List> buildExcel({
    required List<Map<String, dynamic>> rows,
    String sheetName = 'Sheet1',
    List<String>? columnOrder,
    Map<String, String>? columnHeaders,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel[sheetName];

    if (rows.isEmpty) {
      sheet.appendRow(['No data']);
    } else {
      // Use provided column order or all keys from first row
      final headers = columnOrder ?? rows.first.keys.toList();
      final displayHeaders = headers.map((h) => columnHeaders?[h] ?? h).toList();
      
      // Add header row
      sheet.appendRow(displayHeaders);
      
      // Add data rows
      for (final row in rows) {
        final cells = headers.map((h) {
          final value = row[h];
          if (value == null) return '';
          if (value is DateTime) return dateFormat.format(value);
          return value.toString();
        }).toList();
        sheet.appendRow(cells);
      }
    }

    // Save and return bytes
    final fileBytes = excel.encode();
    return Uint8List.fromList(fileBytes!);
  }

  /// csv export fallback
  static Future<Uint8List> buildCsv({
    required List<Map<String, dynamic>> rows,
    List<String>? columnOrder,
    Map<String, String>? columnHeaders,
    String delimiter = ',',
  }) async {
    final buffer = StringBuffer();

    if (rows.isEmpty) {
      buffer.writeln('No data');
      return Uint8List.fromList(utf8.encode(buffer.toString()));
    }

    final headers = columnOrder ?? rows.first.keys.toList();
    final displayHeaders = headers.map((h) => columnHeaders?[h] ?? h).toList();

    // header row
    buffer.writeln(displayHeaders.map((h) => '"${h.toString().replaceAll('"', '""')}"').join(delimiter));

    // data rows
    for (final row in rows) {
      final cells = headers.map((h) {
        final value = row[h];
        final cell = value == null
            ? ''
            : (value is DateTime ? dateFormat.format(value) : value.toString());
        // Escape double quotes
        return '"${cell.replaceAll('"', '""')}"';
      }).join(delimiter);
      buffer.writeln(cells);
    }

    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }

  /// Save bytes to file (helper for downloads)
  static Future<File> saveFile(Uint8List bytes, String filename) async {
    final dir = Directory.systemTemp;
    // Add timestamp to filename to avoid file lock conflicts
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final nameWithoutExt = filename.substring(0, filename.lastIndexOf('.'));
    final ext = filename.substring(filename.lastIndexOf('.'));
    final uniqueFilename = '${nameWithoutExt}_$timestamp$ext';
    final file = File('${dir.path}/$uniqueFilename');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Share Excel file (saves to temp directory and returns path)
  static Future<String> shareExcel(Uint8List bytes, {String filename = 'document.xlsx'}) async {
    try {
      // Use platform-specific saver: on web this triggers a browser download,
      // on IO platforms this saves to a temp file and returns the path.
      final result = await file_share.saveBytesToFile(bytes, filename);
      return result;
    } catch (e) {
      throw Exception('Failed to save Excel file: $e');
    }
  }

  /// Show a snackbar message
  static void showExportMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  /// Export and share PDF - convenience method
  static Future<void> exportAndSharePdf({
    required BuildContext context,
    required String title,
    required List<Map<String, dynamic>> rows,
    String? filename,
    List<String>? columnOrder,
    Map<String, String>? columnHeaders,
  }) async {
    try {
      final bytes = await buildRegularPdf(
        title: title,
        rows: rows,
        columnOrder: columnOrder,
        columnHeaders: columnHeaders,
      );
      final result = await sharePdf(bytes, filename: filename ?? 'export_${DateTime.now().millisecondsSinceEpoch}.pdf');
      if (result.contains('/') || result.contains('\\')) {
        showExportMessage(context, 'PDF saved to: $result');
      } else {
        showExportMessage(context, 'PDF exported successfully');
      }
    } catch (e) {
      showExportMessage(context, 'Export failed: $e');
    }
  }

  /// Export and share Excel - convenience method
  static Future<void> exportAndShareExcel({
    required BuildContext context,
    required List<Map<String, dynamic>> rows,
    String sheetName = 'Sheet1',
    String? filename,
    List<String>? columnOrder,
    Map<String, String>? columnHeaders,
  }) async {
    try {
      final bytes = await buildExcel(
        rows: rows,
        sheetName: sheetName,
        columnOrder: columnOrder,
        columnHeaders: columnHeaders,
      );
      final filePath = await shareExcel(
        bytes,
        filename: filename ?? 'export_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      );
      showExportMessage(context, 'Excel file saved to: $filePath');
    } catch (e) {
      // If XLSX export fails, fall back to CSV (opens in excel).
      try {
        final csvBytes = await buildCsv(rows: rows, columnOrder: columnOrder, columnHeaders: columnHeaders);
        // Use .csv extension for fallback file
        final fallbackName = (filename != null && filename.contains('.'))
            ? filename.replaceAll(RegExp(r'\.[^\.]+$'), '.csv')
            : 'export_${DateTime.now().millisecondsSinceEpoch}.csv';
        final filePath = await shareExcel(csvBytes, filename: fallbackName);
        showExportMessage(context, 'XLSX export failed, saved CSV instead: $filePath');
      } catch (inner) {
        showExportMessage(context, 'Export failed: $e');
      }
    }
  }
}