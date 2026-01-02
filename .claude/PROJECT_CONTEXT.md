# TravelCompanion - Quick Context Reference for Claude Code

**Last Updated:** January 1, 2026
**Purpose:** Quick reference when Claude needs to recall project context

---

## 🚨 CRITICAL: USCIS Compliance (READ FIRST!)

### Business Owner
- **Legal Owner:** Wife (L2 + EAD) - grayprogrammer007@gmail.com
- **Husband's Role:** Personal financial support ONLY ($500/month spousal gifts)
- **Revenue:** 100% to wife's accounts (Apple/Google pay wife directly)
- **Expenses:** 100% paid by wife from HER accounts
- **Tax Filing:** Wife files Schedule C, husband files W-2 only

### USCIS Red Flags to AVOID
❌ Husband receiving business revenue
❌ Husband paying business expenses long-term
❌ Husband's name on business accounts
❌ Business registered under husband's name

### USCIS-Safe Practices
✅ Wife owns 100% of business
✅ Wife pays all expenses from her account
✅ Husband provides personal support (documented as spousal gifts)
✅ Clear financial separation

---

## 💰 Financial Structure

### Monthly Support
- **Amount:** $500/month from husband to wife
- **Legal Basis:** Spousal support / Personal gift (tax-free)
- **Transfer Label:** "Support for [Wife's Name]" (NOT "business expenses")
- **Wife's Usage:** Pay all business expenses from this money

### Subscriptions (All in Wife's Name)
| Service | Cost | Payment |
|---------|------|---------|
| Claude Code | $20/month | Wife's debit card |
| GitHub Pro | $4/month | Wife's debit card |
| Google Places API | $20-50/month | Wife's credit card |
| Apple Developer | $100/year | Wife's debit card |
| Supabase | $25/month | Wife's debit card |
| Anthropic Claude API | $50-100/month | Wife's credit card |

