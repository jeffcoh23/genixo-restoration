# TestFlight MVP Launch Checklist

This is the minimum path to get the Genixo mobile shell onto testers' iPhones.

## What is already in place (repo)

- Capacitor iOS shell (`mobile/ios`)
- Remote WebView loading the hosted Genixo app (`server.url`)
- iOS camera/photo permission strings in `Info.plist`
- Branded app icon + splash assets

## What is manual (Apple account / Xcode)

- Apple Developer account membership (paid)
- Xcode signing team selection
- App Store Connect app record
- Archive/upload/TestFlight distribution

## 1. Preflight (local)

From repo root:

```bash
cd mobile
npm install
npm run assets:brand
npm run cap:sync
```

Notes:
- `cap:sync` updates config/web assets and plugins.
- It should not replace your custom icons/splash images.

## 2. Xcode project setup (first time)

Open Xcode:

```bash
npm run ios:open
```

In Xcode (`App` target):

1. `Signing & Capabilities`
2. Check `Automatically manage signing`
3. Select your Apple Team
4. Confirm or change bundle identifier to a unique value
   - Example: `com.jeffcohen.genixo-restoration`

## 3. Build and device test (required before upload)

Test on:
- iOS Simulator (fast UI checks)
- at least one real iPhone (camera/uploads/permissions)

Smoke test:

1. Launch app
2. Login
3. Open incident
4. Send message
5. Upload photo from library
6. Try camera photo capture
7. Upload document
8. Change incident status
9. Close/reopen app (session persists)
10. Logout

## 4. App Store Connect app record

In App Store Connect:

1. Create new app
2. Platform: `iOS`
3. Name: `Genixo Restoration`
4. Primary language
5. Bundle ID: must match Xcode target bundle ID
6. SKU: any internal identifier (e.g. `genixo-ios-001`)

## 5. Version/build numbers (Xcode)

In Xcode `General` tab for `App` target:

- `Version` (marketing version), e.g. `1.0.0`
- `Build`, increment each upload (`1`, `2`, `3`, ...)

## 6. Archive and upload

1. In Xcode, select `Any iOS Device (arm64)` (or generic iOS device)
2. `Product` -> `Archive`
3. In Organizer -> `Distribute App`
4. Choose `App Store Connect`
5. Choose `Upload`
6. Complete upload flow

## 7. TestFlight distribution options

### Internal Testing (fastest)

- Add internal testers (App Store Connect users)
- No public link
- Fastest turnaround

### External Testing (shareable link)

- Create external testing group
- Add beta app info/contact details
- Submit first build for Beta App Review
- After approval, enable **Public Link**

This is the path for a shareable install link to companies.

## 8. Known current limitation (expected)

Universal Links / invite deep links are **not implemented yet**.

Current behavior:
- Users install app via TestFlight
- App opens the hosted Genixo web app in a native shell
- Invite links still open in browser until deep links are added

## 9. Post-upload checklist

- Verify app icon and splash look correct on device
- Verify permission prompts use correct text (Camera / Photos)
- Verify no white-screen on cold launch (network available)
- Verify production URL loads inside app

