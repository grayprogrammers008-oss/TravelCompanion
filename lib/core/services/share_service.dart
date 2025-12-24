// Share Service
//
// Provides sharing functionality for trips, itineraries, and other content
// with support for WhatsApp, general sharing, and clipboard copy.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../shared/models/trip_model.dart';
import '../../features/ai_itinerary/domain/entities/ai_itinerary.dart';

/// Service for sharing content via WhatsApp and other platforms
class ShareService {
  // WhatsApp URL schemes
  static const String _whatsAppUrl = 'https://wa.me/';
  static const String _whatsAppApiUrl = 'https://api.whatsapp.com/send?text=';

  // =====================================================
  // TRIP SHARING
  // =====================================================

  /// Share trip details via WhatsApp
  static Future<bool> shareToWhatsApp(String text, {String? phoneNumber}) async {
    try {
      String url;
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        // Send to specific number
        final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
        url = '$_whatsAppUrl$cleanPhone?text=${Uri.encodeComponent(text)}';
      } else {
        // Open WhatsApp with text (user selects contact)
        url = '$_whatsAppApiUrl${Uri.encodeComponent(text)}';
      }

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error sharing to WhatsApp: $e');
      return false;
    }
  }

  /// Share content using system share sheet
  static Future<void> shareGeneral(String text, {String? subject}) async {
    await Share.share(text, subject: subject);
  }

  /// Copy text to clipboard
  static Future<void> copyToClipboard(String text, BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // =====================================================
  // FORMATTED CONTENT GENERATORS
  // =====================================================

  /// Format trip for sharing
  static String formatTrip(TripModel trip, {bool includeInviteLink = false, String? inviteCode}) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final buffer = StringBuffer();

    buffer.writeln('🌴 *${trip.name}*');
    buffer.writeln();

    if (trip.destination != null && trip.destination!.isNotEmpty) {
      buffer.writeln('📍 *Destination:* ${trip.destination}');
    }

    if (trip.startDate != null && trip.endDate != null) {
      buffer.writeln('📅 *Dates:* ${dateFormat.format(trip.startDate!)} - ${dateFormat.format(trip.endDate!)}');
      final duration = trip.endDate!.difference(trip.startDate!).inDays + 1;
      buffer.writeln('⏱️ *Duration:* $duration ${duration == 1 ? 'day' : 'days'}');
    }

    if (trip.cost != null && trip.cost! > 0) {
      final costFormat = NumberFormat.currency(
        symbol: trip.currency,
        decimalDigits: 0,
      );
      buffer.writeln('💰 *Cost:* ${costFormat.format(trip.cost)}');
    }

    if (trip.description != null && trip.description!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('📝 ${trip.description}');
    }

    if (includeInviteLink && inviteCode != null) {
      buffer.writeln();
      buffer.writeln('🔗 *Join this trip:*');
      buffer.writeln('Use code: *$inviteCode*');
    }

    buffer.writeln();
    buffer.writeln('_Planned with TravelCompanion_ ✈️');

    return buffer.toString();
  }

  /// Format AI-generated itinerary for sharing
  static String formatAiItinerary(AiGeneratedItinerary itinerary) {
    final buffer = StringBuffer();

    buffer.writeln('🗺️ *${itinerary.destination} Trip*');
    buffer.writeln();
    buffer.writeln('📍 *Destination:* ${itinerary.destination}');
    buffer.writeln('⏱️ *Duration:* ${itinerary.durationDays} ${itinerary.durationDays == 1 ? 'day' : 'days'}');

    if (itinerary.budget != null && itinerary.budget! > 0) {
      final budgetFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
      buffer.writeln('💰 *Estimated Budget:* ${budgetFormat.format(itinerary.budget)}');
    }

    buffer.writeln();
    buffer.writeln('*📋 ITINERARY*');
    buffer.writeln('─────────────');

    for (final day in itinerary.days) {
      buffer.writeln();
      buffer.writeln('*Day ${day.dayNumber}: ${day.title ?? 'Day ${day.dayNumber}'}*');

      for (final activity in day.activities) {
        final timeStr = activity.startTime != null ? '${activity.startTime} - ' : '';
        buffer.writeln('  • $timeStr${activity.title}');
        if (activity.location != null && activity.location!.isNotEmpty) {
          buffer.writeln('    📍 ${activity.location}');
        }
      }
    }

    if (itinerary.packingList.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('*🎒 PACKING LIST*');
      buffer.writeln('─────────────');

      // Group by category
      final categories = <String, List<AiPackingItem>>{};
      for (final item in itinerary.packingList) {
        final category = item.category ?? 'Other';
        categories.putIfAbsent(category, () => []).add(item);
      }

      for (final entry in categories.entries) {
        buffer.writeln();
        buffer.writeln('*${entry.key}:*');
        for (final item in entry.value) {
          buffer.writeln('  ☐ ${item.item}');
        }
      }
    }

    if (itinerary.tips.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('*💡 TRAVEL TIPS*');
      buffer.writeln('─────────────');
      for (final tip in itinerary.tips) {
        buffer.writeln('  • $tip');
      }
    }

    buffer.writeln();
    buffer.writeln('_Generated with TravelCompanion AI_ 🤖✈️');

    return buffer.toString();
  }

  /// Format a compact version of AI itinerary (for quick share)
  static String formatAiItineraryCompact(AiGeneratedItinerary itinerary) {
    final buffer = StringBuffer();

    buffer.writeln('🗺️ *${itinerary.destination} Trip*');
    buffer.writeln('📍 ${itinerary.destination} • ${itinerary.durationDays} days');

    if (itinerary.budget != null && itinerary.budget! > 0) {
      final budgetFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
      buffer.writeln('💰 ~${budgetFormat.format(itinerary.budget)}');
    }

    buffer.writeln();

    for (final day in itinerary.days) {
      buffer.writeln('*Day ${day.dayNumber}:* ${day.title ?? 'Day ${day.dayNumber}'}');
      final highlights = day.activities.take(3).map((a) => a.title).join(' → ');
      buffer.writeln('  $highlights');
    }

    buffer.writeln();
    buffer.writeln('_TravelCompanion AI_ ✈️');

    return buffer.toString();
  }

  /// Format expense summary for sharing
  static String formatExpenseSummary({
    required String tripName,
    required double totalExpenses,
    required String currency,
    required int memberCount,
    double? budget,
    Map<String, double>? categoryBreakdown,
  }) {
    final currencyFormat = NumberFormat.currency(symbol: currency, decimalDigits: 0);
    final buffer = StringBuffer();

    buffer.writeln('💰 *Expense Summary*');
    buffer.writeln('📍 Trip: $tripName');
    buffer.writeln();
    buffer.writeln('*Total Spent:* ${currencyFormat.format(totalExpenses)}');
    buffer.writeln('👥 *Members:* $memberCount');

    if (budget != null && budget > 0) {
      final remaining = budget - totalExpenses;
      buffer.writeln('📊 *Budget:* ${currencyFormat.format(budget)}');
      buffer.writeln(remaining >= 0
          ? '✅ *Remaining:* ${currencyFormat.format(remaining)}'
          : '⚠️ *Over Budget:* ${currencyFormat.format(remaining.abs())}');
    }

    if (categoryBreakdown != null && categoryBreakdown.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('*By Category:*');
      categoryBreakdown.forEach((category, amount) {
        final emoji = _getCategoryEmoji(category);
        buffer.writeln('  $emoji $category: ${currencyFormat.format(amount)}');
      });
    }

    buffer.writeln();
    buffer.writeln('_TravelCompanion_ ✈️');

    return buffer.toString();
  }

  /// Format checklist for sharing
  static String formatChecklist({
    required String checklistName,
    required List<String> items,
    required List<bool> completedStatus,
    String? tripName,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('📋 *$checklistName*');
    if (tripName != null) {
      buffer.writeln('📍 Trip: $tripName');
    }
    buffer.writeln();

    for (var i = 0; i < items.length; i++) {
      final status = completedStatus.length > i && completedStatus[i] ? '✅' : '☐';
      buffer.writeln('$status ${items[i]}');
    }

    final completed = completedStatus.where((s) => s).length;
    buffer.writeln();
    buffer.writeln('Progress: $completed/${items.length} completed');
    buffer.writeln();
    buffer.writeln('_TravelCompanion_ ✈️');

    return buffer.toString();
  }

  // =====================================================
  // HELPER METHODS
  // =====================================================

  static String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'dining':
      case 'restaurant':
        return '🍽️';
      case 'transport':
      case 'transportation':
      case 'travel':
        return '🚗';
      case 'accommodation':
      case 'hotel':
      case 'lodging':
        return '🏨';
      case 'activities':
      case 'entertainment':
      case 'sightseeing':
        return '🎭';
      case 'shopping':
        return '🛍️';
      case 'health':
      case 'medical':
        return '🏥';
      case 'communication':
        return '📱';
      default:
        return '📦';
    }
  }
}

