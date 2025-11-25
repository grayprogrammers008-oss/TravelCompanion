import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_access.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/data/datasources/profile_photo_service.dart';
import '../../../trips/presentation/providers/trip_providers.dart';

/// Profile Page - View and edit user profile
class ProfilePage extends ConsumerStatefulWidget {
  final String? userId; // If null, shows current user's profile
  final String? fullName; // For viewing other user's profile
  final String? email; // For viewing other user's profile
  final String? role; // For viewing other user's profile

  const ProfilePage({
    super.key,
    this.userId,
    this.fullName,
    this.email,
    this.role,
  });

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isUploadingPhoto = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Update profile via auth repository
      final repository = ref.read(authRepositoryProvider);
      await repository.updateProfile(
        fullName: _fullNameController.text.trim().isEmpty ? null : _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
      );

      // Refresh user data
      ref.invalidate(currentUserProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _uploadProfilePhoto(ImageSource source) async {
    setState(() => _isUploadingPhoto = true);

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        setState(() => _isUploadingPhoto = false);
        return;
      }

      // Upload photo using ProfilePhotoService
      final photoService = ProfilePhotoService();
      final user = ref.read(currentUserProvider).value;
      if (user == null) throw Exception('User not found');

      final avatarUrl = await photoService.uploadProfilePhoto(
        userId: user.id,
        imageFile: pickedFile,
      );

      // Update profile with new avatar URL
      final repository = ref.read(authRepositoryProvider);
      await repository.updateProfile(avatarUrl: avatarUrl);

      // Refresh user data and trips to update avatar everywhere
      ref.invalidate(currentUserProvider);
      ref.invalidate(userTripsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photo: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  void _showPhotoSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_camera, color: context.primaryColor),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _uploadProfilePhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: context.primaryColor),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _uploadProfilePhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.cancel, color: context.textColor.withValues(alpha: 0.7)),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Current Password
                TextFormField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrentPassword,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrentPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setDialogState(() {
                        obscureCurrentPassword = !obscureCurrentPassword;
                      }),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your current password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingMd),

                // New Password
                TextFormField(
                  controller: newPasswordController,
                  obscureText: obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setDialogState(() {
                        obscureNewPassword = !obscureNewPassword;
                      }),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a new password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    if (value == currentPasswordController.text) {
                      return 'New password must be different';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingMd),

                // Confirm Password
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setDialogState(() {
                        obscureConfirmPassword = !obscureConfirmPassword;
                      }),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your new password';
                    }
                    if (value != newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      setDialogState(() => isLoading = true);

                      try {
                        final useCase = ref.read(changePasswordUseCaseProvider);
                        await useCase(
                          currentPassword: currentPasswordController.text,
                          newPassword: newPasswordController.text,
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password changed successfully'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString().replaceAll('Exception: ', '')),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
                      } finally {
                        if (context.mounted) {
                          setDialogState(() => isLoading = false);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final themeData = context.appThemeData;
    final currentUserId = userAsync.value?.id;
    final isViewingOwnProfile = widget.userId == null || widget.userId == currentUserId;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(
          isViewingOwnProfile ? 'Profile' : 'User Profile',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: themeData.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: themeData.primaryGradient,
          ),
        ),
        actions: [
          if (isViewingOwnProfile && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (isViewingOwnProfile && _isEditing && !_isLoading)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => setState(() => _isEditing = false),
            ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null && isViewingOwnProfile) {
            return const Center(
              child: Text('User not found'),
            );
          }

          // If viewing another user's profile, use the passed data
          if (!isViewingOwnProfile) {
            return _buildOtherUserProfile(context, themeData);
          }

          // Initialize controllers with current user data
          if (_fullNameController.text.isEmpty && user!.fullName != null) {
            _fullNameController.text = user.fullName!;
          }
          if (_phoneController.text.isEmpty && user!.phoneNumber != null) {
            _phoneController.text = user.phoneNumber!;
          }
          if (_bioController.text.isEmpty && user!.bio != null) {
            _bioController.text = user.bio!;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Profile Picture Section
                  Stack(
                    children: [
                      // Loading overlay
                      if (_isUploadingPhoto)
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: context.primaryColor.withValues(alpha: 0.1),
                        child: user!.avatarUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  user.avatarUrl!,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildAvatarInitial(user.email);
                                  },
                                ),
                              )
                            : _buildAvatarInitial(user.email),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isUploadingPhoto ? null : _showPhotoSourceDialog,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: context.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingXl),

                  // Profile Information Card
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingLg),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personal Information',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: context.textColor,
                              ),
                        ),
                        const SizedBox(height: AppTheme.spacingLg),

                        // Full Name Field
                        TextFormField(
                          controller: _fullNameController,
                          enabled: _isEditing,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your full name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.spacingMd),

                        // Email Field (Read-only)
                        TextFormField(
                          initialValue: user.email,
                          enabled: false,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                            helperText: 'Email cannot be changed',
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),

                        // Phone Number Field
                        TextFormField(
                          controller: _phoneController,
                          enabled: _isEditing,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: const Icon(Icons.phone),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                            hintText: 'Optional',
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),

                        // Bio Field
                        TextFormField(
                          controller: _bioController,
                          enabled: _isEditing,
                          maxLines: 3,
                          maxLength: 500,
                          decoration: InputDecoration(
                            labelText: 'Bio',
                            prefixIcon: const Icon(Icons.info_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                            hintText: 'Tell us about yourself (Optional)',
                            helperText: 'Maximum 500 characters',
                          ),
                          validator: (value) {
                            if (value != null && value.length > 500) {
                              return 'Bio must be 500 characters or less';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.spacingMd),

                        // Account Created Date
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.calendar_today, color: context.textColor.withValues(alpha: 0.7)),
                          title: const Text('Account Created'),
                          subtitle: Text(
                            _formatDate(user.createdAt),
                            style: TextStyle(color: context.textColor.withValues(alpha: 0.7)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),

                  // Trip Statistics Card
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingLg),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Travel Stats',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: context.textColor,
                              ),
                        ),
                        const SizedBox(height: AppTheme.spacingLg),
                        Consumer(
                          builder: (context, ref, _) {
                            final statsAsync = ref.watch(userStatsProvider);

                            return statsAsync.when(
                              data: (stats) => Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatCard(
                                          context: context,
                                          icon: Icons.luggage,
                                          label: 'Trips',
                                          value: '${stats.totalTrips}',
                                          color: context.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: AppTheme.spacingMd),
                                      Expanded(
                                        child: _buildStatCard(
                                          context: context,
                                          icon: Icons.receipt_long,
                                          label: 'Expenses',
                                          value: '${stats.totalExpenses}',
                                          color: context.accentColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppTheme.spacingMd),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatCard(
                                          context: context,
                                          icon: Icons.attach_money,
                                          label: 'Total Spent',
                                          value: '₹${stats.totalSpent.toStringAsFixed(0)}',
                                          color: context.accentColor,
                                        ),
                                      ),
                                      const SizedBox(width: AppTheme.spacingMd),
                                      Expanded(
                                        child: _buildStatCard(
                                          context: context,
                                          icon: Icons.people,
                                          label: 'Crew Members',
                                          value: '${stats.uniqueCrewMembers}',
                                          color: context.accentColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              loading: () => const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(AppTheme.spacingLg),
                                  child: AppLoadingIndicator(message: 'Loading stats...', size: 60),
                                ),
                              ),
                              error: (error, stack) => Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatCard(
                                          context: context,
                                          icon: Icons.luggage,
                                          label: 'Trips',
                                          value: '0',
                                          color: context.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: AppTheme.spacingMd),
                                      Expanded(
                                        child: _buildStatCard(
                                          context: context,
                                          icon: Icons.receipt_long,
                                          label: 'Expenses',
                                          value: '0',
                                          color: context.accentColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppTheme.spacingMd),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatCard(
                                          context: context,
                                          icon: Icons.attach_money,
                                          label: 'Total Spent',
                                          value: '₹0',
                                          color: context.accentColor,
                                        ),
                                      ),
                                      const SizedBox(width: AppTheme.spacingMd),
                                      Expanded(
                                        child: _buildStatCard(
                                          context: context,
                                          icon: Icons.people,
                                          label: 'Crew Members',
                                          value: '0',
                                          color: context.accentColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),

                  // Save Button (only visible when editing)
                  if (_isEditing)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Save Changes'),
                      ),
                    ),

                  const SizedBox(height: AppTheme.spacingLg),

                  // Additional Actions Card
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingLg),
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
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: context.accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            ),
                            child: Icon(Icons.lock, color: context.accentColor),
                          ),
                          title: const Text('Change Password'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _showChangePasswordDialog,
                        ),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            ),
                            child: const Icon(Icons.delete_forever, color: AppTheme.error),
                          ),
                          title: const Text(
                            'Delete Account',
                            style: TextStyle(color: AppTheme.error),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: AppTheme.error),
                          onTap: () => _showDeleteAccountDialog(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: AppLoadingIndicator(message: 'Loading profile...')),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: AppTheme.error, size: 48),
              const SizedBox(height: AppTheme.spacingMd),
              Text('Error loading profile: ${error.toString()}'),
              const SizedBox(height: AppTheme.spacingMd),
              ElevatedButton(
                onPressed: () => ref.invalidate(currentUserProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarInitial(String? email) {
    return Text(
      email != null && email.isNotEmpty ? email[0].toUpperCase() : '?',
      style: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w600,
        color: context.primaryColor,
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: AppTheme.spacing2xs),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: context.textColor.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOtherUserProfile(BuildContext context, dynamic themeData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        children: [
          // Profile Picture Section
          CircleAvatar(
            radius: 60,
            backgroundColor: context.primaryColor.withValues(alpha: 0.1),
            child: Text(
              (widget.fullName?.isNotEmpty == true ? widget.fullName![0] :
               widget.email?.isNotEmpty == true ? widget.email![0] : 'U').toUpperCase(),
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: context.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // User Info Card
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
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
            child: Column(
              children: [
                // Name
                if (widget.fullName?.isNotEmpty == true) ...[
                  _buildInfoRow(
                    context: context,
                    icon: Icons.person,
                    label: 'Name',
                    value: widget.fullName!,
                    themeData: themeData,
                  ),
                  const Divider(height: AppTheme.spacingLg),
                ],

                // Email
                if (widget.email?.isNotEmpty == true) ...[
                  _buildInfoRow(
                    context: context,
                    icon: Icons.email,
                    label: 'Email',
                    value: widget.email!,
                    themeData: themeData,
                  ),
                  const Divider(height: AppTheme.spacingLg),
                ],

                // Role
                if (widget.role?.isNotEmpty == true)
                  _buildInfoRow(
                    context: context,
                    icon: Icons.badge,
                    label: 'Role',
                    value: widget.role!.substring(0, 1).toUpperCase() + widget.role!.substring(1),
                    themeData: themeData,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required dynamic themeData,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingSm),
          decoration: BoxDecoration(
            color: context.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(icon, size: 20, color: context.primaryColor),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.textColor.withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.textColor,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