**Total:** ~$300-500/month (covered by husband's $500/month support)

---

## 🏦 Banking

**Wife's Account:**
- **Type:** Personal checking account (can be used for sole proprietor business)
- **Bank:** Chase / Bank of America / Wells Fargo
- **Cost:** FREE
- **Usage:** Wife pays ALL business expenses from this account

**Business Account:**
- **Required?** NO (not initially)
- **When?** Only if revenue exceeds $500/month

---

## 📱 Technical Stack

### Core
- **Frontend:** Flutter 3.x + Dart
- **State Management:** Riverpod
- **Backend:** Supabase (PostgreSQL + Realtime + Auth)
- **Push Notifications:** Firebase Cloud Messaging
- **AI:** Anthropic Claude API (trip planning, packing lists)
- **Maps:** Google Maps SDK + Places API

### Key Features
✅ AI Trip Wizard with voice input (English, Tamil, Hindi)
✅ Smart packing list generation (destination + itinerary aware)
✅ Expense tracking with split calculations
✅ Multi-member trip collaboration
✅ Day-by-day itinerary management
✅ Real-time updates via Supabase

---

## 🛠️ Recent Development Work

### AI Trip Wizard Error Fix (Completed)
**File:** [ai_trip_wizard_page.dart:623-737](lib/features/trips/presentation/pages/ai_trip_wizard_page.dart#L623-L737)
- Added `.trim()` validation for all titles
- Individual try-catch blocks for each item
- Partial success pattern (skip bad items, continue processing)
- User-friendly error messages

### Tamil Language Support (Completed)
**File:** [ai_trip_wizard_page.dart:47-53, 193-209, 916-956](lib/features/trips/presentation/pages/ai_trip_wizard_page.dart)
- Language selector in app bar (English → தமிழ் → हिंदी)
- Explicit locale selection (`en_IN`, `ta_IN`, `hi_IN`)
- Visual indicators with native script

### Smart Packing Lists (Completed)
**Files:**
- [smart_checklist_generator.dart](lib/features/checklists/data/smart_checklist_generator.dart)
- [packing_templates.dart](lib/features/checklists/data/packing_templates.dart)
- [add_checklist_page.dart](lib/features/checklists/presentation/pages/add_checklist_page.dart)

**Features:**
- Destination-aware (beach, mountain, city)
- Itinerary-aware (hiking boots if trek planned)
- 12 pre-defined templates
- Category-based organization

---

## 📊 Project Status

**Current Stage:** Pre-launch development
- **Users:** 0 (app not yet published)
- **Revenue:** $0
- **App Store:** Not yet submitted
- **Google Play:** Not yet submitted

**Next Steps:**
1. Wife takes over accounts (Week 1)
2. Final testing (Week 2-3)
3. Submit to stores (Week 4)
4. Launch (Week 7) 🚀

---

## 🎯 Critical Files

### AI & Trip Planning
- [ai_trip_wizard_page.dart](lib/features/trips/presentation/pages/ai_trip_wizard_page.dart) - Voice trip creation
- [smart_checklist_generator.dart](lib/features/checklists/data/smart_checklist_generator.dart) - Packing lists

### Trip Management
- [trip_detail_page.dart](lib/features/trips/presentation/pages/trip_detail_page.dart) - Trip details
- [home_page.dart](lib/features/trips/presentation/pages/home_page.dart) - Trip list
- [trip_providers.dart](lib/features/trips/presentation/providers/trip_providers.dart) - State management

### Database
- `supabase/migrations/` - All database schema

---

## 📝 Conversation Context

### Full Context Location
- **Detailed Context:** [CLAUDE_CONTEXT.md](../CLAUDE_CONTEXT.md) (read for complete history)
- **Conversation Backup:** `~/Documents/TravelCompanion_Claude_Conversation_Backup.txt`
- **Local Storage:** `/Users/vinothvs/Development/TravelCompanion/.claude/conversation_history/`

### Key Discussion Topics
1. ✅ AI Trip Wizard error fix
2. ✅ Trip type coverage analysis (73% average)
3. ✅ Location sharing feature design (planned)
4. ✅ USCIS compliance for L1B/L2 visa holders
5. ✅ Banking structure (wife's account, husband's $500/month support)
6. ✅ Subscription ownership (all in wife's name)
7. ✅ Claude Code privacy (won't report to USCIS)
8. ✅ Monthly financial support (spousal gifts are legal and unlimited)
9. ✅ Context preservation during subscription transfer

---

## 🧪 Testing Context After Transfer

When wife logs into Claude Code, ask these questions to verify context:

1. **Business Context:** "What's the USCIS compliance structure for this project?"
   - Expected: L1B/L2 visa rules, wife ownership, husband support

2. **Banking:** "How much does my husband transfer to me monthly and why?"
   - Expected: $500/month personal support

3. **Code:** "Where did we fix the AI Trip Wizard validation error?"
   - Expected: ai_trip_wizard_page.dart lines 623-737

4. **Subscriptions:** "Who should pay for Claude Code subscription?"
   - Expected: Wife should pay from her account

**If all 4 correct:** ✅ Full context preserved!

---

## 💡 Quick Reminders for Wife

### Always Do
✅ Pay all business expenses from YOUR account
✅ Keep all receipts for tax deductions
✅ File Schedule C every year (even if $0 revenue)
✅ Track income and expenses monthly
✅ Set aside 20-30% of profit for taxes

### Never Do
❌ Let husband pay business expenses long-term
❌ Receive business revenue in husband's name
❌ Use husband's credit card for subscriptions
❌ Post on social media about husband owning business
❌ Create joint business bank accounts

---

## 🔗 Important Links

### Development
- **Supabase Dashboard:** https://supabase.com/dashboard
- **Firebase Console:** https://console.firebase.google.com
- **Google Cloud Console:** https://console.cloud.google.com
- **Anthropic Console:** https://console.anthropic.com

### Business
- **Apple Developer:** https://developer.apple.com
- **Google Play Console:** https://play.google.com/console
- **IRS Schedule C:** https://www.irs.gov/forms-pubs/about-schedule-c-form-1040

### Banking
- **Chase:** https://www.chase.com
- **Mercury:** https://mercury.com (free business account)
- **Novo:** https://novo.co (free business account)

---

## 📞 Emergency Context Recovery

If this context doesn't load automatically:

1. Read: [CLAUDE_CONTEXT.md](../CLAUDE_CONTEXT.md) (comprehensive context)
2. Read: `~/Documents/TravelCompanion_Claude_Conversation_Backup.txt` (full conversation)
3. Ask wife to summarize recent work
4. Claude will rebuild context in 10-15 minutes

---

**Quick Start Message for Wife:**

When you first log into Claude Code, say:

> "I'm taking over this TravelCompanion project from my husband. Please read CLAUDE_CONTEXT.md to understand the complete business structure, USCIS compliance requirements, and recent development work. I'm the sole business owner (L2 + EAD), and my husband provides $500/month personal support."

---

**END OF PROJECT_CONTEXT.MD**
