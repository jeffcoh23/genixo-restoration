# Mobile QA Checklist (MVP)

Use this before sharing the app with testers.

## Device coverage (minimum)

- 1 recent iPhone (real device)
- 1 Android phone (optional for first iOS TestFlight push)

## Core flow checks

1. Login and logout
2. Session persists after app restart
3. Incident list loads
4. Incident show page tabs work (`Daily Log`, `Messages`, `Photos`, etc.)
5. Flash messages are visible and readable
6. Status dropdown works

## Media checks

1. Upload photo from library
2. Camera capture path (if available in WebView)
3. Upload document
4. Message attachment upload
5. Permission denied fallback behavior (manual settings toggle test)

## UI checks

1. Safe-area spacing on notched devices (header not clipped)
2. Bottom content not hidden by home indicator
3. Sidebar drawer opens/closes on mobile
4. Keyboard does not fully cover message composer

## Failure checks

1. Put phone in Airplane Mode and launch app (reasonable failure behavior)
2. Toggle network during upload (user gets feedback, no crash)

