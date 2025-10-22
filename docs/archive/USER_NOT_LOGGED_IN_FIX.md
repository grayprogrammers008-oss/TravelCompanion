# 🔧 Fix: "User Not Logged In" Error

**Last Updated**: 2025-10-20

## 🐛 The Problem

**You reported**: "When I try to add expense it is showing user not logged in. I don't know why such error is coming. I'm not sure it could be the same problem for creating trip as well"

**Symptoms**:
- ✅ Login works
- ✅ Home page loads
- ✅ Can see trips (after RLS fix)
- ❌ **Can't create new trip** → "User not logged in"
- ❌ **Can't add expense** → "User not logged in"
- ❌ Create operations fail even though you're logged in

---

## 🔍 Root Cause

The issue occurs because `SupabaseClientWrapper.currentUserId` returns `null` even after login.

**Why this happens**:

1. ✅ You log in → Supabase creates session
2. ✅ Session stored in browser (localStorage/sessionStorage)
3. ❌ **Page refresh or navigation** → Session might not restore immediately
4. ❌ `client.auth.currentUser` returns `null` temporarily
5. ❌ Remote datasources check user ID → throws "User not authenticated"

**Common causes**:
- Browser cache issues
- PKCE auth flow timing (async session restoration)
- Multiple tabs with different auth states
- Supabase session not persisting correctly
- Auth state not fully initialized before operations

---

## ✅ **Solution 1: Check Console for Debug Messages**

I've added debug logging to track when the user ID is null.

**What to do**:

1. **Open browser console** (F12 or Cmd+Option+I)
2. **Try to create a trip** or add expense
3. **Look for this message**:
   ```
   ⚠️  WARNING: currentUserId is null! User might not be authenticated.
      Current session: null
   ```

**If you see this**:
- Session is lost or not restored
- Need to fix session persistence

**If you DON'T see this**:
- Session exists but still getting error
- Issue might be elsewhere (check next sections)

---

## ✅ **Solution 2: Clear Browser Storage and Re-login**

Sometimes old auth tokens or corrupted session data causes issues.

**Steps**:

1. **Open browser console** (F12)
2. **Go to Application tab** (Chrome) or Storage tab (Firefox)
3. **Clear all storage**:
   - Local Storage → Right-click → Clear
   - Session Storage → Right-click → Clear
   - Cookies → Clear all
4. **Refresh page** (Cmd+R)
5. **Log in again**
6. **Try creating trip/expense**

This forces a fresh login with clean session.

---

## ✅ **Solution 3: Check Supabase Auth Settings**

Verify auth configuration in Supabase:

**Steps**:

1. **Go to Supabase Auth Settings**:
   - https://supabase.com/dashboard/project/ckgaoxajvonazdwpsmai/auth/settings

2. **Check these settings**:
   - ✅ **Enable email confirmations**: OFF (for dev/testing)
   - ✅ **Session timeout**: Should be high (e.g., 7 days)
   - ✅ **Auto-refresh tokens**: Should be enabled
   - ✅ **Site URL**: Should include `http://localhost:8080`

3. **Add Site URL** (if not present):
   - Under "URL Configuration"
   - Add: `http://localhost:8080`
   - Click Save

4. **Refresh your app** and try again

---

## ✅ **Solution 4: Wait for Session to Initialize**

The app might be trying to create trips before Supabase session is fully restored.

**Quick Fix**: Add a small delay or loading state

Let me check if we need to add a session initialization check...

Actually, the router already handles this with `authStateProvider`. The issue might be that the session exists but `currentUser` isn't available yet.

---

## ✅ **Solution 5: Verify RLS Policies Allow INSERT**

Even if you're logged in, you need INSERT policies for trips and expenses.

**Check in Supabase**:

Run this SQL to see INSERT policies:
```sql
SELECT
  tablename,
  policyname,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename IN ('trips', 'expenses', 'trip_members')
  AND cmd = 'INSERT'
ORDER BY tablename;
```

**Expected**:
```
tablename  | policyname                           | cmd
-----------|--------------------------------------|--------
trips      | Users can create trips               | INSERT
expenses   | Users can create expenses            | INSERT
trip_members | Users can insert trip members...   | INSERT
```

**If missing**, run this to add them:

```sql
-- Allow users to create trips
DROP POLICY IF EXISTS "Users can create trips" ON trips;
CREATE POLICY "Users can create trips"
ON trips
FOR INSERT
WITH CHECK (auth.uid() = created_by);

-- Allow users to create expenses
DROP POLICY IF EXISTS "Users can create expenses" ON expenses;
CREATE POLICY "Users can create expenses"
ON expenses
FOR INSERT
WITH CHECK (auth.uid() = paid_by);
```

---

## ✅ **Solution 6: Use Auth Repository getCurrentUser**

Instead of relying on `SupabaseClientWrapper.currentUserId`, we should get the user from the auth repository which has proper session management.

This is a code change that might be needed if the above solutions don't work.

---

## 🧪 **Debugging Steps**

### Step 1: Check Current User in Console

Open browser console and run:
```javascript
// In browser console
localStorage.getItem('supabase.auth.token')
```

**If null**: Session not stored, need to re-login
**If exists**: Session stored, but might not be read correctly

---

### Step 2: Check Auth State Provider

The app uses `authStateProvider` which watches Supabase auth changes. Check if it's updating:

**In console, you should see**:
```
✅ Supabase initialized successfully
[Auth] User signed in: [user-id]
```

**If you don't see the user ID**:
- Auth state not propagating
- Need to check auth providers setup

---

### Step 3: Test with Simple Login Flow

1. **Logout** (if logged in)
2. **Close all browser tabs** with the app
3. **Clear browser cache/cookies**
4. **Open fresh tab**
5. **Login again**
6. **Immediately try to create trip** (without navigating)
7. **Check if it works**

If it works immediately after login but fails after refresh → Session persistence issue

If it doesn't work even immediately after login → RLS policy issue

---

## 🎯 **Most Likely Solution**

Based on your error, the most likely fixes are:

**#1 Priority**: Run the INSERT policy SQL (Solution 5)
- Missing INSERT policies would cause "User not logged in" error
- Even though user is authenticated, RLS blocks the INSERT

**#2 Priority**: Clear browser storage and re-login (Solution 2)
- Corrupted session data
- Fresh login fixes it

**#3 Priority**: Check Supabase settings (Solution 3)
- Site URL not configured
- Session timeout too short

---

## 📝 **What I Changed**

**File**: `lib/core/network/supabase_client.dart` (lines 59-66)

**Added debug logging**:
```dart
static String? get currentUserId {
  final userId = currentUser?.id;
  if (kDebugMode && userId == null) {
    print('⚠️  WARNING: currentUserId is null! User might not be authenticated.');
    print('   Current session: ${client.auth.currentSession}');
  }
  return userId;
}
```

This will help you see in the console when the user ID is null.

---

## 🚀 **Action Plan**

**Do these in order**:

1. ✅ **Check browser console** when trying to create trip/expense
   - Look for "currentUserId is null" warning

2. ✅ **Run INSERT policy SQL** ([Solution 5](#solution-5-verify-rls-policies-allow-insert))
   - Add missing INSERT policies for trips/expenses

3. ✅ **Clear browser storage** and re-login ([Solution 2](#solution-2-clear-browser-storage-and-re-login))
   - Fresh session

4. ✅ **Try creating trip/expense again**
   - Should work now!

5. ✅ **If still not working**: Check Supabase auth settings ([Solution 3](#solution-3-check-supabase-auth-settings))

---

## 📚 **Related Documentation**

- **[COMPLETE_FIX.sql](COMPLETE_FIX.sql)** - RLS policies fix (for SELECT)
- **[RLS_RECURSION_FIX.md](RLS_RECURSION_FIX.md)** - Infinite recursion fix
- **[LOGIN_NAVIGATION_FIX.md](LOGIN_NAVIGATION_FIX.md)** - Login navigation
- **[ONLINE_ONLY_MODE.md](ONLINE_ONLY_MODE.md)** - Supabase configuration

---

## ✅ **Summary**

**Error**: "User not logged in" when creating trips/expenses

**Most likely cause**: Missing INSERT RLS policies or session not persisting

**Quick fix**:
1. Run INSERT policy SQL (Solution 5)
2. Clear browser storage and re-login (Solution 2)
3. Check console for debug messages

**App is restarting now with debug logging** - check the console when you try to create a trip!

---

**Let me know what you see in the console and we'll fix it!** 🚀
