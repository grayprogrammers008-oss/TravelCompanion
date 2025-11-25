# Profile Photo Upload Implementation

**Status:** ✅ Complete and Ready for Testing
**Date:** February 1, 2025
**Feature:** Upload and display user profile photos using Supabase Storage

---

## 📋 Overview

This feature allows users to upload profile photos which are stored in Supabase Storage and displayed throughout the app (profile page, settings, trip members list, etc.).

### Key Features
- ✅ Pick images from gallery or camera
- ✅ Automatic image optimization (max 1024x1024, 85% quality)
- ✅ Upload to Supabase Storage with proper RLS policies
- ✅ Update user profile with photo URL
- ✅ Display in all avatar widgets
- ✅ Delete old photos when uploading new ones
- ✅ FREE tier compatible (uses Supabase Free tier)

---

## 🏗️ Architecture

### Components Implemented

#### 1. **ProfilePhotoService** ([profile_photo_service.dart](../lib/features/auth/data/datasources/profile_photo_service.dart))
Handles all photo operations:
- `pickImageFromGallery()` - Select photo from gallery
- `pickImageFromCamera()` - Take photo with camera
- `uploadProfilePhoto()` - Upload to Supabase Storage
- `deleteProfilePhoto()` - Remove old photos

#### 2. **AuthRepository** ([auth_repository_impl.dart](../lib/features/auth/data/repositories/auth_repository_impl.dart))
Already supports `updateProfile(avatarUrl: string)` to update user profile with photo URL.

#### 3. **UserAvatarWidget** ([destination_image.dart:272-363](../lib/core/widgets/destination_image.dart#L272-L363))
Displays user avatars throughout the app:
- Shows uploaded photo if available
- Falls back to gradient with initials
- Supports custom sizes and borders
- Uses CachedNetworkImage for performance

#### 4. **Profile Page** ([profile_page.dart:90-146](../lib/features/settings/presentation/pages/profile_page.dart#L90-L146))
Complete UI for photo upload:
- Photo upload button
- Modal bottom sheet for camera/gallery selection
- Loading states
- Error handling

---

## 🗄️ Database Setup

### Supabase Storage Buckets

**Migration File:** `supabase/migrations/20250201_storage_buckets_setup.sql`

#### Buckets Created:
1. **profile-avatars** (Public)
   - Size limit: 5MB
   - Allowed types: JPEG, PNG, WebP
   - Public read access
   - Users can only upload/update/delete their own photos

2. **trip-covers** (Public)
   - Size limit: 10MB
   - Trip members can upload

3. **expense-receipts** (Private)
   - Size limit: 10MB
   - Only trip members can view

4. **settlement-proofs** (Private)
   - Size limit: 10MB
   - Only involved users can access

### Row Level Security (RLS) Policies

**Profile Avatars Bucket:**
```sql
-- Users can upload their own avatars
CREATE POLICY "Users can upload their own profile avatars"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'profile-avatars'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Users can update their own avatars
CREATE POLICY "Users can update their own profile avatars"
ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'profile-avatars'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Users can delete their own avatars
CREATE POLICY "Users can delete their own profile avatars"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'profile-avatars'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Public can view all avatars
CREATE POLICY "Public can view profile avatars"
ON storage.objects FOR SELECT TO public
USING (bucket_id = 'profile-avatars');
```

---

## 🚀 How to Apply the Migration

### Option 1: Supabase Dashboard (Recommended)
1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Create new query
4. Copy contents from `supabase/migrations/20250201_storage_buckets_setup.sql`
5. Click **Run**
6. Verify in **Storage** section that buckets were created

### Option 2: Supabase CLI
```bash
# From project root
supabase db push

# Or apply specific migration
supabase migration up --include-all
```

### Verify Installation
After migration, check:
1. **Storage → Buckets** - Should see 4 buckets
2. **Storage → Policies** - Each bucket should have RLS policies
3. Try uploading a test file to `profile-avatars` bucket

---

## 📱 User Flow

### Upload Profile Photo

1. **Navigate to Profile**
   - Go to Settings → Tap profile card at top

2. **Initiate Upload**
   - Tap camera icon on avatar
   - Modal sheet appears with options:
     - 📷 Take Photo
     - 🖼️ Choose from Gallery
     - ❌ Cancel

3. **Select Photo**
   - Choose source (camera/gallery)
   - Select/capture image
   - Image is auto-resized to 1024x1024, 85% quality

4. **Upload Process**
   - Loading indicator appears
   - Photo uploads to Supabase Storage
   - Profile updates with new URL
   - Success message shown

5. **Photo Appears Everywhere**
   - Profile page
   - Settings page
   - Trip members list
   - Anywhere `UserAvatarWidget` is used

---

## 🔍 File Structure

```
lib/features/auth/data/datasources/
└── profile_photo_service.dart          # Photo operations service

lib/features/settings/presentation/pages/
└── profile_page.dart                   # UI with upload functionality

lib/core/widgets/
└── destination_image.dart              # UserAvatarWidget component

supabase/migrations/
└── 20250201_storage_buckets_setup.sql  # Database migration

test/features/auth/data/datasources/
└── profile_photo_service_test.dart     # Unit tests

test/features/auth/integration/
└── profile_photo_upload_integration_test.dart  # Integration tests
```

---

## ⚙️ Configuration

