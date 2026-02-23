# Capacitor Mobile App Checklist (Rails + Inertia + React)

## Goal

Ship a mobile app wrapper for the existing Genixo web app (Rails + Inertia + React) so invite/signup emails can include an app link.

This plan assumes:

- We are **not** doing PWA.
- We want the fastest path to a usable mobile app.
- A **shareable public/beta link** is acceptable (not necessarily full App Store production approval on day one).

## Recommendation

Use **Capacitor** as a native shell around the hosted web app.

- Keep Rails as the backend and page renderer.
- Load the production/staging web app URL inside Capacitor WebView.
- Add deep links so invite links open in the app when installed.
- Use beta distribution links first (TestFlight / Android testing links).

## Reality Check: App Store Approval vs Public Link

### iOS

- If you want a shareable iPhone app link, the practical path is **TestFlight public link**.
- TestFlight external testing **still requires Apple beta app review** (lighter than full App Store review, but still a review).
- If Apple rejects a thin wrapper, add more native/mobile polish (camera integration, push, better offline/loading UX).

### Android

- Much easier to distribute:
- Options include **Google Play closed testing link**, **Internal App Sharing**, or **Firebase App Distribution**.

### If you truly want "no review"

- iOS has no general public install path without Apple review.
- Apple Enterprise distribution is for internal employees, not customer companies (do not use it for client distribution).

## Architecture Decision (Important)

Use Capacitor in **remote URL mode** (WebView loads hosted app), not bundled SPA-only mode.

Why:

- Your app depends on Rails routes/controllers/Inertia responses.
- Bundling frontend assets alone does not replace the Rails app.

## Phase 1: Build a Working Mobile Shell

### 1. Create a Mobile Wrapper Folder

Recommended structure:

- `mobile/` (new folder for Capacitor app)

This keeps native project files out of the Rails root.

### 2. Initialize Capacitor

Example commands (run inside `mobile/`):

```bash
npm init -y
npm install @capacitor/core @capacitor/cli
npx cap init GenixoRestoration com.genixo.restoration
npm install @capacitor/ios @capacitor/android
npx cap add ios
npx cap add android
```

### 3. Configure Capacitor to Load Hosted App

Create/update `mobile/capacitor.config.ts`:

```ts
import type { CapacitorConfig } from "@capacitor/cli";

const config: CapacitorConfig = {
  appId: "com.genixo.restoration",
  appName: "Genixo Restoration",
  webDir: "www",
  server: {
    url: "https://YOUR_APP_DOMAIN",
    cleartext: false
  }
};

export default config;
```

Notes:

- Use your real production domain (or staging while testing).
- `https` is required for stable cookies and deep links.

### 4. Open Native Projects

```bash
npx cap open ios
npx cap open android
```

## Phase 2: Make the Rails App Mobile-Safe

### 5. Verify Session Auth Works in WebView

Test on real devices/simulators:

- Login
- App restart (session persists)
- Logout
- Form submissions (CSRF)
- File uploads (documents/photos/messages)

If issues appear, check:

- cookie domain
- `Secure` cookies over `https`
- same-site behavior during login redirects

### 6. Safe Area + Keyboard Polish (Web App UI)

Update the web UI (Rails/Inertia app) so it behaves in mobile WebView:

- respect `safe-area-inset-*` for bottom/top spacing
- ensure message composer is not hidden behind keyboard
- verify modals/dialogs fit small screens
- verify camera/photo dialogs on mobile viewport

Areas to validate carefully:

- `Messages` composer
- `Take Photos` dialog
- `Daily Log` forms
- `Manage` tab lists

### 7. External Link Handling

Decide which links should open outside the app browser:

- PDFs / downloads
- external websites
- mailto/tel links

Implement in Capacitor shell (native side) if needed.

## Phase 3: Deep Links for Invite Emails

### 8. Keep Invite URLs Stable

Use your existing invite URL path (example):

- `/invitations/accept/:token`

Do not create separate mobile invite tokens unless necessary.

### 9. Add Apple Universal Links Support (Rails)

Serve `/.well-known/apple-app-site-association` from Rails.

Checklist:

- Add route for `/.well-known/apple-app-site-association`
- Return JSON with `application/json` (no `.json` extension in URL)
- Include your app bundle identifier and allowed paths (invite path at minimum)

### 10. Add Android App Links Support (Rails)

Serve `/.well-known/assetlinks.json` from Rails.

Checklist:

- Add route for `/.well-known/assetlinks.json`
- Include package name and SHA-256 signing certificate fingerprint(s)
- Include both debug/test and release fingerprints as needed for environments

### 11. Configure iOS App for Universal Links

In Xcode (`ios/` project):

- Enable Associated Domains capability
- Add:

```txt
applinks:YOUR_APP_DOMAIN
```

### 12. Configure Android App for App Links

In Android manifest:

- Add `intent-filter` for `https://YOUR_APP_DOMAIN`
- Include invite path handling (or broad app paths)
- Enable auto verification where appropriate

### 13. Handle Incoming App Links in Capacitor

When app opens from a deep link:

