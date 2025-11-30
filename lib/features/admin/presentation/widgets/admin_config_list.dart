import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_crew/core/theme/app_theme.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_config.dart';

/// Default app configurations
/// These are stored locally for now but can be synced with database later
final _defaultConfigs = [
  // Trips Configuration
  AdminConfigModel(
    id: '1',
    key: 'max_trip_members',
    value: '50',
    description: 'Maximum number of members allowed per trip',
    category: 'trips',
    valueType: 'number',
  ),
  AdminConfigModel(
    id: '2',
    key: 'max_trips_per_user',
    value: '20',
    description: 'Maximum active trips a user can create',
    category: 'trips',
    valueType: 'number',
  ),
  AdminConfigModel(
    id: '3',
    key: 'allow_trip_deletion',
    value: 'true',
    description: 'Allow users to delete their trips',
    category: 'trips',
    valueType: 'boolean',
  ),
  AdminConfigModel(
    id: '4',
    key: 'trip_invite_expiry_days',
    value: '7',
    description: 'Days until trip invite codes expire',
    category: 'trips',
    valueType: 'number',
  ),

  // Expenses Configuration
  AdminConfigModel(
    id: '5',
    key: 'default_currency',
    value: 'INR',
    description: 'Default currency for new expenses',
    category: 'expenses',
    valueType: 'string',
  ),
  AdminConfigModel(
    id: '6',
    key: 'max_expense_amount',
    value: '1000000',
    description: 'Maximum amount for a single expense',
    category: 'expenses',
    valueType: 'number',
  ),
  AdminConfigModel(
    id: '7',
    key: 'enable_receipt_upload',
    value: 'true',
    description: 'Allow users to upload receipt images',
    category: 'expenses',
    valueType: 'boolean',
  ),
  AdminConfigModel(
    id: '8',
    key: 'max_receipt_size_mb',
    value: '5',
    description: 'Maximum receipt image size in MB',
    category: 'expenses',
    valueType: 'number',
  ),

  // Users Configuration
  AdminConfigModel(
    id: '9',
    key: 'allow_user_registration',
    value: 'true',
    description: 'Allow new user registrations',
    category: 'users',
    valueType: 'boolean',
  ),
  AdminConfigModel(
    id: '10',
    key: 'require_email_verification',
    value: 'true',
    description: 'Require email verification for new users',
    category: 'users',
    valueType: 'boolean',
  ),
  AdminConfigModel(
    id: '11',
    key: 'max_profile_photo_size_mb',
    value: '2',
    description: 'Maximum profile photo size in MB',
    category: 'users',
    valueType: 'number',
  ),
  AdminConfigModel(
    id: '12',
    key: 'session_timeout_minutes',
    value: '1440',
    description: 'Session timeout in minutes (1440 = 24 hours)',
    category: 'users',
    valueType: 'number',
  ),

  // Notifications Configuration
  AdminConfigModel(
    id: '13',
    key: 'enable_push_notifications',
    value: 'true',
    description: 'Enable push notifications',
    category: 'notifications',
    valueType: 'boolean',
  ),
  AdminConfigModel(
    id: '14',
    key: 'enable_email_notifications',
    value: 'true',
    description: 'Enable email notifications',
    category: 'notifications',
    valueType: 'boolean',
  ),
  AdminConfigModel(
    id: '15',
    key: 'expense_reminder_days',
    value: '3',
    description: 'Days before sending expense settlement reminders',
    category: 'notifications',
    valueType: 'number',
  ),

  // Feature Flags
  AdminConfigModel(
    id: '16',
    key: 'enable_chat',
    value: 'true',
    description: 'Enable in-app chat feature',
    category: 'features',
    valueType: 'boolean',
  ),
  AdminConfigModel(
    id: '17',
    key: 'enable_itinerary',
    value: 'true',
    description: 'Enable trip itinerary feature',
    category: 'features',
    valueType: 'boolean',
  ),
  AdminConfigModel(
    id: '18',
    key: 'enable_checklists',
    value: 'true',
    description: 'Enable packing checklists feature',
    category: 'features',
    valueType: 'boolean',
  ),
  AdminConfigModel(
    id: '19',
    key: 'enable_emergency_services',
    value: 'true',
    description: 'Enable emergency services feature',
    category: 'features',
    valueType: 'boolean',
  ),
  AdminConfigModel(
    id: '20',
    key: 'enable_offline_mode',
    value: 'true',
    description: 'Enable offline mode and data sync',
    category: 'features',
    valueType: 'boolean',
  ),

  // Security Configuration
  AdminConfigModel(
    id: '21',
    key: 'min_password_length',
    value: '8',
    description: 'Minimum password length',
    category: 'security',
    valueType: 'number',
  ),
  AdminConfigModel(
    id: '22',
    key: 'require_special_chars',
    value: 'true',
    description: 'Require special characters in password',
    category: 'security',
    valueType: 'boolean',
  ),
  AdminConfigModel(
    id: '23',
    key: 'max_login_attempts',
    value: '5',
    description: 'Max failed login attempts before lockout',
    category: 'security',
    valueType: 'number',
  ),
  AdminConfigModel(
    id: '24',
    key: 'lockout_duration_minutes',
    value: '30',
    description: 'Account lockout duration in minutes',
    category: 'security',
    valueType: 'number',
  ),

  // General Configuration
  AdminConfigModel(
    id: '25',
    key: 'app_name',
    value: 'Travel Crew',
    description: 'Application display name',
    category: 'general',
    valueType: 'string',
  ),
  AdminConfigModel(
    id: '26',
    key: 'support_email',
    value: 'support@travelcrew.app',
    description: 'Support contact email',
    category: 'general',
    valueType: 'string',
  ),
  AdminConfigModel(
    id: '27',
    key: 'maintenance_mode',
    value: 'false',
    description: 'Enable maintenance mode (blocks user access)',
    category: 'general',
    valueType: 'boolean',
  ),
  AdminConfigModel(
    id: '28',
    key: 'debug_mode',
    value: 'false',
    description: 'Enable debug logging',
    category: 'general',
    valueType: 'boolean',
  ),
];

