import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../services/google_places_service.dart';
import '../services/place_cache_service.dart';
import '../theme/app_theme.dart';

/// Callback when a destination is selected
typedef OnDestinationSelected = void Function(PlaceDetails place);

/// Beautiful destination autocomplete widget with Google Places integration
class DestinationAutocomplete extends StatefulWidget {
  final String? initialValue;
  final OnDestinationSelected? onSelected;
  final String hintText;
  final String? labelText;
  final bool autofocus;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final String? restrictToCountry;

  const DestinationAutocomplete({
    super.key,
    this.initialValue,
    this.onSelected,
    this.hintText = 'Search destination...',
    this.labelText,
    this.autofocus = false,
    this.controller,
    this.focusNode,
    this.decoration,
    this.restrictToCountry,
  });

  @override
  State<DestinationAutocomplete> createState() => _DestinationAutocompleteState();
}

class _DestinationAutocompleteState extends State<DestinationAutocomplete> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  final GooglePlacesService _placesService = GooglePlacesService();
  final PlaceCacheService _cacheService = PlaceCacheService();
  final String _sessionToken = const Uuid().v4();

  List<PlacePrediction> _predictions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;
  PlaceDetails? _selectedPlace;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    _focusNode = widget.focusNode ?? FocusNode();

    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && _controller.text.isNotEmpty) {
      setState(() => _showSuggestions = true);
    }
  }

  void _onTextChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _predictions = [];
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _showSuggestions = true;
    });

    _placesService.getAutocompleteDebounced(
      query: query,
      types: '(cities)', // Filter to cities only
      components: widget.restrictToCountry != null
          ? 'country:${widget.restrictToCountry}'
          : null,
      sessionToken: _sessionToken,
      onResults: (predictions) {
        if (mounted) {
          setState(() {
            _predictions = predictions;
            _isLoading = false;
          });
        }
      },
    );
  }

  Future<void> _onPredictionSelected(PlacePrediction prediction) async {
    HapticFeedback.selectionClick();

    setState(() {
      _isLoading = true;
      _showSuggestions = false;
    });

    // Get full place details
    final details = await _cacheService.getPlaceDetails(prediction.placeId);

    if (details != null && mounted) {
      setState(() {
        _selectedPlace = details;
        _controller.text = details.shortName;
        _isLoading = false;
      });

      widget.onSelected?.call(details);
    } else {
      setState(() => _isLoading = false);
    }

    _focusNode.unfocus();
  }

  void _clearSelection() {
    setState(() {
      _controller.clear();
      _predictions = [];
      _selectedPlace = null;
      _showSuggestions = false;
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    _placesService.dispose();
    _cacheService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Input field
        _buildTextField(),

        // Suggestions dropdown
        if (_showSuggestions) _buildSuggestions(),
      ],
    );
  }

  Widget _buildTextField() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final defaultDecoration = InputDecoration(
      hintText: widget.hintText,
      labelText: widget.labelText,
      prefixIcon: Icon(
        Icons.location_on_outlined,
        color: _selectedPlace != null ? primaryColor : AppTheme.neutral400,
      ),
      suffixIcon: _buildSuffixIcon(),
      filled: true,
      fillColor: AppTheme.neutral50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.neutral200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.neutral200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      decoration: widget.decoration ?? defaultDecoration,
      onChanged: _onTextChanged,
      onTap: () {
        if (_controller.text.isNotEmpty && _predictions.isNotEmpty) {
          setState(() => _showSuggestions = true);
        }
      },
    );
  }

  Widget? _buildSuffixIcon() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_controller.text.isNotEmpty) {
      return IconButton(
        icon: const Icon(Icons.clear, size: 20),
        onPressed: _clearSelection,
      );
    }

    return null;
  }

  Widget _buildSuggestions() {
    if (_predictions.isEmpty && !_isLoading) {
      if (_controller.text.length >= 2) {
        return _buildNoResults();
      }
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: _predictions.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: AppTheme.neutral100,
            ),
            itemBuilder: (context, index) {
              final prediction = _predictions[index];
              return _buildPredictionTile(prediction);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPredictionTile(PlacePrediction prediction) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: () => _onPredictionSelected(prediction),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Type icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  prediction.typeIcon,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Place name and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prediction.mainText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (prediction.secondaryText.isNotEmpty)
                    Text(
                      prediction.secondaryText,
                      style: TextStyle(
                        color: AppTheme.neutral500,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Arrow indicator
            Icon(
              Icons.north_east,
              size: 16,
              color: AppTheme.neutral400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search_off, color: AppTheme.neutral400),
          const SizedBox(width: 12),
          Text(
            'No destinations found',
            style: TextStyle(color: AppTheme.neutral500),
          ),
        ],
      ),
    );
  }
}

