import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../shared/models/trip_model.dart';
import '../../features/checklists/domain/entities/checklist_entity.dart';
import '../../features/itinerary/domain/entities/itinerary_entity.dart';

/// Beautiful PDF Export Service for Trip Details
/// Creates professional, well-designed PDF documents
class PdfExportService {
  // Brand colors
  static const _primaryColor = PdfColors.teal;
  static const _primaryLight = PdfColors.teal50;
  static const _accentColor = PdfColors.amber700;
  static const _successColor = PdfColors.green600;
  static const _textColor = PdfColors.grey800;
  static const _subtitleColor = PdfColors.grey600;
  static const _borderColor = PdfColors.grey300;
  static const _bgColor = PdfColors.grey50;

  /// Generate and share/print a trip PDF
  static Future<void> exportTrip({
    required BuildContext context,
    required TripModel trip,
    required List<TripMemberModel> members,
    List<ChecklistWithItemsEntity>? checklists,
    List<ItineraryItemEntity>? itinerary,
  }) async {
    debugPrint('📄 PDF Export: Starting...');
    debugPrint('📄 PDF Export: Trip: ${trip.name}');
    debugPrint('📄 PDF Export: Members: ${members.length}');
    debugPrint('📄 PDF Export: Checklists: ${checklists?.length ?? 0}');
    debugPrint('📄 PDF Export: Itinerary: ${itinerary?.length ?? 0}');

    // Capture render box before async operations (required for iPad share popover)
    final box = context.findRenderObject() as RenderBox?;
    final sharePositionOrigin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : const Rect.fromLTWH(0, 0, 100, 100);

    try {
      final pdf = pw.Document();
      debugPrint('📄 PDF Export: Document created');

      // Build sections
      final sections = <pw.Widget>[];

      // Hero section with trip overview
      sections.add(_buildHeroSection(trip, members));
      sections.add(pw.SizedBox(height: 24));

      // Quick stats row (simplified - no expenses)
      sections.add(_buildQuickStats(trip, itinerary, checklists));
      sections.add(pw.SizedBox(height: 24));

      // Add itinerary if available
      if (itinerary != null && itinerary.isNotEmpty) {
        debugPrint('📄 PDF Export: Adding itinerary section (${itinerary.length} items)');
        sections.add(_buildItinerarySection(itinerary, trip.startDate));
        sections.add(pw.SizedBox(height: 24));
      } else {
        debugPrint('📄 PDF Export: Skipping itinerary - null: ${itinerary == null}, empty: ${itinerary?.isEmpty}');
      }

      // Add checklists if available
      if (checklists != null && checklists.isNotEmpty) {
        debugPrint('📄 PDF Export: Adding checklists section (${checklists.length} items)');
        sections.add(_buildChecklistsSection(checklists));
      } else {
        debugPrint('📄 PDF Export: Skipping checklists - null: ${checklists == null}, empty: ${checklists?.isEmpty}');
      }

      // Add pages
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildHeader(trip, context),
          footer: (context) => _buildFooter(context),
          build: (context) => sections,
        ),
      );
      debugPrint('📄 PDF Export: Pages added with ${sections.length} sections');

      // Generate PDF bytes
      debugPrint('📄 PDF Export: Generating PDF bytes...');
      final bytes = await pdf.save();
      debugPrint('📄 PDF Export: PDF bytes generated: ${bytes.length}');

      // Save to temp file and share
      final tempDir = await getTemporaryDirectory();
      final fileName = '${trip.name.replaceAll(RegExp(r'[^\w\s-]'), '')}_trip_details.pdf';
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      debugPrint('📄 PDF Export: File saved to: $filePath');

