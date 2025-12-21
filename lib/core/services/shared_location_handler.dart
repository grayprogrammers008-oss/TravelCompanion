import 'dart:async';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'google_maps_url_parser.dart';
import '../../features/itinerary/presentation/widgets/add_location_to_trip_sheet.dart';

/// Service to handle shared content from other apps (e.g., Google Maps)
class SharedLocationHandler {
  static StreamSubscription<List<SharedMediaFile>>? _mediaSubscription;
  static BuildContext? _context;
  static ParsedLocation? _pendingLocation;

  /// Initialize the handler to listen for shared content
  static void initialize() {
    try {
      debugPrint('🔗 SharedLocationHandler: Initializing...');

      // Handle initial share when app is opened via share
      _handleInitialShare();

      // Listen for shares while app is running
      _mediaSubscription = ReceiveSharingIntent.instance.getMediaStream().listen(
        (List<SharedMediaFile> value) {
          debugPrint('🔗 SharedLocationHandler: Received ${value.length} shared items');
          for (final file in value) {
            debugPrint('   Type: ${file.type}, Path: ${file.path}');
            if (file.type == SharedMediaType.text || file.type == SharedMediaType.url) {
              _processSharedText(file.path);
            }
          }
        },
        onError: (error) {
          debugPrint('❌ SharedLocationHandler: Error receiving shared content: $error');
        },
      );
    } catch (e, stackTrace) {
      debugPrint('❌ SharedLocationHandler: Failed to initialize: $e');
      debugPrint('Stack trace: $stackTrace');
      // Don't crash - just disable sharing functionality
    }
  }

  /// Set the current context for showing dialogs
  static void setContext(BuildContext context) {
    _context = context;
    // If there's a pending location, show it now
    if (_pendingLocation != null) {
      final location = _pendingLocation!;
      _pendingLocation = null;
      _showAddSheet(location);
    }
  }

  /// Handle initial share when app was opened via share intent
  static Future<void> _handleInitialShare() async {
    try {
      debugPrint('🔗 SharedLocationHandler: Checking for initial share...');
      final initialMedia = await ReceiveSharingIntent.instance.getInitialMedia();
      debugPrint('🔗 SharedLocationHandler: Found ${initialMedia.length} initial items');

      for (final file in initialMedia) {
        debugPrint('   Type: ${file.type}, Path: ${file.path}');
        if (file.type == SharedMediaType.text || file.type == SharedMediaType.url) {
          _processSharedText(file.path);
          break; // Only process first valid share
        }
      }

      // Clear the intent after processing
      ReceiveSharingIntent.instance.reset();
    } catch (e, stackTrace) {
      debugPrint('❌ SharedLocationHandler: Error handling initial share: $e');
      debugPrint('Stack trace: $stackTrace');
      // Don't crash the app on share handling errors
    }
  }

  /// Process shared text to check if it's a Google Maps URL
  static void _processSharedText(String sharedText) {
    debugPrint('🔗 SharedLocationHandler: Processing text: $sharedText');

    // Extract URL from shared text (in case there's additional text)
    final url = GoogleMapsUrlParser.extractUrl(sharedText);
    if (url == null) {
      debugPrint('⚠️ SharedLocationHandler: No Google Maps URL found');
      return;
    }

    debugPrint('🔗 SharedLocationHandler: Found URL: $url');

    // Parse the URL
    final parsedLocation = GoogleMapsUrlParser.parse(url);
    if (parsedLocation == null) {
      debugPrint('⚠️ SharedLocationHandler: Failed to parse URL');
      return;
    }

    debugPrint('✅ SharedLocationHandler: Parsed location: ${parsedLocation.placeName} (${parsedLocation.latitude}, ${parsedLocation.longitude})');

    _showAddSheet(parsedLocation);
  }

  /// Show the add location sheet
  static void _showAddSheet(ParsedLocation location) {
    if (_context != null && _context!.mounted) {
      debugPrint('🔗 SharedLocationHandler: Showing add sheet...');
      // Add a small delay to ensure the app is fully ready
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_context != null && _context!.mounted) {
          AddLocationToTripSheet.show(_context!, location);
        }
      });
    } else {
      debugPrint('⏳ SharedLocationHandler: Context not ready, saving for later...');
      _pendingLocation = location;
    }
  }

  /// Dispose subscriptions
  static void dispose() {
    _mediaSubscription?.cancel();
    _mediaSubscription = null;
    _context = null;
    _pendingLocation = null;
  }

  /// Manually process a shared URL (for testing or deep links)
  static Future<bool> processUrl(BuildContext context, String url) async {
    final parsedLocation = GoogleMapsUrlParser.parse(url);
    if (parsedLocation == null) {
      return false;
    }

    return await AddLocationToTripSheet.show(context, parsedLocation);
  }
}