/// Config list notifier for managing state
class ConfigListNotifier extends Notifier<List<AdminConfigModel>> {
  @override
  List<AdminConfigModel> build() => List.from(_defaultConfigs);

  void updateConfig(String configId, String newValue) {
    final index = state.indexWhere((c) => c.id == configId);
    if (index != -1) {
      final updatedConfigs = List<AdminConfigModel>.from(state);
      updatedConfigs[index] = state[index].copyWith(
        value: newValue,
        updatedAt: DateTime.now(),
      );
      state = updatedConfigs;
    }
  }
}

/// Provider for config list (local state for now)
final configListProvider =
    NotifierProvider<ConfigListNotifier, List<AdminConfigModel>>(
  ConfigListNotifier.new,
);

/// Config category notifier
class ConfigCategoryNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setCategory(String? category) {
    state = category;
  }
}

/// Provider for selected category
final selectedConfigCategoryProvider =
    NotifierProvider<ConfigCategoryNotifier, String?>(
  ConfigCategoryNotifier.new,
);

/// Config search notifier
class ConfigSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setSearch(String query) {
    state = query;
  }
}

/// Provider for config search query
final configSearchQueryProvider =
    NotifierProvider<ConfigSearchNotifier, String>(
  ConfigSearchNotifier.new,
);

/// Filtered configs provider
final filteredConfigsProvider = Provider<List<AdminConfigModel>>((ref) {
  final configs = ref.watch(configListProvider);
  final category = ref.watch(selectedConfigCategoryProvider);
  final searchQuery = ref.watch(configSearchQueryProvider).toLowerCase();

  return configs.where((config) {
    // Category filter
    if (category != null && config.category != category) {
      return false;
    }

    // Search filter
    if (searchQuery.isNotEmpty) {
      return config.key.toLowerCase().contains(searchQuery) ||
          config.displayName.toLowerCase().contains(searchQuery) ||
          (config.description?.toLowerCase().contains(searchQuery) ?? false);
    }

    return true;
  }).toList();
});

/// Admin Config Management List Widget
class AdminConfigList extends ConsumerStatefulWidget {
  const AdminConfigList({super.key});

  @override
  ConsumerState<AdminConfigList> createState() => _AdminConfigListState();
}

