import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/theme_access.dart';
import '../../shared/models/trip_model.dart';
import 'destination_image.dart';

/// A model to hold member data with usage frequency
class MemberWithFrequency {
  final TripMemberModel member;
  final int frequency;

  MemberWithFrequency({
    required this.member,
    this.frequency = 0,
  });
}

/// A reusable member picker widget for selecting trip members
///
/// Features:
/// - Multi-select with checkboxes
/// - Search/filter by name
/// - Frequency-based sorting (most used members first)
/// - Displays avatar, name, and email
class MemberPickerWidget extends StatefulWidget {
  /// List of all available members
  final List<TripMemberModel> members;

  /// Currently selected member IDs
  final List<String> selectedMemberIds;

  /// Callback when selection changes
  final ValueChanged<List<String>> onSelectionChanged;

  /// Map of member ID to usage frequency (for sorting)
  final Map<String, int>? memberFrequency;

  /// Whether to show a "Select All" option
  final bool showSelectAll;

  /// Label text for the field
  final String? labelText;

  /// Hint text when no members are selected
  final String? hintText;

  const MemberPickerWidget({
    super.key,
    required this.members,
    required this.selectedMemberIds,
    required this.onSelectionChanged,
    this.memberFrequency,
    this.showSelectAll = true,
    this.labelText,
    this.hintText,
  });

  @override
  State<MemberPickerWidget> createState() => _MemberPickerWidgetState();
}

class _MemberPickerWidgetState extends State<MemberPickerWidget> {
  void _showMemberPickerDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MemberPickerBottomSheet(
        members: widget.members,
        selectedMemberIds: widget.selectedMemberIds,
        memberFrequency: widget.memberFrequency,
        showSelectAll: widget.showSelectAll,
        onSelectionChanged: widget.onSelectionChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = context.appThemeData;
    final selectedCount = widget.selectedMemberIds.length;
    final totalCount = widget.members.length;

    // Get selected members for display
    final selectedMembers = widget.members
        .where((m) => widget.selectedMemberIds.contains(m.userId))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.neutral700,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
        ],

