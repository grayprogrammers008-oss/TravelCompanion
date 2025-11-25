# Admin Panel Troubleshooting Guide

**Last Updated:** November 24, 2025
**Issue:** ✅ SOLVED - Users tab was showing infinite loading spinner

---

## 🎯 THE FIX

**Root Cause:** PostgreSQL type mismatch. The `email` column is `CITEXT` but the function was declaring return type as `TEXT`.

**Error Message:**
```
structure of query does not match function result type
DETAIL: Returned type citext does not match expected type text in column 2.
```

### Apply This Migration to Fix

**File:** `supabase/migrations/20250131_fix_function_return_types.sql`

Open your Supabase SQL Editor and run this migration. It changes the function's return type from `TEXT` to `CITEXT` for the email column.

```sql
-- Copy and run the contents of 20250131_fix_function_return_types.sql
```

### Optional: Also Apply View Simplification

While not the root cause, this improves performance:

**File:** `supabase/migrations/20250131_fix_user_statistics_view.sql`

```sql
-- Copy the contents of this file and run it in Supabase SQL Editor
```

### Step 2: Run Diagnostics

Open **Supabase SQL Editor** and run the diagnostic script to identify the exact issue:

**File:** `supabase/scripts/debug_admin_loading_issue.sql`

This script contains 10 diagnostic queries. Run each section separately and note the results:

1. ✅ **Check Authentication** - Should show your user ID and email
2. ✅ **Check Your Profile** - Should show your profile data
3. ❓ **Test user_statistics View** - This is likely where the issue is
4. ❓ **Check View Permissions** - Verify RLS policies exist
5. ❓ **Test get_all_users_admin Function** - Should return user list
6. ✅ **Check Function Exists** - Verify function is created
7. ✅ **Check profiles Table RLS** - Should show permissive policies
8. ❓ **Check If View Exists** - Verify view definition
9. ✅ **Test Basic Profile Access** - Should return count
10. ℹ️ **Check Migration History** - See which migrations have been applied

---

## Common Issues and Solutions

### Issue 1: View Doesn't Exist
**Symptom:** Query #8 returns empty result

**Solution:**
```sql
-- Run the 20250131_fix_user_statistics_view.sql migration
```

### Issue 2: View Has No RLS Policy
**Symptom:** Query #3 returns "permission denied" error

**Solution:**
```sql
-- Grant SELECT permission to authenticated users
GRANT SELECT ON user_statistics TO authenticated;
```

### Issue 3: View Definition Has Errors
**Symptom:** Query #8 shows old view definition with expenses JOIN

**Solution:**
```sql
-- Drop and recreate the view
DROP VIEW IF EXISTS user_statistics;
-- Then run the CREATE VIEW statement from the migration
```

### Issue 4: Function Not Found
**Symptom:** Query #5 returns "function does not exist" error

**Solution:**
```sql
-- Run the 20250130_disable_admin_checks_temp.sql migration
-- This creates the get_all_users_admin function with admin checks disabled
```

### Issue 5: Missing Columns in profiles Table
**Symptom:** Query #2 returns "column does not exist" error

**Solution:**
```sql
-- Run the initial admin migration
-- File: 20250128_admin_user_management.sql
```

---

## Current Status

### ✅ Completed
- Admin Panel UI created (3 tabs: Overview, Users, Activity)
- Navigation integrated (Settings → Admin Panel)
- Database functions created (with admin checks temporarily disabled)
- Domain, data, and presentation layers implemented
- 70+ tests passing for admin functionality
- Login issue fixed (RLS policy resolved)

### 🔴 Issues
- **Users Tab**: Infinite loading - awaiting diagnostic results
- Overview Tab: May also have loading issues
- Activity Tab: May also have loading issues

### ⏳ Pending
- Apply `20250131_fix_user_statistics_view.sql` migration
- Run diagnostic script to identify root cause
- Fix identified issues based on diagnostic results

---

## Temporary Security Bypasses (⚠️ REVERT BEFORE PRODUCTION)