/// Simplified destination picker dialog
class DestinationPickerDialog extends StatelessWidget {
  final String? initialValue;
  final String title;

  const DestinationPickerDialog({
    super.key,
    this.initialValue,
    this.title = 'Select Destination',
  });

  static Future<PlaceDetails?> show(
    BuildContext context, {
    String? initialValue,
    String title = 'Select Destination',
  }) {
    return showModalBottomSheet<PlaceDetails>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DestinationPickerDialog(
        initialValue: initialValue,
        title: title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.neutral300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: DestinationAutocomplete(
              initialValue: initialValue,
              autofocus: true,
              hintText: 'Search for a city or country...',
              onSelected: (place) {
                Navigator.pop(context, place);
              },
            ),
          ),

          const SizedBox(height: 20),

          // Popular destinations
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Popular Destinations',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.neutral600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Popular Indian destinations
                      _buildQuickPick(context, '🏖️', 'Goa', 'Goa, India'),
                      _buildQuickPick(context, '🏔️', 'Manali', 'Manali, Himachal Pradesh, India'),
                      _buildQuickPick(context, '🌴', 'Kerala', 'Kerala, India'),
                      _buildQuickPick(context, '🏰', 'Jaipur', 'Jaipur, Rajasthan, India'),
                      _buildQuickPick(context, '🏛️', 'Udaipur', 'Udaipur, Rajasthan, India'),
                      _buildQuickPick(context, '🌊', 'Andaman', 'Andaman and Nicobar Islands, India'),
                      _buildQuickPick(context, '❄️', 'Ladakh', 'Ladakh, India'),
                      _buildQuickPick(context, '🍃', 'Ooty', 'Ooty, Tamil Nadu, India'),
                      _buildQuickPick(context, '🌺', 'Pondicherry', 'Pondicherry, India'),
                      _buildQuickPick(context, '🏞️', 'Shimla', 'Shimla, Himachal Pradesh, India'),
                      _buildQuickPick(context, '🌿', 'Coorg', 'Coorg, Karnataka, India'),
                      _buildQuickPick(context, '🏝️', 'Lakshadweep', 'Lakshadweep, India'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Powered by Google
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Powered by ',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.neutral400,
                  ),
                ),
                Image.network(
                  'https://www.gstatic.com/images/branding/googlelogo/2x/googlelogo_color_74x24dp.png',
                  height: 14,
                  errorBuilder: (_, __, ___) => Text(
                    'Google',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.neutral600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPick(BuildContext context, String emoji, String name, String searchQuery) {
    return ActionChip(
      avatar: Text(emoji),
      label: Text(name),
      backgroundColor: AppTheme.neutral100,
      side: BorderSide.none,
      onPressed: () async {
        // Search for this destination using Google Places
        final placesService = GooglePlacesService();
        final cacheService = PlaceCacheService();

        try {
          // Get autocomplete predictions for the destination
          final predictions = await placesService.getAutocomplete(
            query: searchQuery,
            types: '(cities)',
          );

          if (predictions.isNotEmpty) {
            // Get the first (best) match and fetch its details
            final details = await cacheService.getPlaceDetails(predictions.first.placeId);
            if (details != null && context.mounted) {
              Navigator.pop(context, details);
              return;
            }
          }

          // If no predictions found, create a basic PlaceDetails with the name
          if (context.mounted) {
            Navigator.pop(context, PlaceDetails(
              placeId: '',
              name: name,
              formattedAddress: searchQuery,
              photos: const [],
              types: const ['locality'],
            ));
          }
        } catch (e) {
          // On error, just return the name as a basic place
          if (context.mounted) {
            Navigator.pop(context, PlaceDetails(
              placeId: '',
              name: name,
              formattedAddress: searchQuery,
              photos: const [],
              types: const ['locality'],
            ));
          }
        }
      },
    );
  }
}
