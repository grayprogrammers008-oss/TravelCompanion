# Profile Photo Upload - Manual Testing Guide

**Version:** 1.0
**Last Updated:** February 1, 2025
**Estimated Time:** 15-20 minutes

---

## 🎯 Prerequisites

Before testing, ensure:
- [ ] Supabase migration applied (`20250201_storage_buckets_setup.sql`)
- [ ] App compiled and running on device/simulator
- [ ] Test user account created
- [ ] Internet connection available

### Verify Migration Applied

**Option 1: Supabase Dashboard**
1. Go to Supabase Dashboard → Storage
2. Verify these buckets exist:
   - `profile-avatars` (Public)
   - `trip-covers` (Public)
   - `expense-receipts` (Private)
   - `settlement-proofs` (Private)

**Option 2: SQL Query**
```sql
SELECT id, name, public, file_size_limit
FROM storage.buckets
WHERE id IN ('profile-avatars', 'trip-covers', 'expense-receipts', 'settlement-proofs');
```

Expected: 4 rows returned

---

## 📝 Test Scenarios

### Test 1: Upload Photo from Gallery ✅

**Steps:**
1. Launch app and log in
2. Navigate to Settings
3. Tap on your profile card at the top
4. Tap the camera icon on your avatar
5. Select "Choose from Gallery"
6. Pick any image from your photo library
7. Wait for upload to complete

**Expected Results:**
- [ ] Modal sheet appears with camera/gallery options
- [ ] Gallery opens when "Choose from Gallery" is tapped
- [ ] Selected image displays immediately
- [ ] Loading indicator shows during upload
- [ ] Success message: "Profile photo updated successfully"
- [ ] New photo appears in profile
- [ ] Modal closes automatically

**Pass Criteria:** Photo successfully uploaded and displayed

---

### Test 2: Upload Photo from Camera 📷

**Steps:**
1. From profile page, tap camera icon
2. Select "Take Photo"
3. Allow camera permissions if prompted
4. Take a photo
5. Confirm/use the photo
6. Wait for upload

**Expected Results:**
- [ ] Camera app/interface opens
- [ ] Can capture photo
- [ ] Photo uploads successfully
- [ ] Success message shown
- [ ] New photo replaces old one

**Note:** Camera test only works on real device, not simulator

**Pass Criteria:** Photo captured and uploaded successfully

---

### Test 3: Replace Existing Photo 🔄

**Steps:**
1. Ensure you already have a profile photo
2. Tap camera icon to upload new photo
3. Select different image
4. Upload completes

**Expected Results:**
- [ ] Old photo replaced with new one
- [ ] Only one photo visible (no duplicates)
- [ ] Old photo removed from storage
- [ ] New photo URL saved to profile

**Verification:**
Check Supabase Storage → `profile-avatars` → your user folder
- Should contain only the latest photo

**Pass Criteria:** Only newest photo exists in storage

---

### Test 4: Photo Persistence Across App ��

**Steps:**
1. Upload a profile photo
2. Navigate to different pages:
   - Settings page (profile card)
   - Create/view a trip (member list)
   - Any screen showing your avatar
3. Force close app
4. Reopen and check again

**Expected Results:**
- [ ] Photo appears in Settings profile card
- [ ] Photo appears in UserAvatarWidget everywhere
- [ ] Photo persists after app restart
- [ ] Photo loads quickly (cached)

**Pass Criteria:** Photo displays consistently everywhere

---

### Test 5: Logout and Login 🔑

**Steps:**
1. Upload profile photo
2. Log out of app
3. Log back in with same account
4. Check profile

**Expected Results:**
- [ ] Photo still appears after logout/login
- [ ] Photo URL correctly associated with account
- [ ] No errors loading photo

**Pass Criteria:** Photo persists across sessions

---

### Test 6: Cancel Upload ❌

**Steps:**
1. Tap camera icon on avatar
2. Select "Cancel" in modal
3. OR select "Choose from Gallery" then cancel picker
4. OR select "Take Photo" then cancel camera

**Expected Results:**
- [ ] Modal closes without error
- [ ] No upload initiated
- [ ] Existing photo unchanged
- [ ] No error messages

**Pass Criteria:** Cancellation works smoothly

---

### Test 7: Network Error Handling 🌐

**Steps:**
1. Enable airplane mode
2. Try to upload photo
3. Note the error
4. Disable airplane mode
5. Try again

**Expected Results:**
- [ ] Clear error message: "Failed to upload photo: [error details]"
- [ ] Upload doesn't hang indefinitely
- [ ] Can retry after network restored
- [ ] Retry succeeds

**Pass Criteria:** Graceful error handling and recovery

---

### Test 8: Large Image Upload 📏

**Steps:**
1. Select a very large image (e.g., 10MB+ RAW photo)
2. Upload it
3. Check result

**Expected Results:**
- [ ] Image automatically resized to 1024x1024
- [ ] Quality reduced to 85%
- [ ] Upload succeeds (under 5MB limit)
- [ ] Photo displays correctly

