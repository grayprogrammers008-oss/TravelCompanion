# How to Create GitHub Issues - Step by Step Guide

## Quick Start (2 Steps)

### Step 1: Authenticate with GitHub

Open your terminal and run:

```bash
gh auth login
```

Then follow these steps:
1. Select: **GitHub.com**
2. Select: **HTTPS**
3. When asked "Authenticate Git with your GitHub credentials?": Select **Yes**
4. When asked "How would you like to authenticate?": Select **Login with a web browser**
5. Copy the **one-time code** shown (e.g., `7B81-268E`)
6. Press **Enter** to open the browser
7. Paste the one-time code in the browser
8. Click **Authorize**
9. You should see "✓ Authentication complete"

### Step 2: Run the Script

```bash
cd /Users/vinothvs/Development/TravelCompanion
./create_github_issues.sh
```

That's it! The script will:
- ✅ Create all 23 labels
- ✅ Create all 23 issues with detailed descriptions
- ✅ Assign issues to you and Nithya
- ✅ Add proper priority labels

---

## Alternative: Manual Authentication (if web browser doesn't work)

If the web browser authentication doesn't work, use token authentication:

### Step 1: Create a Personal Access Token

1. Go to: https://github.com/settings/tokens
2. Click **"Generate new token"** → **"Generate new token (classic)"**
3. Give it a name: `GitHub CLI for Travel Crew`
4. Select scopes:
   - ✅ **repo** (all)
   - ✅ **admin:org** → **read:org**
   - ✅ **project** (all)
5. Scroll down and click **"Generate token"**
6. **COPY THE TOKEN** (you won't see it again!)

### Step 2: Authenticate with Token

```bash
gh auth login
```

1. Select: **GitHub.com**
2. Select: **HTTPS**
3. When asked "Authenticate Git with your GitHub credentials?": Select **Yes**
4. When asked "How would you like to authenticate?": Select **Paste an authentication token**
5. Paste the token you copied
6. Press **Enter**
7. You should see "✓ Logged in as vinothvsbe"

### Step 3: Run the Script

```bash
cd /Users/vinothvs/Development/TravelCompanion
./create_github_issues.sh
```

---

## Troubleshooting

### Error: "gh: command not found"
The script already installed `gh` using Homebrew. If you still see this error, restart your terminal.

### Error: "permission denied"
Run: `chmod +x create_github_issues.sh`

### Error: "label already exists"
This is normal! The script will skip existing labels and continue.

### Error: "HTTP 401" or "authentication failed"
Your authentication expired. Run `gh auth login` again.

### Want to see what issues will be created?
Open the file: `GITHUB_ISSUES.md` to see all 23 issues with full descriptions.

---

## After Creating Issues

### View All Issues
Visit: https://github.com/vinothvsbe/TravelCompanion/issues

### Create a Project Board (Optional but Recommended)

1. Go to: https://github.com/vinothvsbe/TravelCompanion/projects
2. Click **"New project"**
3. Select **"Board"** template
4. Name it: **"Travel Crew MVP"**
5. Click **"Create"**
6. Click **"Add items"** and select all issues
7. Organize by priority:
   - **Todo**: All pending issues
   - **In Progress**: Issues being worked on
   - **Done**: Completed issues

### Filter Issues by Assignee

**Vinoth's Issues**:
https://github.com/vinothvsbe/TravelCompanion/issues?q=is%3Aissue+is%3Aopen+assignee%3Avinothvsbe

**Nithya's Issues**:
https://github.com/vinothvsbe/TravelCompanion/issues?q=is%3Aissue+is%3Aopen+assignee%3Anithya

(Replace `nithya` with Nithya's actual GitHub username)

### Filter by Priority

**High Priority**:
https://github.com/vinothvsbe/TravelCompanion/issues?q=is%3Aissue+is%3Aopen+label%3Apriority-high

**Medium Priority**:
https://github.com/vinothvsbe/TravelCompanion/issues?q=is%3Aissue+is%3Aopen+label%3Apriority-medium

---

## Issues Summary

### Priority High (6 issues - Week 1-2)
1. ✅ **#1** - Edit Trip Functionality (Vinoth)
2. ✅ **#2** - Real Destination Images (Nithya)
3. ✅ **#3** - Trip Detail Page (Vinoth)
4. ✅ **#4** - Trip Invite System (Nithya)
5. ✅ **#5** - Itinerary Feature (Vinoth)
6. ✅ **#6** - Checklist Feature (Nithya)

### Priority Medium (8 issues - Week 3-6)
7. ✅ **#7** - Payment Integration (Vinoth)
8. ✅ **#8** - Real-time Sync (Nithya)
9. ✅ **#9** - Claude AI Autopilot (Vinoth)
10. ✅ **#10** - Push Notifications (Nithya)
18. ✅ **#18** - UI Bug Fixes (Both)
19. ✅ **#19** - Error Messages (Nithya)
22. ✅ **#22** - CI/CD Pipeline (Vinoth)

### Priority Low (9 issues - Week 7-8 & Beyond)
11. ✅ **#11** - Deep Linking (Vinoth)
12. ✅ **#12** - Dark Mode (Nithya)
13. ✅ **#13** - Testing (Both)
14. ✅ **#14** - Performance (Nithya)
15. ✅ **#15** - Settings & Profile (Vinoth)
16. ✅ **#16** - Animations (Nithya)
17. ✅ **#17** - Onboarding (Vinoth)
20. ✅ **#20** - User Documentation (Vinoth)
21. ✅ **#21** - API Documentation (Nithya)
23. ✅ **#23** - App Store Listings (Nithya)

---

## Team Collaboration Tips

### For Vinoth:
- Focus on **Priority High** issues first (#1, #3, #5)
- Backend-heavy features (repositories, use cases)
- AI integration (#9)

### For Nithya:
- Focus on **Priority High** issues first (#2, #4, #6)
- UI/UX polish and animations
- Real-time sync and notifications (#8, #10)

### Daily Workflow:
1. Pull latest changes: `git pull origin main`
2. Create feature branch: `git checkout -b feature/issue-X-description`
3. Work on the issue
4. Commit changes: `git commit -m "feat: implement X (#IssueNumber)"`
5. Push branch: `git push origin feature/issue-X-description`
6. Create Pull Request on GitHub
7. Review each other's PRs
8. Merge to main after approval

### Communication:
- Comment on issues for questions
- Use GitHub Discussions for design decisions
- Tag each other with `@username` in comments
- Close issues when done with: `Closes #X` in commit message

---

## Need Help?

- **GitHub CLI Docs**: https://cli.github.com/manual/
- **Creating Issues**: https://docs.github.com/en/issues/tracking-your-work-with-issues/creating-an-issue
- **GitHub Projects**: https://docs.github.com/en/issues/planning-and-tracking-with-projects

---

**Ready to start?**

Run this in your terminal:

```bash
gh auth login
./create_github_issues.sh
```

Then check: https://github.com/vinothvsbe/TravelCompanion/issues

Happy coding! 🚀
