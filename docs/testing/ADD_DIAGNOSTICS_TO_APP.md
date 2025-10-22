# 🔧 How to Add Diagnostics Page to Your App

## Quick Setup (2 minutes)

### Step 1: Add Route to App Router

Edit: `lib/core/router/app_router.dart`

Add this import at the top:
```dart
import '../test_connection_from_india.dart';
```

Add this route to your routes list:
```dart
GoRoute(
  path: '/diagnostics',
  name: 'diagnostics',
  builder: (context, state) => const ConnectionTestPage(),
),
```

### Step 2: Add Button to Settings Page (Optional)

Edit: `lib/features/settings/presentation/pages/settings_page.dart`

Add this in the "App Settings" section:
```dart
_buildSettingTile(
  context,
  icon: Icons.bug_report,
  title: 'Network Diagnostics',
  subtitle: 'Test connection to Supabase',
  onTap: () {
    context.push('/diagnostics');
  },
),
```

### Step 3: Or Create a Temporary Debug Button on Login Page

Edit: `lib/features/auth/presentation/pages/login_page.dart`

Add this button before the login button:
```dart
TextButton(
  onPressed: () => context.push('/diagnostics'),
  child: const Text('🔧 Test Connection'),
),
```

---

## Usage

1. **Start the app**
2. **Navigate to** `/diagnostics` or click the debug button
3. **Tests run automatically**
4. **Share results** with me if issues found

---

## Alternative: Run Standalone Test

If you don't want to modify the app, Nithya can run this in terminal:

```bash
# Create a simple test file
cat > test_supabase_simple.dart << 'EOF'
import 'dart:io';

void main() async {
  print('🔍 Testing Supabase Connection from India...\n');

  // Test 1: Internet
  print('Test 1: Internet Connection...');
  try {
    final result = await InternetAddress.lookup('google.com')
        .timeout(Duration(seconds: 10));
    print('✅ Internet works!\n');
  } catch (e) {
    print('❌ No internet: $e\n');
    return;
  }

  // Test 2: Supabase Domain
  print('Test 2: Supabase Domain Resolution...');
  try {
    final result = await InternetAddress.lookup('ckgaoxajvonazdwpsmai.supabase.co')
        .timeout(Duration(seconds: 10));
    print('✅ Supabase domain resolves to: ${result[0].address}\n');
  } catch (e) {
    print('❌ BLOCKED! Cannot reach Supabase: $e');
    print('\n🔧 SOLUTION: Try mobile hotspot or VPN!\n');
    return;
  }

  // Test 3: HTTP Connection
  print('Test 3: HTTPS Connection...');
  try {
    final client = HttpClient();
    client.connectionTimeout = Duration(seconds: 15);
    final request = await client.getUrl(
        Uri.parse('https://ckgaoxajvonazdwpsmai.supabase.co'))
        .timeout(Duration(seconds: 15));
    final response = await request.close();
    print('✅ Successfully connected! Status: ${response.statusCode}\n');
    print('🎉 Network is working! Authentication should work.\n');
    client.close();
  } catch (e) {
    print('❌ BLOCKED! Cannot connect: $e');
    print('\n🔧 SOLUTION: Use mobile hotspot or VPN!\n');
  }
}
EOF

# Run the test
dart test_supabase_simple.dart
```

---

## What to Look For

### ✅ All Tests Pass
```
✅ Test 1: Internet Connection - success
✅ Test 2: DNS Resolution - success
✅ Test 3: HTTPS Connection - success
✅ Test 4: Supabase SDK - success
✅ Test 5: Database - success
✅ Test 6: Auth Endpoint - success
✅ Test 7: Sign Up - success
✅ Test 8: Login - success
```
**→ Network is fine! Auth issue is something else**

### ❌ Tests Fail at Step 2 or 3
```
✅ Test 1: Internet Connection - success
❌ Test 2: DNS Resolution - FAILED (blocked)
❌ Test 3: HTTPS Connection - FAILED (blocked)
```
**→ ISP/Firewall blocking Supabase!**
**→ SOLUTION: Mobile hotspot or VPN**

---

## Send Me the Results

Have Nithya:
1. Run the diagnostics
2. Take screenshot of results
3. Send to you
4. Share with me

I can tell immediately what's wrong from the test results!

---

## Quick Test Without App

Ask Nithya to open Terminal/Command Prompt and run:

### Windows:
```cmd
ping ckgaoxajvonazdwpsmai.supabase.co
```

### Mac/Linux:
```bash
ping ckgaoxajvonazdwpsmai.supabase.co
```

**If it times out** → Supabase is blocked by network!

---

**TL;DR**: Add the diagnostics route, have Nithya run it, and we'll know exactly what's wrong in 30 seconds! 🚀
