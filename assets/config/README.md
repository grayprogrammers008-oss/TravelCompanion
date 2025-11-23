# Test Users Configuration

This directory contains configuration files for development and testing.

## test_users.json

This file enables quick login during development by providing a dropdown of test users on the login page.

### Setup Instructions

1. **Fill in the shared password:**
   ```json
   "sharedPassword": "YourTestPassword123"
   ```

2. **Add test users:**
   - The JSON file contains example users
   - Replace/add emails with actual users from your Supabase database
   - All test users should have the same password in the database

3. **Enable/disable the dropdown:**
   ```json
   "enableTestUserDropdown": true  // Set to false for production
   ```

### Example Configuration

```json
{
  "enableTestUserDropdown": true,
  "sharedPassword": "Test@1234",
  "testUsers": [
    {
      "name": "Select Test User",
      "email": ""
    },
    {
      "name": "John Doe",
      "email": "john@example.com"
    },
    {
      "name": "Jane Smith",
      "email": "jane@example.com"
    }
  ]
}
```

### Security Notes

- ✅ This file IS committed to the repository
- ✅ Passwords are NOT hardcoded in the file
- ✅ Each developer fills in their local copy with the test password
- ⚠️ Never use production passwords here
- ⚠️ Never enable this in production builds

### How It Works

1. The app loads `test_users.json` on the login page
2. If `enableTestUserDropdown` is `true`, a dropdown appears
3. When you select a test user, it auto-fills:
   - Email from the JSON file
   - Password from `sharedPassword` field
4. Click "Sign In" to log in

### For New Team Members

1. Open `assets/config/test_users.json`
2. Find the `"sharedPassword"` field
3. Ask your team lead for the shared test password
4. Fill it in and save the file
5. The test user dropdown will now work on the login page
