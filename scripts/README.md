# 🔧 Travel Crew Scripts

Utility scripts for database management, diagnostics, and GitHub automation.

---

## 🎯 Quick Actions

**Create messaging module issues:**
```bash
./scripts/create_messaging_issues.sh
```
This creates 9 GitHub issues for the complete messaging system (Internet + Bluetooth + WiFi Direct).

---

## 📁 Folder Structure

### **Root Scripts** - GitHub Automation (1 file)
- `create_messaging_issues.sh` - **Create 9 messaging module GitHub issues** (NEW! 🎉)

### `/scripts/database/` - SQL Scripts (14 files)

Database setup, management, and troubleshooting scripts.

#### **Main Schema**
- `SUPABASE_SCHEMA.sql` - **Complete database schema** (use this!)
- `SUPABASE_SCHEMA_NEW.sql` - Updated schema version
- `SUPABASE_SCHEMA_OLD.sql` - Legacy schema (archived)

#### **User Management**
- `fix_user_account.sql` - Troubleshoot user account issues
- `CONFIRM_EMAIL.sql` - Manually confirm user emails
- `CLEANUP_NITHYA_DATA.sql` - Clean up test user data

#### **Test Data**
- `CREATE_NITHYA_DUMMY_DATA.sql` - Create test data
- `SUPABASE_DUMMY_DATA.sql` - Sample data for testing
- `HOW_TO_ADD_DUMMY_DATA.md` - Guide for adding test data
- `INSERT_DUMMY_DATA.md` - Data insertion instructions

#### **Debugging**
- `DEBUG_TRIPS.sql` - Debug trip-related queries

#### **Fixes & Patches**
- `ADD_INSERT_POLICIES.sql` - Add missing RLS policies
- `COMPLETE_FIX.sql` - Comprehensive fix script
- `FIX_RLS_POLICIES.sql` - Row Level Security fixes

---

### `/scripts/diagnostics/` - Dart Scripts (6 files)

Flutter diagnostic and testing utilities.

#### **Authentication Diagnostics**
- `diagnose_login_issue.dart` - **Test login issues** (run with: `dart diagnose_login_issue.dart`)
- `diagnose_email_issue.dart` - Debug email-related problems
- `check_user_data.dart` - Verify user data integrity
- `reset_password_helper.dart` - Password reset utilities

#### **Integration Testing**
- `test_supabase_connection.dart` - **Test Supabase connectivity**
- `test_unsplash.dart` - Test Unsplash API integration

---

## 🚀 Common Usage

### Setup Fresh Database

```bash
# 1. Open Supabase Dashboard → SQL Editor
# 2. Copy contents of scripts/database/SUPABASE_SCHEMA.sql
# 3. Paste and Run
# 4. Verify tables in Table Editor
```

---

### Fix User Login Issues

```bash
# Option 1: Use SQL script
# Open scripts/database/fix_user_account.sql
# Replace email in script
# Run in Supabase SQL Editor

# Option 2: Use diagnostic script
dart scripts/diagnostics/diagnose_login_issue.dart
```

---

### Test Supabase Connection

```bash
dart scripts/diagnostics/test_supabase_connection.dart
```

Output will show:
- ✅ Connection successful
- ❌ Connection failed with details

---

### Confirm User Email Manually

```sql
-- Run in Supabase SQL Editor
-- scripts/database/CONFIRM_EMAIL.sql

UPDATE auth.users
SET email_confirmed_at = NOW()
WHERE email = 'user@example.com';
```

---

### Add Test Data

```bash
# 1. Read scripts/database/HOW_TO_ADD_DUMMY_DATA.md
# 2. Use scripts/database/CREATE_NITHYA_DUMMY_DATA.sql
# 3. Run in Supabase SQL Editor
```

---

### Debug Trip Issues

```bash
# Open scripts/database/DEBUG_TRIPS.sql
# Run queries to see trip data
# Useful for troubleshooting trip creation/display
```

---

## 📋 Script Descriptions

### Database Scripts

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `SUPABASE_SCHEMA.sql` | Complete DB schema | Fresh setup, schema reset |
| `fix_user_account.sql` | Fix user issues | Login fails, email problems |
| `CONFIRM_EMAIL.sql` | Confirm emails | User can't login (unconfirmed) |
| `CREATE_NITHYA_DUMMY_DATA.sql` | Test data | Development, testing |
| `DEBUG_TRIPS.sql` | Debug trips | Trip display issues |
| `FIX_RLS_POLICIES.sql` | Fix permissions | Permission denied errors |

### Diagnostic Scripts

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `diagnose_login_issue.dart` | Test auth flow | Login failures |
| `test_supabase_connection.dart` | Test network | Connection issues |
| `check_user_data.dart` | Verify user data | Data integrity issues |
| `test_unsplash.dart` | Test images | Image loading fails |
| `diagnose_email_issue.dart` | Email debugging | Email verification issues |
| `reset_password_helper.dart` | Reset passwords | Password reset needed |

---

## 🔧 Running Dart Scripts

### Prerequisites
```bash
# Ensure Dart SDK is installed
dart --version
```

### Run a Script
```bash
# From project root
dart scripts/diagnostics/diagnose_login_issue.dart

# Or navigate to script
cd scripts/diagnostics
dart diagnose_login_issue.dart
```

### Modify for Your Use
Most scripts have placeholders like:
```dart
const testEmail = 'user@example.com';  // ← CHANGE THIS
const testPassword = 'password123';     // ← CHANGE THIS
```

Update these values before running!

---

## 🎯 Quick Troubleshooting

### Problem: "Can't login"
```bash
# Step 1: Run diagnostic
dart scripts/diagnostics/diagnose_login_issue.dart

# Step 2: If email not confirmed
# Run scripts/database/CONFIRM_EMAIL.sql in Supabase
```

### Problem: "Network timeout"
```bash
# Test connection
dart scripts/diagnostics/test_supabase_connection.dart
```

### Problem: "No trips showing"
```sql
-- Run scripts/database/DEBUG_TRIPS.sql in Supabase
-- Check if trips exist and user has access
```

### Problem: "Permission denied"
```sql
-- Run scripts/database/FIX_RLS_POLICIES.sql
-- This fixes Row Level Security issues
```

---

## 📝 Adding New Scripts

### Database Scripts
1. Create file in `scripts/database/`
2. Name it descriptively (e.g., `FIX_EXPENSE_SPLITS.sql`)
3. Add header comment explaining purpose
4. Update this README

### Diagnostic Scripts
1. Create file in `scripts/diagnostics/`
2. Name it descriptively (e.g., `test_expense_creation.dart`)
3. Add usage comments in script
4. Update this README

---

## ⚠️ Important Notes

### SQL Scripts
- Always backup before running destructive operations
- Test in development environment first
- Read script comments carefully
- Some scripts require parameter changes

### Dart Scripts
- Update hardcoded values before running
- Some scripts require network access
- Check Supabase credentials are configured
- Run from project root for proper imports

---

## 🆘 Need Help?

- **SQL issues:** Check `/docs/troubleshooting/`
- **Auth issues:** Run `diagnose_login_issue.dart`
- **Network issues:** Run `test_supabase_connection.dart`
- **Database setup:** Use `SUPABASE_SCHEMA.sql`

---

**Quick Start:** Use `SUPABASE_SCHEMA.sql` for fresh setup, `diagnose_login_issue.dart` for auth problems!