### UI Level
1. **Settings Page** - Admin Panel visible to all users
   - File: [settings_page_enhanced.dart:299-329](lib/features/settings/presentation/pages/settings_page_enhanced.dart#L299-L329)
   - TODO: Restore `isAdminProvider` check

2. **Dashboard Page** - Access check disabled
   - File: [admin_dashboard_page.dart:35-38](lib/features/admin/presentation/pages/admin_dashboard_page.dart#L35-L38)
   - TODO: Restore admin permission check

### Database Level
3. **Admin Functions** - Permission checks commented out
   - File: `supabase/migrations/20250130_disable_admin_checks_temp.sql`
   - Functions affected:
     - `get_all_users_admin()`
     - `suspend_user()`
     - `activate_user()`
     - `update_user_role()`
     - `get_admin_dashboard_stats()`
   - TODO: Revert to original functions with security checks

---

## Data Flow (for debugging)

```
User clicks Users tab
    ↓
AdminUserList widget renders
    ↓
Watches adminUsersProvider(UserListParams)
    ↓
FutureProvider.family calls GetAllUsersUseCase
    ↓
UseCase calls AdminRepositoryImpl.getAllUsers()
    ↓
Repository calls AdminRemoteDataSource.getAllUsers()
    ↓
DataSource makes Supabase RPC call: get_all_users_admin()
    ↓
PostgreSQL function queries user_statistics view
    ↓
View joins profiles table (simplified - no expenses)
    ↓
Returns List<AdminUser> back up the chain
    ↓
Widget displays user list
```

**Current Failure Point:** Likely at the view query or function call level

---

## Files Reference

### Database Files
- `supabase/migrations/20250128_admin_user_management.sql` - Initial admin system
- `supabase/migrations/20250129_fix_admin_rls.sql` - Fixed login issue ✅
- `supabase/migrations/20250130_disable_admin_checks_temp.sql` - Disabled admin checks (TEMP)
- `supabase/migrations/20250131_fix_user_statistics_view.sql` - Simplified view (APPLY THIS)
- `supabase/scripts/make_user_admin.sql` - Helper to make yourself admin
- `supabase/scripts/debug_admin_loading_issue.sql` - Diagnostic queries (RUN THIS)

### Flutter Files
- [lib/features/admin/presentation/pages/admin_dashboard_page.dart](lib/features/admin/presentation/pages/admin_dashboard_page.dart) - Main dashboard
- [lib/features/admin/presentation/widgets/admin_user_list.dart](lib/features/admin/presentation/widgets/admin_user_list.dart) - Users tab widget
- [lib/features/admin/presentation/providers/admin_providers.dart](lib/features/admin/presentation/providers/admin_providers.dart) - State management
- [lib/features/admin/data/datasources/admin_remote_datasource.dart](lib/features/admin/data/datasources/admin_remote_datasource.dart) - Supabase API calls

### Documentation
- [CLAUDE.md](CLAUDE.md) - Complete development notes
- [ADMIN_PANEL_TROUBLESHOOTING.md](ADMIN_PANEL_TROUBLESHOOTING.md) - This file

---

## Next Steps

1. **Apply Migration**
   - Open Supabase SQL Editor
   - Run `supabase/migrations/20250131_fix_user_statistics_view.sql`

2. **Run Diagnostics**
   - Open Supabase SQL Editor
   - Run each query from `supabase/scripts/debug_admin_loading_issue.sql`
   - Note which queries fail and what error messages appear

3. **Report Results**
   - Share the output of the failed queries
   - This will help identify the exact root cause

4. **Apply Fix**
   - Based on diagnostic results, apply the appropriate solution
   - Test the Users tab to verify loading works

---

## Contact Points

If you need to make yourself an admin user in the database:
1. Open `supabase/scripts/make_user_admin.sql`
2. Replace `'your-email@example.com'` with your actual email
3. Run Step 1 to get your user ID
4. Uncomment and run Step 2 with your user ID
5. Run Step 3 to verify the change

---

**Remember:** All temporary security bypasses MUST be reverted before production deployment!
