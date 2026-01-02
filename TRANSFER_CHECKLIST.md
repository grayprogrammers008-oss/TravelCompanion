# TravelCompanion Ownership Transfer Checklist

**Owner:** Wife (L2 + EAD) - grayprogrammer007@gmail.com
**Transfer Date:** January 2026
**Purpose:** Complete handover from husband to wife

---

## Week 1: Banking & Claude Code Setup

### Day 1-2: Open Bank Account

- [ ] **Wife: Research banks**
  - Compare Chase, Bank of America, Wells Fargo
  - Look for FREE personal checking accounts
  - Check branch locations near you

- [ ] **Wife: Gather documents**
  - [ ] Social Security Card
  - [ ] Passport or Driver's License
  - [ ] Proof of address (lease, utility bill)
  - [ ] Phone number

- [ ] **Wife: Open account**
  - **Option A:** Online application (10 minutes)
    - Go to chase.com/personal/checking
    - Fill application
    - Get instant approval
    - Note down account number
  - **Option B:** In-person at branch (30 minutes)
    - Visit branch with documents
    - Open account
    - Get temporary debit card on spot

- [ ] **Wife: Wait for debit card**
  - Physical card arrives in 7-10 days
  - OR get instant digital card in mobile app (use immediately)

- [ ] **Husband: Transfer startup capital**
  - [ ] Amount: $1,000
  - [ ] Method: ACH transfer / Zelle / Wire
  - [ ] Memo: "Support for [Wife's Name]"
  - [ ] Screenshot transfer confirmation

---

### Day 3-4: Claude Code Subscription

- [ ] **Husband: Cancel current subscription**
  - [ ] Go to claude.ai
  - [ ] Login with current account
  - [ ] Settings → Billing → Cancel subscription
  - [ ] Note effective cancellation date

- [ ] **Wife: Create Claude account**
  - [ ] Go to claude.ai
  - [ ] Sign up with grayprogrammer007@gmail.com
  - [ ] Verify email
  - [ ] Complete profile

- [ ] **Wife: Subscribe to Claude Code**
  - [ ] Select Claude Code plan
  - [ ] Choose: $200/year (best value) OR $20/month
  - [ ] Enter debit card details
  - [ ] Complete payment
  - [ ] Save receipt for taxes

- [ ] **Wife: Install/Login to Claude Code on Mac**
  ```bash
  # Logout of old account
  claude logout

  # Login with wife's account
  claude login --email grayprogrammer007@gmail.com

  # Open TravelCompanion project
  cd /Users/vinothvs/Development/TravelCompanion
  claude .
  ```

- [ ] **Wife: Verify context preserved**
  - [ ] Read: WIFE_FIRST_MESSAGE.md
  - [ ] Send first message to Claude
  - [ ] Run tests from CONTEXT_VERIFICATION_TEST.md
  - [ ] Confirm Claude understands business structure

---

### Day 5-7: Set Up Monthly Support

- [ ] **Husband & Wife: Agree on monthly transfer**
  - [ ] Amount: $500/month
  - [ ] Date: 1st of every month (or choose date)
  - [ ] Method: ACH transfer / Zelle
  - [ ] Memo template: "Support for [Wife's Name]"

- [ ] **Husband: Set up recurring transfer** (optional)
  - Many banks allow scheduled recurring transfers
  - OR manually transfer each month

- [ ] **Wife: Track support received**
  - Create simple spreadsheet:
    - Column A: Date
    - Column B: Amount received from husband
    - Column C: Business expenses paid
    - Column D: Balance remaining

---

## Week 2: Developer Accounts Setup

### Apple Developer Account