      // Share the file
      debugPrint('📄 PDF Export: Opening share dialog...');
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: '${trip.name} - Trip Details',
        text: 'Here are the details for the trip "${trip.name}"',
        sharePositionOrigin: sharePositionOrigin,
      );
      debugPrint('📄 PDF Export: Share dialog closed');
    } catch (e, stackTrace) {
      debugPrint('📄 PDF Export ERROR: $e');
      debugPrint('📄 PDF Export STACK: $stackTrace');
      rethrow;
    }
  }

  /// Build PDF header
  static pw.Widget _buildHeader(TripModel trip, pw.Context context) {
    if (context.pageNumber == 1) {
      return pw.SizedBox.shrink();
    }
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _borderColor, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            trip.name,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber}',
            style: const pw.TextStyle(fontSize: 10, color: _subtitleColor),
          ),
        ],
      ),
    );
  }

  /// Build PDF footer
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _borderColor, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 8,
                height: 8,
                decoration: const pw.BoxDecoration(
                  color: _primaryColor,
                  shape: pw.BoxShape.circle,
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Text(
                'TravelCompanion',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: _primaryColor,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.Text(
            'Generated on ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 9, color: _subtitleColor),
          ),
        ],
      ),
    );
  }

  /// Build hero section with trip name and destination
  static pw.Widget _buildHeroSection(TripModel trip, List<TripMemberModel> members) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return pw.Container(
      padding: const pw.EdgeInsets.all(24),
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(
          colors: [_primaryColor, PdfColors.teal700],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Status badge
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: pw.BoxDecoration(
              color: trip.isCompleted ? _successColor : _accentColor,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Text(
              trip.isCompleted ? 'COMPLETED' : 'ACTIVE TRIP',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                letterSpacing: 1,
              ),
            ),
          ),
          pw.SizedBox(height: 12),
          // Trip name
          pw.Text(
            trip.name,
            style: pw.TextStyle(
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          if (trip.destination != null) ...[
            pw.SizedBox(height: 4),
            pw.Row(
              children: [
                pw.Container(
                  width: 14,
                  height: 14,
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.white,
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'L',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: _primaryColor,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.Text(
                  trip.destination!,
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
          pw.SizedBox(height: 16),
          // Date range
          if (trip.startDate != null && trip.endDate != null)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: pw.BoxDecoration(
                color: PdfColors.white.shade(0.2),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    '${dateFormat.format(trip.startDate!)} - ${dateFormat.format(trip.endDate!)}',
                    style: pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Text(
                    '(${trip.endDate!.difference(trip.startDate!).inDays + 1} days)',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
                  ),
                ],
              ),
            ),
          if (trip.description != null && trip.description!.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text(
              trip.description!,
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.white),
              maxLines: 3,
            ),
          ],
        ],
      ),
    );
  }

  /// Build quick stats row
  static pw.Widget _buildQuickStats(
    TripModel trip,
    List<ItineraryItemEntity>? itinerary,
    List<ChecklistWithItemsEntity>? checklists,
  ) {
    // Calculate total checklist items across all checklists
    int totalChecklistItems = 0;
    if (checklists != null) {
      for (final checklist in checklists) {
        totalChecklistItems += checklist.items.length;
      }
    }

    return pw.Row(
      children: [
        pw.Expanded(child: _buildStatCard('Activities', '${itinerary?.length ?? 0}', PdfColors.orange)),
        pw.SizedBox(width: 12),
        pw.Expanded(child: _buildStatCard('Items', '$totalChecklistItems', PdfColors.green)),
        if (trip.cost != null) ...[
          pw.SizedBox(width: 12),
          pw.Expanded(child: _buildStatCard('Cost', '${trip.currency} ${trip.cost!.toStringAsFixed(0)}', PdfColors.purple)),
        ],
      ],
    );
  }

  /// Build stat card
  static pw.Widget _buildStatCard(String label, String value, PdfColor accentColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _bgColor,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _borderColor, width: 0.5),
      ),
      child: pw.Column(
        children: [
          pw.Container(
            width: 28,
            height: 28,
            decoration: pw.BoxDecoration(
              color: accentColor,
              shape: pw.BoxShape.circle,
            ),
            child: pw.Center(
              child: pw.Text(
                label[0],
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.white,
                ),
              ),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: _textColor,
            ),
          ),
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 9, color: _subtitleColor),
          ),
        ],
      ),
    );
  }

  /// Build itinerary section
  static pw.Widget _buildItinerarySection(
    List<ItineraryItemEntity> itinerary,
    DateTime? tripStartDate,
  ) {
    final dateFormat = DateFormat('EEE, MMM d');
    final timeFormat = DateFormat('h:mm a');

    // Group by day (using startTime or dayNumber)
    final grouped = <String, List<ItineraryItemEntity>>{};
    for (final item in itinerary) {
      String dateKey;
      if (item.startTime != null) {
        dateKey = dateFormat.format(item.startTime!);
      } else if (item.dayNumber != null && tripStartDate != null) {
        final itemDate = tripStartDate.add(Duration(days: item.dayNumber! - 1));
        dateKey = 'Day ${item.dayNumber} - ${dateFormat.format(itemDate)}';
      } else if (item.dayNumber != null) {
        dateKey = 'Day ${item.dayNumber}';
      } else {
        dateKey = 'Unscheduled';
      }
      grouped.putIfAbsent(dateKey, () => []).add(item);
    }

    // Sort items within each group by orderIndex or startTime
    for (final items in grouped.values) {
      items.sort((a, b) {
        if (a.startTime != null && b.startTime != null) {
          return a.startTime!.compareTo(b.startTime!);
        }
        return a.orderIndex.compareTo(b.orderIndex);
      });
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Itinerary', '${itinerary.length} activities'),
        pw.SizedBox(height: 12),
        ...grouped.entries.map((entry) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 16),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Day header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: _primaryLight,
                  borderRadius: const pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(8),
                    topRight: pw.Radius.circular(8),
                  ),
                ),
                child: pw.Text(
                  entry.key,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: _primaryColor,
                    fontSize: 11,
                  ),
                ),
              ),
              // Activities
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _borderColor, width: 0.5),
                  borderRadius: const pw.BorderRadius.only(
                    bottomLeft: pw.Radius.circular(8),
                    bottomRight: pw.Radius.circular(8),
                  ),
                ),
                child: pw.Column(
                  children: entry.value.asMap().entries.map((activityEntry) {
                    final index = activityEntry.key;
                    final item = activityEntry.value;
                    final isLast = index == entry.value.length - 1;

                    return pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: isLast
                            ? null
                            : const pw.Border(
                                bottom: pw.BorderSide(color: _borderColor, width: 0.5),
                              ),
                      ),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Time column
                          pw.Container(
                            width: 60,
                            child: item.startTime != null
                                ? pw.Text(
                                    timeFormat.format(item.startTime!),
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      color: _primaryColor,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  )
                                : pw.Text(
                                    '—',
                                    style: const pw.TextStyle(
                                      fontSize: 9,
                                      color: _subtitleColor,
                                    ),
                                  ),
                          ),
                          // Activity details
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  item.title,
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 11,
                                    color: _textColor,
                                  ),
                                ),
                                if (item.location != null) ...[
                                  pw.SizedBox(height: 2),
                                  pw.Text(
                                    item.location!,
                                    style: const pw.TextStyle(
                                      fontSize: 9,
                                      color: _subtitleColor,
                                    ),
                                  ),
                                ],
                                if (item.description != null && item.description!.isNotEmpty) ...[
                                  pw.SizedBox(height: 4),
                                  pw.Text(
                                    item.description!,
                                    style: const pw.TextStyle(fontSize: 9, color: _subtitleColor),
                                    maxLines: 2,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  /// Build checklists section
  static pw.Widget _buildChecklistsSection(List<ChecklistWithItemsEntity> checklists) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Checklists', '${checklists.length} lists'),
        pw.SizedBox(height: 12),
        pw.Wrap(
          spacing: 12,
          runSpacing: 12,
          children: checklists.map((checklist) {
            final progress = checklist.items.isEmpty
                ? 0.0
                : checklist.completedCount / checklist.items.length;

            return pw.Container(
              width: 240,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _borderColor, width: 0.5),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          checklist.checklist.name,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: progress == 1 ? _successColor : _primaryLight,
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Text(
                          '${checklist.completedCount}/${checklist.items.length}',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: progress == 1 ? PdfColors.white : _primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  // Progress bar
                  pw.Container(
                    height: 4,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.circular(2),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: (progress * 100).round(),
                          child: pw.Container(
                            decoration: pw.BoxDecoration(
                              color: progress == 1 ? _successColor : _primaryColor,
                              borderRadius: pw.BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        if (progress < 1)
                          pw.Expanded(
                            flex: ((1 - progress) * 100).round(),
                            child: pw.Container(),
                          ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  // Items
                  ...checklist.items.take(6).map((item) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      children: [
                        pw.Container(
                          width: 10,
                          height: 10,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(
                              color: item.isCompleted ? _successColor : _borderColor,
                              width: 1,
                            ),
                            borderRadius: pw.BorderRadius.circular(2),
                            color: item.isCompleted ? _successColor : PdfColors.white,
                          ),
                          child: item.isCompleted
                              ? pw.Center(
                                  child: pw.Text(
                                    '✓',
                                    style: const pw.TextStyle(
                                      fontSize: 6,
                                      color: PdfColors.white,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        pw.SizedBox(width: 6),
                        pw.Expanded(
                          child: pw.Text(
                            item.title,
                            style: pw.TextStyle(
                              fontSize: 9,
                              decoration: item.isCompleted ? pw.TextDecoration.lineThrough : null,
                              color: item.isCompleted ? _subtitleColor : _textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                  if (checklist.items.length > 6)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 4),
                      child: pw.Text(
                        '+ ${checklist.items.length - 6} more items...',
                        style: const pw.TextStyle(fontSize: 8, color: _subtitleColor),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Build section header
  static pw.Widget _buildSectionHeader(String title, String subtitle) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: _textColor,
          ),
        ),
        pw.Text(
          subtitle,
          style: const pw.TextStyle(fontSize: 10, color: _subtitleColor),
        ),
      ],
    );
  }
}