class _AdminConfigListState extends ConsumerState<AdminConfigList> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredConfigs = ref.watch(filteredConfigsProvider);
    final selectedCategory = ref.watch(selectedConfigCategoryProvider);

    return Column(
      children: [
        // Search and Filter Header
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          color: Colors.white,
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search configurations...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(configSearchQueryProvider.notifier).setSearch('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: BorderSide(color: AppTheme.neutral300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: BorderSide(color: AppTheme.neutral300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                    vertical: AppTheme.spacingSm,
                  ),
                ),
                onChanged: (value) {
                  ref.read(configSearchQueryProvider.notifier).setSearch(value);
                },
              ),
              const SizedBox(height: AppTheme.spacingMd),

              // Category Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip(
                      context,
                      label: 'All',
                      isSelected: selectedCategory == null,
                      onSelected: () {
                        ref.read(selectedConfigCategoryProvider.notifier).setCategory(null);
                      },
                    ),
                    ...ConfigCategory.values.map((category) {
                      return _buildCategoryChip(
                        context,
                        label: category.displayName,
                        isSelected: selectedCategory == category.value,
                        onSelected: () {
                          ref.read(selectedConfigCategoryProvider.notifier)
                              .setCategory(category.value);
                        },
                        icon: _getCategoryIcon(category),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Config List
        Expanded(
          child: filteredConfigs.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  itemCount: filteredConfigs.length,
                  itemBuilder: (context, index) {
                    final config = filteredConfigs[index];
                    return _buildConfigCard(context, config);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: AppTheme.spacingSm),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppTheme.neutral600,
              ),
              const SizedBox(width: 4),
            ],
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => onSelected(),
        selectedColor: Theme.of(context).colorScheme.primary,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.neutral700,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : AppTheme.neutral300,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(ConfigCategory category) {
    switch (category) {
      case ConfigCategory.general:
        return Icons.settings;
      case ConfigCategory.trips:
        return Icons.flight_takeoff;
      case ConfigCategory.expenses:
        return Icons.receipt_long;
      case ConfigCategory.users:
        return Icons.people;
      case ConfigCategory.notifications:
        return Icons.notifications;
      case ConfigCategory.security:
        return Icons.security;
      case ConfigCategory.features:
        return Icons.toggle_on;
    }
  }

  Widget _buildConfigCard(BuildContext context, AdminConfigModel config) {
    final categoryColor = _getCategoryColor(config.category);

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: InkWell(
        onTap: config.isEditable ? () => _showEditDialog(context, config) : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            children: [
              // Category Icon
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSm),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  _getCategoryIcon(ConfigCategory.fromString(config.category)),
                  color: categoryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),

              // Config Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (config.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        config.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.neutral600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Value Widget
              _buildValueWidget(context, config),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValueWidget(BuildContext context, AdminConfigModel config) {
    switch (config.valueType) {
      case 'boolean':
        return Switch(
          value: config.boolValue,
          onChanged: config.isEditable
              ? (value) => _updateConfigValue(config, value.toString())
              : null,
          activeTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Theme.of(context).colorScheme.primary;
            }
            return null;
          }),
        );

      case 'number':
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingXs,
          ),
          decoration: BoxDecoration(
            color: AppTheme.neutral100,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Text(
            config.value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        );

      default:
        return Container(
          constraints: const BoxConstraints(maxWidth: 120),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingSm,
            vertical: AppTheme.spacingXs,
          ),
          decoration: BoxDecoration(
            color: AppTheme.neutral100,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Text(
            config.value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'trips':
        return Colors.blue;
      case 'expenses':
        return Colors.green;
      case 'users':
        return Colors.orange;
      case 'notifications':
        return Colors.purple;
      case 'security':
        return Colors.red;
      case 'features':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  void _updateConfigValue(AdminConfigModel config, String newValue) {
    ref.read(configListProvider.notifier).updateConfig(config.id, newValue);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${config.displayName} updated'),
        backgroundColor: AppTheme.success,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showEditDialog(BuildContext context, AdminConfigModel config) {
    final controller = TextEditingController(text: config.value);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              decoration: BoxDecoration(
                color: _getCategoryColor(config.category).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(
                Icons.edit,
                color: _getCategoryColor(config.category),
                size: 20,
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Text(
                'Edit ${config.displayName}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (config.description != null) ...[
              Text(
                config.description!,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.neutral600,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
            ],
            TextField(
              controller: controller,
              keyboardType: config.valueType == 'number'
                  ? TextInputType.number
                  : TextInputType.text,
              decoration: InputDecoration(
                labelText: 'Value',
                hintText: config.valueType == 'number'
                    ? 'Enter a number'
                    : 'Enter value',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newValue = controller.text.trim();
              if (newValue.isNotEmpty) {
                _updateConfigValue(config, newValue);
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            decoration: BoxDecoration(
              color: AppTheme.neutral100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.settings_outlined,
              size: 48,
              color: AppTheme.neutral400,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'No configurations found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.neutral700,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.neutral500,
            ),
          ),
        ],
      ),
    );
  }
}
