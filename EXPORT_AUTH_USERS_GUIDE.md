# How to Export auth.users (Authentication Data)

## ⚠️ Important Security Note

The `auth.users` table contains sensitive authentication data (password hashes, tokens, etc.). Supabase restricts direct SQL access to this table for security reasons.

---

## Method 1: Supabase CLI (Official Method) ✅ RECOMMENDED

### Prerequisites
1. Install Supabase CLI
2. Have access to both Supabase accounts

### Steps:

#### 1. Install Supabase CLI

**Windows:**
```bash
npm install -g supabase
```

**Mac/Linux:**
```bash
brew install supabase/tap/supabase
```

#### 2. Login to OLD Supabase Account

```bash
supabase login
```
- Enter your OLD account credentials (palkarfoods224@gmail.com)
- Browser will open for authentication

#### 3. Link OLD Project

```bash
supabase link --project-ref YOUR_OLD_PROJECT_REF
```

**How to get project ref:**
1. Go to https://supabase.com
2. Open OLD project
3. Settings → General → Reference ID
4. Copy the project ref (e.g., `abcdefghijklm`)

#### 4. Export Database (includes auth.users)

```bash
supabase db dump --local -f old_database_dump.sql
```

This exports:
- ✅ auth.users (with password hashes)
- ✅ auth.identities
- ✅ auth.sessions
- ✅ All public schema tables
- ✅ All functions, policies, triggers

#### 5. Switch to NEW Account

```bash
supabase logout
supabase login
```
- Enter NEW account credentials (grayprogrammers008@gmail.com)

#### 6. Link NEW Project

```bash
supabase link --project-ref YOUR_NEW_PROJECT_REF
```

#### 7. Import to NEW Database

```bash
supabase db push --dry-run  # Test first
supabase db push            # Actually import
```

---

## Method 2: Supabase Support (Easiest) ✅ SIMPLE

### Contact Supabase Support

Email: **support@supabase.com**

**Subject:** Request: Migrate auth.users between projects

**Email Template:**
```
Hello Supabase Support,

I need to migrate my Supabase project data including authentication users.

Old Project:
- Account: palkarfoods224@gmail.com
- Project Name: TravelCompanion
- Project Ref: [YOUR_OLD_PROJECT_REF]

New Project:
- Account: grayprogrammers008@gmail.com
- Project Name: TravelCompanion
- Project Ref: [YOUR_NEW_PROJECT_REF]

Please help me migrate:
1. All auth.users (with password hashes)
2. All auth.identities
3. All auth.sessions

I have already migrated the public schema data manually.

Thank you!
```

**Response Time:** Usually 1-2 business days

---

## Method 3: Manual SQL Export (Advanced) ⚠️ LIMITED

### ⚠️ Limitations:
- Cannot export password hashes (security restriction)
- Can export email, metadata, created_at, etc.
- **Users will need to reset passwords**

### If You Still Want This Approach:

Run this in OLD Supabase SQL Editor:

```sql
-- Export auth.users metadata (NO passwords)
SELECT format(
    'INSERT INTO auth.users (id, email, email_confirmed_at, created_at, updated_at, raw_user_meta_data) VALUES (%L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    email,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_user_meta_data::text
) as import_script
FROM auth.users
ORDER BY created_at;
```

**Problem:** This won't work because you don't have permission to INSERT into `auth.users` directly. Supabase Auth manages this table.

---

## Method 4: User Re-Registration (Simplest) ✅ NO SUPPORT NEEDED

### How It Works:

1. **Import profile data** (already done with your CSV)
2. **Users create new accounts** on new database (same email addresses)
3. **App links auth.users to profiles** by email matching
4. **All data preserved** (trips, expenses, messages, etc.)

### Implementation:

**In your Flutter app, add this logic:**

```dart
// After user registers on new database
Future<void> linkAuthToExistingProfile(User authUser) async {
  // Check if profile already exists with this email
  final existingProfile = await supabase
      .from('profiles')
      .select()
      .eq('email', authUser.email)
      .maybeSingle();

  if (existingProfile != null) {
    // Update profile with new auth user ID
    await supabase
        .from('profiles')
        .update({'id': authUser.id})
        .eq('email', authUser.email);

    print('Linked existing profile to new auth user');
  } else {
    // Create new profile
    await supabase
        .from('profiles')
        .insert({
          'id': authUser.id,
          'email': authUser.email,
          'full_name': authUser.email.split('@')[0],
        });
  }
}
```

### Steps for Users:

1. Open app connected to NEW database
2. Click "Sign Up" (not "Log In")
3. Enter **same email** as before
4. Create **new password**
5. App automatically links to existing profile
6. All their trips, expenses, etc. are still there!

**Pros:**
- ✅ No Supabase support needed
- ✅ No CLI tools needed
- ✅ Works immediately
- ✅ Users just need 2 minutes to re-register

**Cons:**
- ❌ Users need to create new passwords

---

## Recommended Approach

### For 10 Users (Your Case):

**Option 1: User Re-Registration** (5 minutes setup)
- Best for small user bases (< 100 users)
- No support ticket needed
- Works immediately

**Option 2: Supabase Support** (1-2 days wait)
- Best if you want to preserve passwords
- Official support handles everything
- Safest method

**Option 3: Supabase CLI** (30 minutes setup)
- Best if you want full control
- Exports everything including passwords
- Requires technical setup

---

## Which Method Should You Choose?

| Method | Time | Difficulty | Preserves Passwords |
|--------|------|------------|---------------------|
| User Re-Registration | 5 min | Easy | ❌ No |
| Supabase Support | 1-2 days | Easy | ✅ Yes |
| Supabase CLI | 30 min | Medium | ✅ Yes |
| Manual SQL | N/A | Hard | ❌ No (blocked) |

**My Recommendation:** Start with **User Re-Registration** since you only have 10 users. If users complain about resetting passwords, then contact Supabase Support.

---

## Summary

✅ **Profile data already exported** - Your CSV has all user profiles
✅ **Public data can be migrated** - Trips, expenses, checklists
⚠️ **Auth data needs special handling** - Choose one method above

**Easiest path:**
1. Import profile data to new database (using your CSV)
2. Have users re-register with same email
3. App automatically links them to existing data
4. Done in 5 minutes!

---

Need help implementing the auto-linking code in your Flutter app? Let me know!
