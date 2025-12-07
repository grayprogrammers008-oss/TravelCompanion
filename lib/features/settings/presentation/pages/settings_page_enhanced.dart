import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart' as theme_provider;
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/easy_mode_provider.dart';
import '../../../../core/widgets/destination_image.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Enhanced Settings Page with working toggles and preferences
class SettingsPageEnhanced extends ConsumerStatefulWidget {
  const SettingsPageEnhanced({super.key});

  @override
  ConsumerState<SettingsPageEnhanced> createState() => _SettingsPageEnhancedState();
}

class _SettingsPageEnhancedState extends ConsumerState<SettingsPageEnhanced> {
  static const String _appVersion = '1.0.0 (1)';

  // Notification preferences
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _tripInvites = true;
  bool _expenseUpdates = true;
  bool _itineraryChanges = true;

  // App preferences
  String _language = 'English';
  String _currency = 'USD';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _emailNotifications = prefs.getBool('email_notifications') ?? true;
      _tripInvites = prefs.getBool('trip_invites') ?? true;
      _expenseUpdates = prefs.getBool('expense_updates') ?? true;
      _itineraryChanges = prefs.getBool('itinerary_changes') ?? true;
      _language = prefs.getString('language') ?? 'English';
      _currency = prefs.getString('currency') ?? 'USD';
    });
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current user from Supabase (online-only mode)
    final userAsync = ref.watch(currentUserProvider);
    final themeData = ref.watch(theme_provider.currentThemeDataProvider);

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        title: const Text('Settings'),
        foregroundColor: AppTheme.neutral900,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Section
            Container(
              margin: const EdgeInsets.all(AppTheme.spacingLg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: userAsync.when(
                data: (user) => InkWell(
                  onTap: () => context.push('/profile'),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingLg),
                    child: Row(
                      children: [
                        UserAvatarWidget(
                          imageUrl: user?.avatarUrl,
                          userName: user?.fullName ?? user?.email,
                          size: 60,
                          showBorder: true,
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.email != null
                                    ? user!.email.split('@')[0]
                                    : 'User',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.neutral900,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? '',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.neutral600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppTheme.neutral400),
                      ],
                    ),
                  ),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppTheme.spacingXl),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => const Padding(
                  padding: EdgeInsets.all(AppTheme.spacingXl),
                  child: Center(child: Text('Error loading profile')),
                ),
              ),
            ),

            // Notification Settings
            _buildSection(
              context,
              title: 'Notification Preferences',
              items: [
                _buildSwitchTile(
                  context,
                  icon: Icons.notifications_active,
                  iconColor: Colors.orange,
                  title: 'Push Notifications',
                  subtitle: 'Receive notifications on this device',
                  value: _pushNotifications,
                  onChanged: (value) {
                    setState(() => _pushNotifications = value);
                    _savePreference('push_notifications', value);
                  },
                ),
                _buildSwitchTile(
                  context,
                  icon: Icons.email,
                  iconColor: Colors.orange,
                  title: 'Email Notifications',
                  subtitle: 'Receive updates via email',
                  value: _emailNotifications,
                  onChanged: (value) {
                    setState(() => _emailNotifications = value);
                    _savePreference('email_notifications', value);
                  },
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingLg,
                    AppTheme.spacingMd,
                    AppTheme.spacingLg,
                    AppTheme.spacingXs,
                  ),
                  child: Text(
                    'Notify me about:',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.neutral600,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                _buildSwitchTile(
                  context,
                  icon: Icons.group_add,
                  iconColor: Colors.orange,
                  title: 'Trip Invites',
                  value: _tripInvites,
                  onChanged: (value) {
                    setState(() => _tripInvites = value);
                    _savePreference('trip_invites', value);
                  },
                ),
                _buildSwitchTile(
                  context,
                  icon: Icons.attach_money,
                  iconColor: Colors.orange,
                  title: 'Expense Updates',
                  value: _expenseUpdates,
                  onChanged: (value) {
                    setState(() => _expenseUpdates = value);
                    _savePreference('expense_updates', value);
                  },
                ),
                _buildSwitchTile(
                  context,
                  icon: Icons.event,
                  iconColor: Colors.orange,
                  title: 'Itinerary Changes',
                  value: _itineraryChanges,
                  onChanged: (value) {
                    setState(() => _itineraryChanges = value);
                    _savePreference('itinerary_changes', value);
                  },
                ),
              ],
            ),

            // Appearance Settings
            _buildSection(
              context,
              title: 'Appearance',
              items: [
                _buildNavigationTile(
                  context,
                  icon: Icons.color_lens,
                  iconColor: Colors.purple,
                  title: 'Color Scheme',
                  subtitle: themeData.name,
                  onTap: () => context.push('/settings/theme'),
                ),
              ],
            ),

            // App Preferences
            _buildSection(
              context,
              title: 'Preferences',
              items: [
                _buildNavigationTile(
                  context,
                  icon: Icons.language,
                  iconColor: Colors.blue,
                  title: 'Language',
                  subtitle: _language,
                  onTap: () => _showLanguageDialog(context),
                ),
                _buildNavigationTile(
                  context,
                  icon: Icons.attach_money,
                  iconColor: Colors.blue,
                  title: 'Currency',
                  subtitle: _currency,
                  onTap: () => _showCurrencyDialog(context),
                ),
              ],
            ),

            // Accessibility Section
            _buildSection(
              context,
              title: 'Accessibility',
              items: [
                _buildEasyModeToggle(context, ref),
              ],
            ),

            // Account Settings
            _buildSection(
              context,
              title: 'Account',
              items: [
                _buildNavigationTile(
                  context,
                  icon: Icons.lock,
                  iconColor: Colors.green,
                  title: 'Change Password',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Change Password - Coming Soon')),
                    );
                  },
                ),
                _buildNavigationTile(
                  context,
                  icon: Icons.security,
                  iconColor: Colors.green,
                  title: 'Privacy & Security',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Privacy & Security - Coming Soon')),
                    );
                  },
                ),
              ],
            ),

            // About Section
            _buildSection(
              context,
              title: 'About',
              items: [
                _buildNavigationTile(
                  context,
                  icon: Icons.info,
                  iconColor: Colors.grey,
                  title: 'App Version',
                  subtitle: _appVersion,
                ),
                _buildNavigationTile(
                  context,
                  icon: Icons.description,
                  iconColor: Colors.grey,
                  title: 'Open Source Licenses',
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationName: 'Travel Crew',
                      applicationVersion: _appVersion,
                    );
                  },
                ),
                _buildNavigationTile(
                  context,
                  icon: Icons.privacy_tip,
                  iconColor: Colors.grey,
                  title: 'Privacy Policy',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Privacy Policy - Coming Soon')),
                    );
                  },
                ),
                _buildNavigationTile(
                  context,
                  icon: Icons.gavel,
                  iconColor: Colors.grey,
                  title: 'Terms of Service',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Terms of Service - Coming Soon')),
                    );
                  },
                ),
              ],
            ),

            // Danger Zone
            _buildSection(
              context,
              title: 'Danger Zone',
              items: [
                _buildNavigationTile(
                  context,
                  icon: Icons.delete_forever,
                  iconColor: AppTheme.error,
                  title: 'Delete Account',
                  titleColor: AppTheme.error,
                  onTap: () => _showDeleteAccountDialog(context),
                ),
              ],
            ),

            // Logout Button
            Container(
              margin: const EdgeInsets.all(AppTheme.spacingLg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(Icons.logout, color: context.errorColor),
                ),
                title: Text(
                  'Logout',
                  style: TextStyle(
                    color: context.errorColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Icon(Icons.chevron_right, color: context.errorColor),
                onTap: () => _showLogoutDialog(context),
              ),
            ),

            const SizedBox(height: AppTheme.spacingXl),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingLg,
            AppTheme.spacingLg,
            AppTheme.spacingLg,
            AppTheme.spacingMd,
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.neutral600,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: AppTheme.neutral900,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                color: AppTheme.neutral600,
                fontSize: 13,
              ),
            )
          : null,
      value: value,
      activeTrackColor: context.primaryColor.withValues(alpha: 0.5),
      thumbColor: WidgetStateProperty.resolveWith<Color>((states) => context.primaryColor),
      onChanged: onChanged,
    );
  }

  Widget _buildEasyModeToggle(BuildContext context, WidgetRef ref) {
    final isEasyMode = ref.watch(easyModeEnabledProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: isEasyMode ? Colors.orange.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: isEasyMode
            ? Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 2)
            : null,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: const Icon(Icons.accessibility_new, color: Colors.orange),
        ),
        title: Row(
          children: [
            const Text(
              'Easy Mode',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            if (isEasyMode) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'ON',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          isEasyMode
              ? 'Larger text & buttons for easier use'
              : 'Tap to enable larger text & buttons',
          style: TextStyle(
            color: isEasyMode ? Colors.orange.shade700 : AppTheme.neutral600,
            fontSize: 13,
          ),
        ),
        trailing: Switch(
          value: isEasyMode,
          activeThumbColor: Colors.orange,
          activeTrackColor: Colors.orange.withValues(alpha: 0.5),
          onChanged: (value) {
            HapticFeedback.mediumImpact();
            ref.read(easyModeEnabledProvider.notifier).setEnabled(value);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(
                      value ? Icons.accessibility_new : Icons.accessibility,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Text(value
                        ? 'Easy Mode enabled - Larger text & buttons'
                        : 'Easy Mode disabled'),
                  ],
                ),
                backgroundColor: value ? Colors.orange : AppTheme.neutral700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
            );
          },
        ),
        onTap: () {
          HapticFeedback.mediumImpact();
          ref.read(easyModeEnabledProvider.notifier).toggle();
        },
      ),
    );
  }

  Widget _buildNavigationTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: titleColor ?? AppTheme.neutral900,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                color: AppTheme.neutral600,
                fontSize: 13,
              ),
            )
          : null,
      trailing: onTap != null ? const Icon(Icons.chevron_right, color: AppTheme.neutral400) : null,
      onTap: onTap,
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final languages = ['English', 'Spanish', 'French', 'German', 'Chinese', 'Japanese'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: languages.map((lang) {
              final isSelected = lang == _language;
              return ListTile(
                title: Text(lang),
                trailing: isSelected ? Icon(Icons.check, color: context.primaryColor) : null,
                onTap: () {
                  setState(() => _language = lang);
                  _savePreference('language', lang);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Language set to $lang (i18n coming soon)')),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context) {
    final currencies = [
      {'code': 'USD', 'name': 'US Dollar'},
      {'code': 'EUR', 'name': 'Euro'},
      {'code': 'GBP', 'name': 'British Pound'},
      {'code': 'JPY', 'name': 'Japanese Yen'},
      {'code': 'INR', 'name': 'Indian Rupee'},
      {'code': 'AUD', 'name': 'Australian Dollar'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: currencies.map((currency) {
              final code = currency['code']!;
              final name = currency['name']!;
              final isSelected = code == _currency;
              return ListTile(
                title: Text('$code - $name'),
                trailing: isSelected ? Icon(Icons.check, color: context.primaryColor) : null,
                onTap: () {
                  setState(() => _currency = code);
                  _savePreference('currency', code);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Delete Account - Coming Soon'),
                  backgroundColor: AppTheme.error,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Sign out using auth controller
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error logging out: ${e.toString()}'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