/// Extension to make sharing easier from Trip objects
extension TripShareExtension on TripModel {
  /// Share this trip via WhatsApp
  Future<bool> shareToWhatsApp({String? inviteCode}) async {
    final text = ShareService.formatTrip(
      this,
      includeInviteLink: inviteCode != null,
      inviteCode: inviteCode,
    );
    return ShareService.shareToWhatsApp(text);
  }

  /// Share this trip via system share sheet
  Future<void> shareGeneral({String? inviteCode}) async {
    final text = ShareService.formatTrip(
      this,
      includeInviteLink: inviteCode != null,
      inviteCode: inviteCode,
    );
    await ShareService.shareGeneral(text, subject: 'Trip: $name');
  }
}

/// Extension to make sharing easier from AI Itinerary objects
extension AiItineraryShareExtension on AiGeneratedItinerary {
  /// Share this itinerary via WhatsApp
  Future<bool> shareToWhatsAppItinerary({bool compact = false}) async {
    final text = compact
        ? ShareService.formatAiItineraryCompact(this)
        : ShareService.formatAiItinerary(this);
    return ShareService.shareToWhatsApp(text);
  }

  /// Share this itinerary via system share sheet
  Future<void> shareGeneralItinerary({bool compact = false}) async {
    final text = compact
        ? ShareService.formatAiItineraryCompact(this)
        : ShareService.formatAiItinerary(this);
    await ShareService.shareGeneral(text, subject: 'Itinerary: $destination');
  }
}
