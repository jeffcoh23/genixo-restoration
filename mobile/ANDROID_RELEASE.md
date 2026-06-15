# Android Release Checklist (Google Play closed testing)

End-to-end path from "code is ready" to "testers install from Play Store".

## Repo state (already done in `feature/android-camera-downloads`)

- Capacitor shell points at `https://genixorestoration.com`
- In-WebView camera capture + DownloadManager wired in `MainActivity`
- Release signing config in `app/build.gradle` (reads `keystore.properties`)
- Android App Links `intent-filter` in `AndroidManifest.xml`
- Rails serves `/.well-known/assetlinks.json` (driven by `ANDROID_APP_LINKS_SHA256` env var)
- `*.jks`, `keystore.properties`, `android/keystore/` gitignored

## What's still manual (you do this part)

### 1. Pivot Play Console to org account (DUNS)

Google does NOT allow converting a personal account to org. Path:

1. In your existing personal Play Console: don't publish anything yet.
2. Visit https://play.google.com/console/signup, choose **Organization**, pay $25 again.
3. Enter DUNS number — Google verifies via D&B contact (email/phone on file at dnb.com).
   - If contact is stale, fix at https://www.dnb.com/duns-number/lookup.html first.
4. Wait 1–14 days for verification.
5. Once verified, abandon the personal account (or use it for unrelated test apps).

Why org: skips the 12-tester / 14-day production gate, looks legit to PM clients,
matches Apple side.

### 2. Generate the upload keystore (LOCAL — ONE TIME)

From `mobile/`:

```bash
./scripts/generate-android-keystore.sh
```

You'll be prompted for a password — use the same one for keystore and key.

**Immediately after:**

1. Add `mobile/android/keystore/genixo-upload.jks` to 1Password (attach the file).
2. Add the password to 1Password.
3. Copy `mobile/android/keystore.properties.example` → `mobile/android/keystore.properties`,
   fill in `storePassword` and `keyPassword`.

### 3. Capture the SHA-256 fingerprint

```bash
keytool -list -v \
  -keystore mobile/android/keystore/genixo-upload.jks \
  -alias genixo-upload
```

Copy the `SHA256:` line (looks like `AB:CD:EF:...`). Hand this to Claude — it goes
into the Heroku env var `ANDROID_APP_LINKS_SHA256` so the assetlinks JSON serves it.

### 4. Build the signed AAB

```bash
cd mobile
npm run cap:sync
cd android
./gradlew bundleRelease
```

Output: `mobile/android/app/build/outputs/bundle/release/app-release.aab`

### 5. Create the Play Console app listing

In the org-verified Play Console:

1. **Create app** → name "Genixo Restoration", default language English (US),
   app or game = App, free/paid = Free.
2. **App content** forms (all required):
   - Privacy policy URL: `https://genixorestoration.com/privacy`
   - App access (login required) — provide a test login (create a Play-only test user
     in Genixo so reviewers can sign in)
   - Ads = No
   - Content rating = take the IARC questionnaire (productivity, no adult content)
   - Target audience = 18+
   - Data safety form — declare: account info (email), photos (user-provided),
     location if you collect it, encrypted in transit, not sold
   - News app = No
   - Government app = No
3. **Store listing**:
   - Short description (80 chars)
   - Full description (4000 chars)
   - App icon 512×512 PNG (already in `mobile/assets/source/`)
   - Feature graphic 1024×500 PNG (NEEDS TO BE CREATED — Claude can draft)
   - Phone screenshots ×2+ (take from a real Android phone running the closed test)

### 6. Enroll in Play App Signing & upload the AAB

1. **Testing → Closed testing → Create track** → name "alpha" or "internal-pilot".
2. **Releases → Create new release** → upload `app-release.aab`.
3. Play Console prompts to enroll in Play App Signing — accept.
4. Once uploaded, go to **Setup → App integrity → App signing**.
5. Copy the **App signing key certificate SHA-256**. This is Google's key (different
   from your upload key).
6. Hand it to Claude — append it to `ANDROID_APP_LINKS_SHA256` on Heroku so both
   the upload key AND Play's app signing key appear in `assetlinks.json`. Required
   for App Links verification to keep working post-launch.

### 7. Add testers + share install link

1. In the closed track, add a tester email list (or Google Group).
2. Copy the **opt-in URL** (looks like `https://play.google.com/apps/internaltest/...`).
3. Send it to testers. They open on Android, accept, install from Play Store.

### 8. Heroku env var

Set on production:

```bash
heroku config:set ANDROID_APP_LINKS_SHA256="AB:CD:EF:...,12:34:56:..." -a genixo-restoration
```

Comma-separate the upload key fingerprint and Play's app signing fingerprint once
both exist. Verify by hitting:

```bash
curl https://genixorestoration.com/.well-known/assetlinks.json
```

### 9. Verify App Links

After install, on Android phone:

```bash
adb shell pm get-app-links com.genixo.restoration
```

Look for `verified` status on `genixorestoration.com`. If `none`, the assetlinks
JSON is wrong or unreachable.

## Bumping versions later

Every Play Console upload needs a higher `versionCode` than the previous one:

```gradle
// mobile/android/app/build.gradle
versionCode 2          // bump this
versionName "1.0.1"    // human-readable
```

## What can go wrong

- **App Links not verifying** → check assetlinks JSON returns `application/json`,
  no redirect, SHA-256 has colons and uppercase hex.
- **AAB rejected at upload** → versionCode collision (you already uploaded this number).
- **Beta review rejected** → usually missing data safety or privacy policy disclosure.
- **Login broken in WebView** → cookies need `SameSite=Lax` + `Secure`; already set in Rails 8 default.
