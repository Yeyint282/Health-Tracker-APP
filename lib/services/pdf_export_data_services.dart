import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

// Define an enum for export time ranges
enum ExportTimeRange {
  oneWeek,
  twoWeeks,
  threeWeeks,
  oneMonth,
  all,
}

class PdfExportService {
  pw.Font? _englishFont;
  pw.Font? _burmeseFont;

  Future<void> exportHealthDataToPdf({
    required List<Map<String, dynamic>> bloodPressureData,
    required List<Map<String, dynamic>> bloodSugarData,
    required List<Map<String, dynamic>> dailyActivityData,
    required String userName,
    required ExportTimeRange timeRange, // Parameter to specify time range
  }) async {
    final pdf = pw.Document();

    try {
      final ByteData robotoData =
          await rootBundle.load('assets/fonts/times.ttf');
      _englishFont = pw.Font.ttf(robotoData.buffer.asByteData());

      final ByteData myanmarData =
          await rootBundle.load('assets/fonts/AyarJuno-2LO8.ttf');
      _burmeseFont = pw.Font.ttf(myanmarData.buffer.asByteData());

      debugPrint('Fonts loaded successfully.');
    } catch (e) {
      debugPrint('Error loading fonts: $e. Using default font.');
      _englishFont = pw.Font.courier(); // Fallback for English
      _burmeseFont = pw.Font
          .courier(); // Fallback for Burmese (may not render Burmese chars)
    }

    // Define Text Styles using the loaded fonts
    // Helper function to get the appropriate text style based on content
    pw.TextStyle _getTextStyle(String text,
        {double? fontSize, pw.FontWeight? fontWeight}) {
      pw.Font fontToUse = _englishFont!; // Default to English font
      if (_containsBurmese(text)) {
        fontToUse =
            _burmeseFont!; // Use Burmese font if Burmese characters are detected
      }
      return pw.TextStyle(
        font: fontToUse,
        fontSize: fontSize ?? 10,
        fontWeight: fontWeight,
      );
    }

    // Styles for fixed English elements (like section headers)
    pw.TextStyle documentTitleStyle = pw.TextStyle(
        font: _englishFont!, fontSize: 24, fontWeight: pw.FontWeight.bold);
    pw.TextStyle sectionTitleStyle = pw.TextStyle(
        font: _englishFont!, fontSize: 18, fontWeight: pw.FontWeight.bold);

    // --- NEW: Filter Data Based on Time Range ---
    DateTime now = DateTime.now();
    int? startTimeMillis;
    String timeRangeDescription; // For PDF title and filename

    switch (timeRange) {
      case ExportTimeRange.oneWeek:
        startTimeMillis =
            now.subtract(const Duration(days: 7)).millisecondsSinceEpoch;
        timeRangeDescription = 'Last 1 Week';
        break;
      case ExportTimeRange.twoWeeks:
        startTimeMillis =
            now.subtract(const Duration(days: 14)).millisecondsSinceEpoch;
        timeRangeDescription = 'Last 2 Weeks';
        break;
      case ExportTimeRange.threeWeeks:
        startTimeMillis =
            now.subtract(const Duration(days: 21)).millisecondsSinceEpoch;
        timeRangeDescription = 'Last 3 Weeks';
        break;
      case ExportTimeRange.oneMonth:
        // Approximating 1 month as 30 days for simplicity and consistency with Duration
        startTimeMillis =
            now.subtract(const Duration(days: 30)).millisecondsSinceEpoch;
        timeRangeDescription = 'Last 1 Month';
        break;
      case ExportTimeRange.all:
        startTimeMillis = null; // No start time filter for 'all'
        timeRangeDescription = 'All Records';
        break;
    }

    // Apply filtering to each data list
    List<Map<String, dynamic>> filteredBloodPressure =
        bloodPressureData.where((data) {
      final int? dateTime = data['date_time'] as int?;
      return dateTime != null &&
          (startTimeMillis == null || dateTime >= startTimeMillis);
    }).toList();

    List<Map<String, dynamic>> filteredBloodSugar =
        bloodSugarData.where((data) {
      final int? dateTime = data['date_time'] as int?;
      return dateTime != null &&
          (startTimeMillis == null || dateTime >= startTimeMillis);
    }).toList();

    List<Map<String, dynamic>> filteredDailyActivity =
        dailyActivityData.where((data) {
      // Daily activity data uses 'date' (which is also millisecondsSinceEpoch)
      final int? date = data['date'] as int?;
      return date != null &&
          (startTimeMillis == null || date >= startTimeMillis);
    }).toList();

    // --- 2. Add Document Title Page ---
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('Health Data Report ($timeRangeDescription)',
                    style: documentTitleStyle), // Updated title
                pw.SizedBox(height: 20),
                pw.Text('For $userName',
                    style: _getTextStyle(userName,
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text(
                    'Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                    style: _getTextStyle('Generated on:', fontSize: 10)),
              ],
            ),
          );
        },
      ),
    );

    // --- 3. Add Blood Pressure Data Page (if filtered data exists) ---
    if (filteredBloodPressure.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Blood Pressure Records', style: sectionTitleStyle),
                pw.SizedBox(height: 10),
                _buildTable(
                  headers: [
                    'Date & Time',
                    'Systolic (mmHg)',
                    'Diastolic (mmHg)',
                    'Notes'
                  ],
                  data: filteredBloodPressure // Use filtered data
                      .map((data) => <String>[
                            _formatDateTime(data['date_time'] as int?),
                            (data['systolic'] as int?)?.toString() ?? '',
                            (data['diastolic'] as int?)?.toString() ?? '',
                            (data['notes'] as String?) ?? '',
                          ])
                      .toList(),
                  getCellTextStyle: _getTextStyle, // Pass the function itself
                  headerTextStyle: pw.TextStyle(
                      font: _englishFont!,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold), // Headers are English
                ),
              ],
            );
          },
        ),
      );
    }

    // --- 4. Add Blood Sugar Data Page (if filtered data exists) ---
    if (filteredBloodSugar.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Blood Sugar Records', style: sectionTitleStyle),
                pw.SizedBox(height: 10),
                _buildTable(
                  headers: [
                    'Date & Time',
                    'Glucose (mg/dL)',
                    'Type',
                    'Category',
                    'Notes'
                  ],
                  data: filteredBloodSugar // Use filtered data
                      .map((data) => <String>[
                            _formatDateTime(data['date_time'] as int?),
                            (data['glucose'] as double?)?.toStringAsFixed(1) ??
                                '',
                            (data['measurement_type'] as String?) ?? '',
                            (data['category'] as String?) ?? '',
                            (data['notes'] as String?) ?? '',
                          ])
                      .toList(),
                  getCellTextStyle: _getTextStyle,
                  headerTextStyle: pw.TextStyle(
                      font: _englishFont!,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold),
                ),
              ],
            );
          },
        ),
      );
    }

    // --- 5. Add Daily Activity Data Page (if filtered data exists) ---
    if (filteredDailyActivity.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Daily Activity Records', style: sectionTitleStyle),
                pw.SizedBox(height: 10),
                _buildTable(
                  headers: [
                    'Date',
                    'Type',
                    'Steps',
                    'Calories Burned',
                    'Distance (km)',
                    'Duration (min)',
                    'Notes'
                  ],
                  data: filteredDailyActivity // Use filtered data
                      .map((data) => <String>[
                            _formatDate(data['date'] as int?),
                            (data['type'] as String?) ?? '',
                            (data['steps'] as int?)?.toString() ?? '',
                            (data['calories'] as double?)?.toStringAsFixed(1) ??
                                '',
                            (data['distance'] as double?)?.toStringAsFixed(2) ??
                                '',
                            (data['duration'] as int?)?.toString() ?? '',
                            (data['notes'] as String?) ?? '',
                          ])
                      .toList(),
                  getCellTextStyle: _getTextStyle,
                  headerTextStyle: pw.TextStyle(
                      font: _englishFont!,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold),
                ),
              ],
            );
          },
        ),
      );
    }

    // --- 6. File Saving and Sharing Logic ---
    Directory? directory;
    String folderName = 'HealthTracker_Reports';
    // Updated filename to include the time range
    String fileName =
        '${userName.replaceAll(' ', '_')}_HealthReport_${timeRange.name}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

    debugPrint('Attempting to get application documents directory...');
    directory = await getApplicationDocumentsDirectory();

    if (directory == null) {
      debugPrint('Error: getApplicationDocumentsDirectory() returned null.');
      throw Exception(
          'Could not determine a suitable directory to save the file.');
    }
    debugPrint('Base directory (Application Documents): ${directory.path}');

    final reportDirectory = Directory('${directory.path}/$folderName');
    debugPrint('Report directory path: ${reportDirectory.path}');

    if (!await reportDirectory.exists()) {
      debugPrint('Report directory does not exist, attempting to create.');
      try {
        await reportDirectory.create(recursive: true);
        debugPrint('Report directory created successfully.');
      } catch (e) {
        debugPrint('Error creating report directory: $e');
        throw Exception('Failed to create report directory: $e');
      }
    } else {
      debugPrint('Report directory already exists.');
    }

    final String filePath = '${reportDirectory.path}/$fileName';
    final File file = File(filePath);
    debugPrint('Final file path for private storage: $filePath');

    try {
      final Uint8List pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);
      debugPrint('PDF successfully saved to app-private storage: $filePath');

      if (file.existsSync()) {
        debugPrint('File exists in private storage. Initiating share sheet...');
        await Share.shareXFiles(
          [XFile(filePath)],
          text:
              'Your Health Report - $timeRangeDescription', // Updated share text
        );
        debugPrint('Share sheet presented to the user.');
      } else {
        debugPrint(
            'Error: File not found in private storage after saving. Cannot share.');
        throw Exception('File not found after saving. Cannot initiate share.');
      }
    } catch (e) {
      debugPrint('Error saving or sharing PDF file: $e');
      throw Exception(
          'Failed to export PDF: $e. Please ensure you have enough storage space or try sharing to a different app.');
    }

    if (kDebugMode) {
      debugPrint('PDF export process completed.');
    }
  }

  // --- Helper Methods ---

  /// Checks if a string contains any Burmese Unicode characters (U+1000 to U+109F).
  bool _containsBurmese(String text) {
    if (text.isEmpty) return false;
    for (int i = 0; i < text.length; i++) {
      int charCode = text.codeUnitAt(i);
      if (charCode >= 0x1000 && charCode <= 0x109F) {
        return true;
      }
    }
    return false;
  }

  // REWRITTEN: _buildTable to manually construct the table for per-cell styling
  pw.Table _buildTable({
    required List<String> headers,
    required List<List<String>> data,
    required pw.TextStyle Function(String text)
        getCellTextStyle, // Function to get style
    required pw.TextStyle headerTextStyle,
  }) {
    // Create the header row
    final headerRow = pw.TableRow(
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey300,
        border: pw.Border(
            bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey700)),
      ),
      children: headers
          .map((header) => pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(header, style: headerTextStyle),
                ),
              ))
          .toList(),
    );

    // Create the data rows
    final dataRows = data.map((row) {
      return pw.TableRow(
        decoration: const pw.BoxDecoration(
          border: pw.Border(
              bottom: pw.BorderSide(width: 0.2, color: PdfColors.grey400)),
        ),
        children: row
            .map((cellText) => pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    // Apply the dynamic text style for each cell's content
                    child: pw.Text(cellText, style: getCellTextStyle(cellText)),
                  ),
                ))
            .toList(),
      );
    }).toList();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        for (int i = 1; i < headers.length; i++)
          i: const pw.FlexColumnWidth(1.5),
        if (headers.length > 3)
          (headers.length - 1): const pw.FlexColumnWidth(3),
      },
      children: [
        headerRow, // Add the header row
        ...dataRows, // Add all the data rows
      ],
    );
  }

  String _formatDateTime(int? millisecondsSinceEpoch) {
    if (millisecondsSinceEpoch == null) return '';
    final dateTime =
        DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  String _formatDate(int? millisecondsSinceEpoch) {
    if (millisecondsSinceEpoch == null) return '';
    final dateTime =
        DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }
}