- capture the URL in native shell / Capacitor listener
- route/load that exact URL in the WebView

Goal:

- Invite email link opens directly to invite accept page in-app
- If app is not installed, same link still opens the web page

## Phase 4: Email Changes (Invite / Signup)

### 14. Update Invitation Emails

In Rails mailers/templates:

- Add `Open in App` button (same HTTPS invite URL)
- Add `Open in Browser` button (same URL or explicit web path)
- Add optional store/beta download links:
  - TestFlight public link (iOS)
  - Android testing link

Recommended order:

1. Open in App
2. Open in Browser
3. Install iPhone App
4. Install Android App

### 15. Add a "Mobile App" Help/Install Page (Optional but Useful)

Create a simple page with:

- iOS beta link
- Android beta link
- troubleshooting steps
- "If the app does not open, use browser" fallback

Good URL to share in onboarding docs and email footers.

## Phase 5: Camera and Upload Reliability

### 16. Test Existing HTML File Inputs First (No Plugin Yet)

Your app already supports:

- photo uploads
- message attachments
- camera input (`capture="environment"`)

Validate on real devices inside the app shell:

- single photo capture
- multiple gallery uploads
- message photo attach
- large photo compression/upload success

### 17. Add Capacitor Camera Plugin Only If Needed

If WebView camera/file input is unreliable on target devices:

```bash
cd mobile
npm install @capacitor/camera
npx cap sync
```

Then integrate with the web app via one of these approaches:

- native plugin returns file(s) -> inject into web app upload flow
- custom bridge that posts images to current Rails endpoints

Do this only after testing the existing HTML approach.

## Phase 6: Distribution (Public Link Beta First)

### 18. iOS Distribution (Recommended: TestFlight Public Link)

Checklist:

- Apple Developer account
- App icon/splash assets
- Privacy Policy URL
- Build in Xcode
- Upload via Xcode / Transporter
- App Store Connect app setup
- TestFlight external testing enabled
- Create public TestFlight link

Note:

- Apple beta review is still required for external testers.

### 19. Android Distribution (Recommended: Closed Testing Link)

Checklist:

- Google Play Developer account
- App signing config
- App listing basics (can be minimal for closed test)
- Upload build to closed testing track
- Create shareable tester link

Alternative:

- Firebase App Distribution for faster internal rollouts

## Phase 7: QA Checklist (Must Pass Before Sending Links in Emails)

### 20. Deep Link QA

- Invite link opens app when installed
- Invite link opens browser when app not installed
- Invite link works from:
  - Apple Mail
  - Gmail app
  - desktop email clients

### 21. Auth QA

- Login works
- Session persists across app relaunch
- Logout works
- Password reset links work
- Invitation accept flow works in-app and in-browser

### 22. Workflow QA (Real Devices)

- Create incident
- Send message
- Attach file to message
- Upload photos
- Take photos
- Daily log entry creation
- Status transition

### 23. Failure QA

- Network offline / poor connection behavior
- Upload failure message clarity
- Session expiration behavior
- 404/unauthorized behavior inside app shell

## Phase 8: Optional but High-Value Mobile Upgrades (After Beta)

### 24. Push Notifications

Add later if beta usage is good:

- Capacitor Push Notifications plugin
- APNs + FCM setup
- Device token registration endpoint in Rails
- Notification routing from existing jobs

### 25. Native Camera / Better Upload UX

If field technicians use mobile heavily:

- native camera capture
- batch uploads with retry
- background upload improvements

### 26. App Store Production Launch (Optional)

If you later want public store listing:

- add more native polish/value
- improve offline/loading UX
- complete privacy disclosures
- App Store review hardening

## Exact Repo Changes Checklist (This Project)

### Rails app (`genixo-restoration`)

- [ ] Add routes/controllers for:
  - [ ] `/.well-known/apple-app-site-association`
  - [ ] `/.well-known/assetlinks.json`
- [ ] Add app install/help page (optional)
- [ ] Update invitation email templates with app/beta links
- [ ] Verify session/cookie settings on production domain in WebView
- [ ] QA deep-link invite flow end-to-end

### Mobile wrapper (`mobile/`)

- [ ] Initialize Capacitor app
- [ ] Add iOS + Android platforms
- [ ] Configure `server.url` to hosted app
- [ ] Configure deep links (iOS + Android)
- [ ] Test WebView auth/session persistence
- [ ] Validate uploads/camera inputs on real devices
- [ ] Prepare beta distributions (TestFlight + Android testing)

## Suggested Rollout Order (Fastest Path)

1. Build Capacitor shell loading staging site
2. Verify login/session/uploads on real devices
3. Add deep links + invite URL handling
4. Update invite emails with app/beta links
5. Ship TestFlight + Android testing links to pilot companies
6. Gather feedback
7. Add push notifications/native camera only if needed

## Go / No-Go for v1 Mobile Beta

Ship beta links when all are true:

- Deep links open invite flow correctly
- Login/session works reliably
- Photo/message/document uploads work on real devices
- No major keyboard/layout blockers
- Pilot users can install from shared links

