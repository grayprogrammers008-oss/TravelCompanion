# Release Runbook

How to ship `com.pathio.travel` to Google Play Store and Apple App Store.

## TL;DR — Cutting a release

```bash
# 1. Bump version in pubspec.yaml (e.g., 1.0.0+1 → 1.0.1+2)
# 2. Update distribution/whatsnew/whatsnew-en-US with release notes
# 3. Commit + tag
git commit -am "chore: Release 1.0.1"
git tag v1.0.1
git push origin main --tags

# Pushing the tag triggers .github/workflows/release.yml, which:
#   - Builds Android AAB and uploads to Play Store internal track
#   - Builds iOS IPA and uploads to TestFlight
#   - Creates a GitHub release with both artifacts
```

Manual trigger (no tag): GitHub → Actions → Release → Run workflow → pick track.

---

## One-time setup

### Android signing key

```bash
# Generate the upload keystore (do this ONCE; back up the file securely)
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Encode for GitHub Secrets
base64 -w 0 upload-keystore.jks > keystore.base64.txt
```

Set these GitHub repository secrets (Settings → Secrets → Actions):

| Secret | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | contents of `keystore.base64.txt` |
| `ANDROID_STORE_PASSWORD` | the keystore password you set |
| `ANDROID_KEY_PASSWORD` | the key password you set (usually same as store) |
| `ANDROID_KEY_ALIAS` | `upload` |

### Play Store service account

1. Google Cloud Console → IAM → Service Accounts → Create
2. Grant role: **Service Account User** + **Editor** (or finer-grained)
3. Create JSON key → download
4. Google Play Console → Setup → API access → link this service account
5. Grant access to the app and the **Release Manager** role
6. Set GitHub secret `PLAY_STORE_SERVICE_ACCOUNT_JSON` = paste the full JSON

### App Store Connect API key

1. App Store Connect → Users and Access → Integrations → App Store Connect API
2. Generate API Key with **App Manager** role
3. Download the `.p8` private key file (one-time; save it)
4. Note the Key ID and Issuer ID

Set these GitHub secrets:

| Secret | Value |
|---|---|
| `APPSTORE_ISSUER_ID` | the Issuer ID from the API page |
| `APPSTORE_KEY_ID` | the Key ID |
| `APPSTORE_PRIVATE_KEY` | contents of the `.p8` file |

### iOS code signing certificate

1. On a Mac: Xcode → Settings → Accounts → Manage Certificates → Apple Distribution
2. Export as `.p12` with a password
3. Encode: `base64 -i certs.p12 -o certs.base64.txt`
4. Set GitHub secrets:
   - `IOS_CERTIFICATE_BASE64` = contents of `certs.base64.txt`
   - `IOS_CERTIFICATE_PASSWORD` = password you set on export

### Edit `ios/ExportOptions.plist`

Replace `YOUR_TEAM_ID` with your Apple Developer Team ID
(find at https://developer.apple.com/account → Membership Details).

---

## Local builds (without CI)

### Android AAB

```bash
# One-time: create android/key.properties (not committed):
cat > android/key.properties <<EOF
storePassword=<your store password>
keyPassword=<your key password>
keyAlias=upload
storeFile=/absolute/path/to/upload-keystore.jks
EOF

flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS IPA (Mac only)

```bash
cd ios && pod install --repo-update && cd ..
flutter build ipa --release \
  --export-options-plist=ios/ExportOptions.plist
# Output: build/ios/ipa/travel_crew.ipa
```

Upload via **Transporter** app or `xcrun altool`.

---

## Pre-release checklist

Run through this every time before tagging:

- [ ] All tests pass: `flutter test`
- [ ] Version bumped in `pubspec.yaml` (both name and build number)
- [ ] `distribution/whatsnew/whatsnew-en-US` updated
- [ ] **Admin panel access** locked down — see [CLAUDE.md](CLAUDE.md#admin-panel-access)
  for the `isAdminProvider` checks that are currently disabled for dev
- [ ] **Supabase production URL** verified — confirm
  `lib/core/config/supabase_config.dart` points at the live project,
  and all migrations under `supabase/migrations/` have been applied
- [ ] **Privacy policy URL** is live and current
- [ ] `flutter analyze --no-fatal-infos --no-fatal-warnings` clean
- [ ] Manual smoke test on a real device of: login, create trip,
  add expense, send chat message, SOS trigger
- [ ] Coverage CI green on the commit you're tagging

---

## Tracks

The workflow defaults to the `internal` Play Store track (visible only to
testers you've added in Play Console). Promote up the chain manually
once you're satisfied:

```
internal → closed (alpha) → open (beta) → production
```

For iOS, the workflow uploads to TestFlight. From there, internal
testers see it instantly; external testers need Apple's beta review
(~24h); production submission requires app review (~1-2 days first
time, often faster after).

---

## Rollback

### Android
Play Console → Production → Releases → Halt rollout. Then upload a new
build with the previous good code + a higher version code.

### iOS
App Store Connect → app version → Reject Binary. Submit prior build.

Note: you cannot truly "downgrade" — both stores require a higher
version number on every upload. The fix is always "ship a corrected
new build."

---

## Troubleshooting

**"Your app is not compliant with Google Play policies"** — usually a
missing privacy policy entry, broken data safety form, or use of
restricted permissions without justification. The email lists the
specific issue.

**"Missing Info.plist value for NSCameraUsageDescription"** — iOS
requires a human-readable purpose string for every sensitive
permission. Add to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Scan receipts for expense tracking</string>
<key>NSMicrophoneUsageDescription</key>
<string>Voice trip wizard input</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Show nearby places and emergency contacts</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Attach photos to messages and expenses</string>
```

**iOS build fails with "Provisioning profile doesn't include the
currently selected device"** — your iOS bundle ID in App Store Connect
must match `ios/Runner.xcodeproj/project.pbxproj`. Both should be
`com.pathio.travel`.