        // Tap area to open picker
        InkWell(
          onTap: _showMemberPickerDialog,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: AppTheme.neutral300,
                width: 1,
              ),
              boxShadow: AppTheme.shadowSm,
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSm),
                  decoration: BoxDecoration(
                    color: themeData.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(
                    Icons.people_outline,
                    color: themeData.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),

                // Content
                Expanded(
                  child: selectedMembers.isEmpty
                      ? Text(
                          widget.hintText ?? 'Select members to split with',
                          style: TextStyle(
                            color: AppTheme.neutral500,
                            fontSize: 14,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Selected count
                            Text(
                              '$selectedCount of $totalCount members selected',
                              style: TextStyle(
                                color: AppTheme.neutral700,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacing2xs),

                            // Avatar row
                            SizedBox(
                              height: 32,
                              child: Row(
                                children: [
                                  // Show up to 4 avatars
                                  ...selectedMembers.take(4).map((member) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: UserAvatarWidget(
                                        imageUrl: member.avatarUrl,
                                        userName: member.fullName,
                                        size: 28,
                                      ),
                                    );
                                  }),

                                  // +N more indicator
                                  if (selectedMembers.length > 4)
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: themeData.primaryColor.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '+${selectedMembers.length - 4}',
                                          style: TextStyle(
                                            color: themeData.primaryColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
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

                // Chevron
                Icon(
                  Icons.keyboard_arrow_down,
                  color: AppTheme.neutral500,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet for member selection
class _MemberPickerBottomSheet extends StatefulWidget {
  final List<TripMemberModel> members;
  final List<String> selectedMemberIds;
  final Map<String, int>? memberFrequency;
  final bool showSelectAll;
  final ValueChanged<List<String>> onSelectionChanged;

  const _MemberPickerBottomSheet({
    required this.members,
    required this.selectedMemberIds,
    this.memberFrequency,
    required this.showSelectAll,
    required this.onSelectionChanged,
  });

  @override
  State<_MemberPickerBottomSheet> createState() => _MemberPickerBottomSheetState();
}

class _MemberPickerBottomSheetState extends State<_MemberPickerBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  late List<String> _localSelectedIds;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _localSelectedIds = List.from(widget.selectedMemberIds);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MemberWithFrequency> get _sortedMembers {
    final membersWithFreq = widget.members.map((m) {
      return MemberWithFrequency(
        member: m,
        frequency: widget.memberFrequency?[m.userId] ?? 0,
      );
    }).toList();

    membersWithFreq.sort((a, b) {
      final freqCompare = b.frequency.compareTo(a.frequency);
      if (freqCompare != 0) return freqCompare;
      final nameA = a.member.fullName ?? a.member.email ?? '';
      final nameB = b.member.fullName ?? b.member.email ?? '';
      return nameA.toLowerCase().compareTo(nameB.toLowerCase());
    });

    return membersWithFreq;
  }

  List<MemberWithFrequency> get _filteredMembers {
    if (_searchQuery.isEmpty) return _sortedMembers;

    final query = _searchQuery.toLowerCase();
    return _sortedMembers.where((mf) {
      final name = mf.member.fullName?.toLowerCase() ?? '';
      final email = mf.member.email?.toLowerCase() ?? '';
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  bool get _allSelected =>
      _localSelectedIds.length == widget.members.length &&
      widget.members.isNotEmpty;

  void _toggleMember(String userId) {
    setState(() {
      if (_localSelectedIds.contains(userId)) {
        _localSelectedIds.remove(userId);
      } else {
        _localSelectedIds.add(userId);
      }
    });
  }

  void _toggleAll() {
    setState(() {
      if (_allSelected) {
        _localSelectedIds.clear();
      } else {
        _localSelectedIds = widget.members.map((m) => m.userId).toList();
      }
    });
  }

  void _confirmSelection() {
    widget.onSelectionChanged(_localSelectedIds);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = context.appThemeData;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Row(
              children: [
                Icon(
                  Icons.people,
                  color: themeData.primaryColor,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  'Select Members',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.neutral900,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _confirmSelection,
                  child: Text(
                    'Done',
                    style: TextStyle(
                      color: themeData.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              decoration: InputDecoration(
                hintText: 'Search by name...',
                hintStyle: TextStyle(color: AppTheme.neutral500),
                prefixIcon: Icon(Icons.search, color: AppTheme.neutral500),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppTheme.neutral500),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.neutral100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingSm,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacingSm),

          // Select All option
          if (widget.showSelectAll && _searchQuery.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
              child: InkWell(
                onTap: _toggleAll,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spacingSm,
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _allSelected,
                        onChanged: (_) => _toggleAll(),
                        activeColor: themeData.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Text(
                        'Select All (${widget.members.length})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.neutral700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Divider(color: AppTheme.neutral200),
          ],

          // Member list
          Flexible(
            child: _filteredMembers.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingXl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: AppTheme.neutral400,
                          ),
                          const SizedBox(height: AppTheme.spacingSm),
                          Text(
                            'No members found',
                            style: TextStyle(
                              color: AppTheme.neutral600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.only(
                      bottom: bottomPadding + AppTheme.spacingMd,
                    ),
                    itemCount: _filteredMembers.length,
                    itemBuilder: (context, index) {
                      final memberWithFreq = _filteredMembers[index];
                      final member = memberWithFreq.member;
                      final isSelected = _localSelectedIds.contains(member.userId);

                      return _MemberListTile(
                        member: member,
                        frequency: memberWithFreq.frequency,
                        isSelected: isSelected,
                        onTap: () => _toggleMember(member.userId),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Individual member list tile
class _MemberListTile extends StatelessWidget {
  final TripMemberModel member;
  final int frequency;
  final bool isSelected;
  final VoidCallback onTap;

  const _MemberListTile({
    required this.member,
    required this.frequency,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = context.appThemeData;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        child: Row(
          children: [
            // Checkbox
            Checkbox(
              value: isSelected,
              onChanged: (_) => onTap(),
              activeColor: themeData.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            // Avatar
            UserAvatarWidget(
              imageUrl: member.avatarUrl,
              userName: member.fullName,
              size: 40,
            ),
            const SizedBox(width: AppTheme.spacingSm),

            // Name and email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.fullName ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.neutral900,
                    ),
                  ),
                  if (member.email != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      member.email!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.neutral500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Frequency badge (if > 0)
            if (frequency > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSm,
                  vertical: AppTheme.spacing2xs,
                ),
                decoration: BoxDecoration(
                  color: themeData.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 12,
                      color: themeData.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$frequency',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: themeData.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
