# Genixo Mobile (Capacitor Wrapper)

This folder contains an iOS/Android Capacitor shell that loads the existing hosted Rails/Inertia app in a native WebView.

## Current approach

- No frontend rewrite
- No API rewrite
- The native app loads the hosted URL configured in `capacitor.config.ts`

Default remote URL:

- `https://genixo-restoration-eff44db79cc1.herokuapp.com`

Override it for local runs:

```bash
GENIXO_MOBILE_WEB_URL="https://your-domain.example" npm run cap:sync
```

## iOS-first setup

1. Install dependencies:

```bash
cd mobile
npm install
```

2. Generate the iOS project (first time only):

```bash
npm run cap:add:ios
```

3. Sync config/web assets:

```bash
npm run cap:sync
```

4. Open in Xcode:

```bash
npm run ios:open
```

5. In Xcode:
- choose a simulator or connected iPhone
- run the `App` target

## Android (optional next step)

The package already includes `@capacitor/android`, so you can also generate Android later:

```bash
npm run cap:add:android
npm run cap:sync
npm run android:open
```

## Notes / constraints

- This uses `server.url` to load remote content. Capacitor docs describe `server.url` as a live-reload-oriented setting and not intended for production app-store releases. For internal/beta testing with a small set of companies, this is acceptable for initial validation.
- Web deploys update the app UI immediately because the shell loads the hosted site.
- Native app updates are only required for native-shell changes (deep links, push, icons, camera plugin, etc.).

## Next steps (after shell validation)

- Deep links (Universal Links / App Links) for invite emails
- TestFlight distribution
- Camera plugin fallback if WebView file/camera capture is unreliable on iOS