- [ ] **Wife: Create Apple ID** (if doesn't exist)
  - Go to appleid.apple.com
  - Use grayprogrammer007@gmail.com
  - Strong password + 2FA

- [ ] **Wife: Enroll in Apple Developer Program**
  - [ ] Go to developer.apple.com/programs/enroll
  - [ ] Choose "Individual" (not company)
  - [ ] Fill personal information (wife's full legal name)
  - [ ] Enter wife's SSN for tax purposes
  - [ ] Pay $100 using wife's debit card
  - [ ] Wait for approval (usually 24-48 hours)
  - [ ] Save receipt for taxes

- [ ] **Wife: Set up payment information**
  - [ ] App Store Connect → Agreements, Tax, and Banking
  - [ ] Complete tax forms (W-9 with wife's SSN)
  - [ ] Add wife's bank account for revenue deposits
  - [ ] Accept paid app agreement

---

### Google Play Console

- [ ] **Wife: Create Google account** (if doesn't exist)
  - Use grayprogrammer007@gmail.com
  - Strong password + 2FA

- [ ] **Wife: Register as Google Play developer**
  - [ ] Go to play.google.com/console/signup
  - [ ] Choose "Individual" account type
  - [ ] Fill personal information (wife's full legal name)
  - [ ] Pay $25 one-time registration fee (wife's debit card)
  - [ ] Complete identity verification
  - [ ] Save receipt for taxes

- [ ] **Wife: Set up merchant account**
  - [ ] Google Play Console → Settings → Payment profile
  - [ ] Complete tax forms (W-9 with wife's SSN)
  - [ ] Add wife's bank account for revenue deposits
  - [ ] Verify bank account (micro-deposits)

---

## Week 3: GitHub & Code Repository

### GitHub Account Transfer

- [ ] **Wife: Create GitHub account**
  - [ ] Go to github.com
  - [ ] Sign up with grayprogrammer007@gmail.com
  - [ ] Free account is fine (or Pro for $4/month)
  - [ ] Set up 2FA

- [ ] **Husband: Transfer repository ownership**

  **Option A: Transfer existing repo (keeps git history)**
  - [ ] Go to github.com/[username]/TravelCompanion
  - [ ] Settings → Transfer ownership
  - [ ] Enter wife's GitHub username
  - [ ] Confirm transfer

  **Option B: Create fresh repo (clean history)**
  - [ ] Wife creates new repo: TravelCompanion
  - [ ] Husband pushes code to wife's repo
  - [ ] Old repo deleted

  **Recommended:** Option B (fresh start, no trace to old account)

- [ ] **Wife: Update local git config**
  ```bash
  cd /Users/vinothvs/Development/TravelCompanion

  # Update remote URL
  git remote set-url origin https://github.com/[wife-username]/TravelCompanion.git

  # Set user config for this repo
  git config user.name "Wife's Full Name"
  git config user.email "grayprogrammer007@gmail.com"

  # Push to new repo
  git push -u origin main
  ```

---

## Week 4: API Keys & Cloud Services

### Google Cloud Platform

- [ ] **Wife: Create GCP account**
  - [ ] Go to console.cloud.google.com
  - [ ] Sign in with grayprogrammer007@gmail.com
  - [ ] Accept terms of service

- [ ] **Wife: Create new project**
  - [ ] Name: TravelCompanion
  - [ ] Note down Project ID

- [ ] **Husband: Export API keys** (reference only)
  - Document which APIs are currently enabled:
    - [ ] Maps SDK for Android
    - [ ] Maps SDK for iOS
    - [ ] Places API
    - [ ] Geocoding API

- [ ] **Wife: Enable APIs and create new keys**
  - [ ] Enable Maps SDK for Android
  - [ ] Enable Maps SDK for iOS
  - [ ] Enable Places API
  - [ ] Enable Geocoding API
  - [ ] Create API keys (separate for iOS and Android)
  - [ ] Set up API key restrictions (bundle ID, package name)
  - [ ] Save keys securely

- [ ] **Wife: Set up billing**
  - [ ] Add wife's credit card
  - [ ] Set up billing alerts ($50, $100, $200)
  - [ ] Review pricing to understand costs

- [ ] **Update code with new API keys**
  - [ ] Update `android/app/src/main/AndroidManifest.xml`
  - [ ] Update `ios/Runner/AppDelegate.swift`
  - [ ] Update `.env` file
  - [ ] Test maps functionality

---

### Anthropic Claude API

- [ ] **Wife: Create Anthropic account**
  - [ ] Go to console.anthropic.com
  - [ ] Sign up with grayprogrammer007@gmail.com
  - [ ] Verify email

- [ ] **Wife: Set up billing**
  - [ ] Add wife's credit card
  - [ ] Add initial credits ($50-100)
  - [ ] Set up usage alerts

- [ ] **Wife: Create API key**
  - [ ] Console → API Keys → Create Key
  - [ ] Name: TravelCompanion Production
  - [ ] Copy and save securely
  - [ ] Update `.env` file with new key
  - [ ] Test AI trip wizard functionality

---

### Supabase

- [ ] **Wife: Create Supabase account**
  - [ ] Go to supabase.com
  - [ ] Sign up with grayprogrammer007@gmail.com
  - [ ] Verify email

- [ ] **Husband: Export database** (for migration)
  - [ ] Supabase Dashboard → Database → Backups
  - [ ] Create manual backup
  - [ ] Download SQL dump

- [ ] **Wife: Create new Supabase project**
  - [ ] Project name: TravelCompanion
  - [ ] Choose region (closest to target users)
  - [ ] Strong database password
  - [ ] Note down project URL and keys

- [ ] **Wife: Import database**
  - [ ] SQL Editor → Upload SQL file
  - [ ] Run migrations from `supabase/migrations/`
  - [ ] Verify all tables created

- [ ] **Wife: Set up billing**
  - [ ] Choose plan: Free (0-500MB) OR Pro ($25/month)
  - [ ] Add wife's credit card if choosing Pro
  - [ ] Set up usage alerts

- [ ] **Update code with new Supabase credentials**
  - [ ] Update `.env` file
  - [ ] Test authentication
  - [ ] Test database queries
  - [ ] Test real-time subscriptions

---

### Firebase

- [ ] **Wife: Create Firebase project**
  - [ ] Go to console.firebase.google.com
  - [ ] Sign in with grayprogrammer007@gmail.com
  - [ ] Add project: TravelCompanion
  - [ ] Disable Google Analytics (optional)

- [ ] **Wife: Add iOS app**
  - [ ] iOS bundle ID: com.pathio.travel
  - [ ] Download GoogleService-Info.plist
  - [ ] Replace in `ios/Runner/`

- [ ] **Wife: Add Android app**
  - [ ] Android package: com.pathio.travel
  - [ ] Download google-services.json
  - [ ] Replace in `android/app/`

- [ ] **Wife: Enable Firebase services**
  - [ ] Cloud Messaging (push notifications)
  - [ ] Crashlytics (crash reporting)
  - [ ] Analytics (if desired)

- [ ] **Wife: Set up billing** (if needed)
  - Firebase has generous free tier
  - Add credit card only if expecting high usage

- [ ] **Test push notifications**
  - Send test notification from Firebase Console
  - Verify received on iOS and Android

---

## Week 5: Documentation & Final Setup

### Update App Configuration

- [ ] **Update app metadata**
  - [ ] `pubspec.yaml` - Verify app name, version
  - [ ] `android/app/build.gradle` - Verify package name
  - [ ] `ios/Runner/Info.plist` - Verify bundle ID

- [ ] **Update privacy policy**
  - [ ] Create privacy policy URL
  - [ ] Update links in app
  - [ ] Required for App Store and Google Play

- [ ] **Create app store assets**
  - [ ] App icon (1024x1024)
  - [ ] Screenshots (iPhone, iPad, Android)
  - [ ] App description
  - [ ] Keywords for ASO (App Store Optimization)

---

### Tax & Legal Setup

- [ ] **Wife: Understand tax obligations**
  - [ ] Read IRS Schedule C guide
  - [ ] Understand quarterly estimated taxes (if revenue >$1,000/quarter)
  - [ ] Set up spreadsheet for income/expense tracking

- [ ] **Wife: Create business expense tracking system**
  - Simple spreadsheet with columns:
    - Date
    - Vendor (Claude, GitHub, Google, etc.)
    - Category (Subscriptions, Tools, Fees)
    - Amount
    - Payment method
    - Receipt/Invoice #
    - Notes

- [ ] **Wife: Organize receipts**
  - [ ] Create folder: `~/Documents/TravelCompanion_Business/Receipts/`
  - [ ] Save all subscription receipts
  - [ ] Save developer account receipts
  - [ ] Keep for 7 years (IRS requirement)

---

## Week 6: Testing & Verification

### Test All Functionality

- [ ] **Test AI Trip Wizard**
  - [ ] Voice input (English, Tamil, Hindi)
  - [ ] Trip creation
  - [ ] Itinerary generation
  - [ ] Packing list generation

- [ ] **Test trip management**
  - [ ] Create trip
  - [ ] Edit trip
  - [ ] Delete trip
  - [ ] Add members
  - [ ] Pull-to-refresh

- [ ] **Test expenses**
  - [ ] Add expense
  - [ ] Split expense
  - [ ] View expense summary
  - [ ] Multi-currency support

- [ ] **Test checklists**
  - [ ] Create checklist
  - [ ] Smart packing list
  - [ ] Mark items complete
  - [ ] Edit checklist

- [ ] **Test profile**
  - [ ] Upload profile photo
  - [ ] Update name
  - [ ] Change settings

- [ ] **Test authentication**
  - [ ] Sign up
  - [ ] Login
  - [ ] Logout
  - [ ] Password reset

---

### Verify All Accounts

- [ ] **Claude Code**
  - [ ] Login successful with wife's email
  - [ ] Context preserved
  - [ ] Can use all features

- [ ] **GitHub**
  - [ ] Repository under wife's account
  - [ ] Can push/pull code
  - [ ] Actions/CI working (if set up)

- [ ] **Google Cloud**
  - [ ] Maps working on iOS
  - [ ] Maps working on Android
  - [ ] Places autocomplete working
  - [ ] Billing account active

- [ ] **Anthropic**
  - [ ] API key working
  - [ ] AI responses generating
  - [ ] Credits/billing set up

- [ ] **Supabase**
  - [ ] Database queries working
  - [ ] Authentication working
  - [ ] Real-time working
  - [ ] Storage working (profile photos)

- [ ] **Firebase**
  - [ ] Push notifications working
  - [ ] Crashlytics reporting (if enabled)

---

## Ongoing: Monthly Maintenance

### Every Month

- [ ] **Husband: Send monthly support**
  - [ ] Transfer $500 on 1st of month
  - [ ] Memo: "Support for [Wife's Name]"
  - [ ] Keep transfer confirmation

- [ ] **Wife: Pay business expenses**
  - [ ] Claude Code: $20
  - [ ] GitHub Pro: $4 (optional)
  - [ ] Google Places API: $20-50 (usage-based)
  - [ ] Supabase: $25 (if on Pro plan)
  - [ ] Other services as needed

- [ ] **Wife: Track income & expenses**
  - [ ] Update spreadsheet
  - [ ] File receipts
  - [ ] Calculate running total

- [ ] **Wife: Review usage & costs**
  - [ ] Check Google Cloud Platform billing
  - [ ] Check Anthropic usage
  - [ ] Check Supabase usage
  - [ ] Optimize if costs increasing

---

## Tax Season (April Each Year)

### Wife's Tax Filing

- [ ] **Gather documents**
  - [ ] All receipts from past year
  - [ ] Revenue statements (Apple, Google)
  - [ ] Expense spreadsheet
  - [ ] Bank statements

- [ ] **Prepare Schedule C**
  - [ ] Business name: TravelCompanion
  - [ ] Principal business code: 511210 (Software Publishers)
  - [ ] Business address: Home address
  - [ ] Income: Total from Apple + Google
  - [ ] Expenses: All business expenses
  - [ ] Net profit/loss: Income - Expenses

- [ ] **File Form 1040**
  - [ ] Attach Schedule C
  - [ ] Use tax software (TurboTax Self-Employed) OR hire accountant
  - [ ] Pay self-employment tax if profit >$400

- [ ] **Pay quarterly estimated taxes** (if required)
  - If business profit >$1,000/year, must pay quarterly
  - Due dates: Apr 15, Jun 15, Sep 15, Jan 15

---

### Husband's Tax Filing

- [ ] **File Form 1040**
  - [ ] Include W-2 from employer ONLY
  - [ ] Standard deduction
  - [ ] NO Schedule C
  - [ ] NO business mention
  - [ ] DO NOT deduct spousal support

---

## Emergency Contacts & Resources

### If You Need Help

**Claude Code Support:**
- Email: support@anthropic.com
- Documentation: docs.anthropic.com

**GitHub Support:**
- Help: support.github.com

**Google Cloud Support:**
- Console: console.cloud.google.com/support

**Tax Questions:**
- IRS: irs.gov or 1-800-829-1040
- Tax professional: Find local CPA

**USCIS Questions:**
- Immigration attorney: Find local immigration lawyer
- USCIS: uscis.gov or 1-800-375-5283

---

## Checklist Summary

**Total Tasks:** ~150
**Estimated Time:** 6 weeks (part-time)
**Critical Path:**
1. Week 1: Banking + Claude Code (must do first)
2. Week 2-4: Developer accounts + APIs (can do in parallel)
3. Week 5-6: Testing + verification (do last)

**Current Status:** 0% complete

**Next Step:** Wife opens bank account! 🏦

---

## Progress Tracking

Update this section as you complete items:

**Week 1:** ☐ Not started / ⏳ In progress / ✅ Complete
**Week 2:** ☐ Not started / ⏳ In progress / ✅ Complete
**Week 3:** ☐ Not started / ⏳ In progress / ✅ Complete
**Week 4:** ☐ Not started / ⏳ In progress / ✅ Complete
**Week 5:** ☐ Not started / ⏳ In progress / ✅ Complete
**Week 6:** ☐ Not started / ⏳ In progress / ✅ Complete

**Overall Progress:** [          ] 0%

---

**Good luck with the transfer! You've got this! 🚀**
