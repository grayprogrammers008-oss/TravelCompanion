# Test Users Configuration

This directory contains configuration files for development and testing.

## test_users.json

This file enables quick login during development by providing a dropdown of test users on the login page.

### Setup Instructions

1. **Fill in individual passwords for each user:**
   ```json
   {
     "name": "User Name",
     "email": "user@example.com",
     "password": "UserPassword123"
   }
   ```

2. **Add test users:**
   - The JSON file contains example users with empty passwords
   - Fill in the `password` field for each user
   - Each user can have their own unique password
   - Add more users to the array as needed

3. **Enable/disable the dropdown:**
   ```json
   "enableTestUserDropdown": true  // Set to false for production
   ```

### Example Configuration

```json
{
  "enableTestUserDropdown": true,
  "testUsers": [
    {
      "name": "Select Test User",
      "email": "",
      "password": ""
    },
    {
      "name": "Palkar Foods",
      "email": "palkarfoods224@gmail.com",
      "password": "PalkarPass123"
    },
    {
      "name": "Nithya",
      "email": "nithyavs@live.in",
      "password": "NithyaPass123"
    },
    {
      "name": "Test User",
      "email": "test@example.com",
      "password": "Test@1234"
    }
  ]
}
```

### Security Notes

- ✅ This file IS committed to the repository
- ✅ Passwords are left empty in the committed version
- ✅ Each developer fills in their local copy with actual test passwords
- ⚠️ Never use production passwords here
- ⚠️ Never enable this in production builds
- ⚠️ Keep your local password changes uncommitted (git will show changes, just don't commit them)

### How It Works

1. The app loads `test_users.json` on the login page
2. If `enableTestUserDropdown` is `true`, a dropdown appears with a "Testing Mode" badge
3. When you select a test user, it auto-fills:
   - Email from the JSON file
   - Password from that user's `password` field
4. Click "Sign In" to log in instantly

### For New Team Members

1. Open `assets/config/test_users.json`
2. Find each user in the `testUsers` array
3. Ask your team lead for the passwords for each test account
4. Fill in the `"password"` field for each user
5. Save the file (but don't commit password changes)
6. The test user dropdown will now work on the login page

### Adding New Test Users

To add a new test user to the team:

1. Create the user account in Supabase
2. Add to `test_users.json`:
   ```json
   {
     "name": "New User",
     "email": "newuser@example.com",
     "password": ""
   }
   ```
3. Commit and push the change
4. Share the password with team members who need it
5. Each developer fills in their local copy

### Disabling for Production

Set `enableTestUserDropdown` to `false` before building production releases:

```json
{
  "enableTestUserDropdown": false,
  "testUsers": [ ... ]
}
```