**Verification:**
Check storage bucket - file should be ~200-500 KB

**Pass Criteria:** Large images handled gracefully

---

### Test 9: Photo Display Quality 🎨

**Steps:**
1. Upload a high-quality photo
2. Check display in multiple places:
   - Profile page (large avatar)
   - Settings card (medium avatar)
   - Trip member list (small avatar)

**Expected Results:**
- [ ] Photo sharp and clear at all sizes
- [ ] No pixelation or artifacts
- [ ] Proper aspect ratio (circular crop)
- [ ] Colors accurate

**Pass Criteria:** Photo quality good at all sizes

---

### Test 10: Multiple Users 👥

**Steps:**
1. Create/use 2+ test accounts
2. Upload different photos for each
3. Create a trip with both users
4. View trip members

**Expected Results:**
- [ ] Each user sees their own photo in profile
- [ ] Each user's photo displays correctly in member list
- [ ] No photo mix-ups between users
- [ ] Photos load independently

**Pass Criteria:** Multi-user photos work correctly

---

## 🔍 Edge Cases to Test

### Edge Case 1: No Profile Photo (Fallback)
**Test:** User with no uploaded photo
**Expected:** Gradient avatar with initials displays

### Edge Case 2: Corrupted Image URL
**Test:** Manually corrupt avatar_url in database
**Expected:** Falls back to gradient avatar

### Edge Case 3: Deleted Storage File
**Test:** Delete file from storage but keep URL in profile
**Expected:** Shows gradient fallback, no crash

### Edge Case 4: Rapid Uploads
**Test:** Upload multiple photos quickly in succession
**Expected:** Latest upload wins, no race conditions

### Edge Case 5: Offline Mode
**Test:** View profile while offline
**Expected:** Cached photo displays (if viewed before)

---

## ✅ Final Checklist

### Feature Completeness
- [ ] Can upload from gallery
- [ ] Can upload from camera (device only)
- [ ] Can replace existing photo
- [ ] Photo appears in all locations
- [ ] Photo persists across sessions
- [ ] Graceful error handling
- [ ] Image optimization works
- [ ] Old photos deleted

### UI/UX
- [ ] Modal sheet looks good
- [ ] Loading states clear
- [ ] Error messages helpful
- [ ] Success feedback given
- [ ] Avatar displays beautifully
- [ ] Responsive on all screen sizes

### Performance
- [ ] Upload completes in <5 seconds (good network)
- [ ] Images cached properly
- [ ] No memory leaks
- [ ] App remains responsive during upload

### Security
- [ ] Users can only upload to their folder
- [ ] Cannot delete others' photos
- [ ] File type restrictions enforced
- [ ] File size limits enforced

---

## 📊 Test Results Template

```markdown
## Test Session: [Date]
**Tester:** [Your Name]
**Device:** [iOS/Android, Model]
**App Version:** 1.0.0

| Test # | Name | Result | Notes |
|--------|------|--------|-------|
| 1 | Gallery Upload | ✅ Pass | |
| 2 | Camera Upload | ✅ Pass | |
| 3 | Replace Photo | ✅ Pass | |
| 4 | Photo Persistence | ✅ Pass | |
| 5 | Logout/Login | ✅ Pass | |
| 6 | Cancel Upload | ✅ Pass | |
| 7 | Network Error | ✅ Pass | |
| 8 | Large Image | ✅ Pass | |
| 9 | Display Quality | ✅ Pass | |
| 10 | Multiple Users | ✅ Pass | |

**Overall Status:** ✅ All Tests Passed

**Issues Found:** None

**Recommendations:** Ready for production
```

---

## 🐛 Common Issues and Solutions

### Issue: "Failed to upload photo"
**Debug Steps:**
1. Check Supabase Dashboard → Storage → `profile-avatars`
2. Verify bucket exists and is public
3. Check RLS policies applied
4. Review app logs for specific error

### Issue: Photo not appearing
**Debug Steps:**
1. Check database: `SELECT avatar_url FROM profiles WHERE id = '[user_id]'`
2. Verify URL is valid
3. Check if URL is accessible in browser
4. Clear app cache and retry

### Issue: "Permission denied"
**Debug Steps:**
1. Ensure user is authenticated
2. Check RLS policies exist
3. Verify bucket configuration
4. Check user permissions in Supabase

---

## 📸 Test Screenshots Checklist

Capture screenshots of:
- [ ] Profile page with uploaded photo
- [ ] Upload modal sheet
- [ ] Success message
- [ ] Photo in settings
- [ ] Photo in trip members
- [ ] Error message (if any)

---

## 🎉 Completion

Once all tests pass:

1. ✅ Mark implementation as tested
2. ✅ Document any issues found
3. ✅ Update implementation status
4. ✅ Proceed to production deployment

**Congratulations! Profile Photo Upload is fully tested and ready! 🚀**