### Constants ([app_constants.dart:69-73](../lib/core/constants/app_constants.dart#L69-L73))
```dart
static const String profileAvatarsBucket = 'profile-avatars';
static const String tripCoversBucket = 'trip-covers';
static const String expenseReceiptsBucket = 'expense-receipts';
static const String settlementProofsBucket = 'settlement-proofs';
```

### Image Optimization Settings
```dart
// In ProfilePhotoService
maxWidth: 1024px
maxHeight: 1024px
imageQuality: 85%
```

---

## 🧪 Testing

### Manual Testing Checklist

See [PROFILE_PHOTO_TESTING.md](./PROFILE_PHOTO_TESTING.md) for complete testing guide.

**Quick Test:**
1. ✅ Upload photo from gallery
2. ✅ Upload photo from camera
3. ✅ Replace existing photo
4. ✅ Photo appears in settings
5. ✅ Photo appears in trip members
6. ✅ Photo persists after logout/login

### Automated Tests

**Unit Tests:** `test/features/auth/data/datasources/profile_photo_service_test.dart`
- Image picker operations
- Upload flow
- Delete operations
- Error handling
- Edge cases

**Integration Tests:** `test/features/auth/integration/profile_photo_upload_integration_test.dart`
- End-to-end upload flow
- Profile update integration
- Photo replacement
- Error recovery

```bash
# Run tests
flutter test test/features/auth/data/datasources/profile_photo_service_test.dart
flutter test test/features/auth/integration/profile_photo_upload_integration_test.dart
```

---

## 🔒 Security

### RLS Policies
- ✅ Users can only upload to their own folder (`userId/`)
- ✅ Users can only modify/delete their own photos
- ✅ Public read access for displaying avatars
- ✅ File type restrictions (JPEG, PNG, WebP only)
- ✅ File size limits (5MB for avatars)

### Best Practices Implemented
- ✅ Image validation before upload
- ✅ Automatic image optimization
- ✅ Proper error handling
- ✅ Old photo cleanup
- ✅ Secure URL generation

---

## 💰 Cost Analysis (Supabase Free Tier)

### Storage Limits
- **Total Storage:** 1 GB (free tier)
- **Bandwidth:** 2 GB/month (free tier)
- **Avatar Size:** ~200 KB (optimized)
- **Capacity:** ~5,000 profile photos

### Bandwidth Usage
- **Upload:** 200 KB per user
- **Download:** ~200 KB per view
- **Monthly estimate:** 2 GB = ~10,000 avatar views

**Conclusion:** Free tier is more than sufficient for personal/small team use!

---

## 🐛 Troubleshooting

### Issue: "Failed to upload photo"
**Possible Causes:**
1. Supabase not initialized
2. Migration not applied
3. Network connectivity
4. File size exceeds limit

**Solution:**
- Check Supabase connection
- Verify migration was applied
- Check file size < 5MB
- Review browser console for errors

### Issue: "Avatar not showing"
**Possible Causes:**
1. Image URL not saved to profile
2. RLS policy blocking read access
3. Cache issues

**Solution:**
- Check `profiles.avatar_url` in database
- Verify public read policy exists
- Clear app cache and reload

### Issue: "Permission denied"
**Possible Causes:**
1. User not authenticated
2. RLS policies not applied
3. Bucket doesn't exist

**Solution:**
- Ensure user is logged in
- Reapply migration
- Check bucket exists in Storage dashboard

---

## 📚 API Reference

### ProfilePhotoService

```dart
class ProfilePhotoService {
  /// Pick image from gallery
  /// Returns XFile or null if cancelled
  Future<XFile?> pickImageFromGallery()

  /// Pick image from camera
  /// Returns XFile or null if cancelled
  Future<XFile?> pickImageFromCamera()

  /// Upload profile photo to Supabase Storage
  /// Returns public URL of uploaded photo
  Future<String> uploadProfilePhoto({
    required String userId,
    required XFile imageFile,
  })

  /// Delete profile photo from storage
  /// Does not throw on failure
  Future<void> deleteProfilePhoto(String avatarUrl)
}
```

### AuthRepository

```dart
/// Update user profile with new avatar URL
Future<UserEntity> updateProfile({
  String? fullName,
  String? phoneNumber,
  String? avatarUrl,  // ← Photo URL goes here
  String? bio,
})
```

---

## ✅ Implementation Checklist

- [x] ProfilePhotoService implemented
- [x] Image picker integration
- [x] Supabase Storage upload
- [x] Profile update with avatar URL
- [x] UserAvatarWidget displays photos
- [x] Profile page UI complete
- [x] Database migration created
- [x] RLS policies configured
- [x] Unit tests written
- [x] Integration tests written
- [x] Documentation complete
- [ ] Migration applied to database ⚠️
- [ ] Manual testing completed ⚠️
- [ ] Production deployment ⚠️

---

## 🎯 Next Steps

1. **Apply Migration** (REQUIRED)
   - Run migration on Supabase dashboard
   - Verify buckets created

2. **Manual Testing**
   - Follow testing checklist
   - Test on iOS and Android
   - Verify photos persist

3. **Production Deployment**
   - Ensure migration applied to production
   - Monitor storage usage
   - Set up alerts for quota

---

## 📞 Support

For issues or questions:
- Check [Troubleshooting](#-troubleshooting) section
- Review [Supabase Storage docs](https://supabase.com/docs/guides/storage)
- Check migration file: `supabase/migrations/20250201_storage_buckets_setup.sql`

---

**Implementation Complete!** 🎉

Photo upload feature is fully implemented and ready for testing once the migration is applied to your Supabase database.
