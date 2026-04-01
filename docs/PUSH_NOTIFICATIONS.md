# Push Notifications — FCM Implementation Plan

> Firebase Cloud Messaging (FCM) integration for the Genixo Restoration mobile app (Capacitor iOS/Android).

---

## Overview

Push notifications let field technicians and property managers receive real-time alerts on their phones — new incidents, status changes, messages, and escalations — without having the app open.

**Flow:** User opens app → requests push permission → gets device token from Apple/Google → token sent to Rails backend → notification jobs send pushes via FCM → FCM routes to APNs (iOS) or delivers directly (Android).

---

## Architecture

```
┌─────────────┐     ┌──────────────┐     ┌─────────┐     ┌──────────┐
│ Capacitor   │────▶│ Rails API    │────▶│ FCM API │────▶│ APNs /   │
│ App         │     │ (device      │     │         │     │ Android  │
│             │◀────│  tokens +    │     │         │     │          │
│ Push Plugin │     │  push jobs)  │     │         │     │          │
└─────────────┘     └──────────────┘     └─────────┘     └──────────┘
```

### Why FCM (not direct APNs)?

- Single API for both iOS and Android
- FCM handles APNs certificate management and token refresh
- Simpler backend — one HTTP endpoint instead of two platform-specific ones
- Industry standard for cross-platform push

---

## Backend (Rails)

### 1. Database — `device_tokens` table

```ruby
create_table :device_tokens do |t|
  t.references :user, null: false, foreign_key: true
  t.string :token, null: false
  t.string :platform, null: false  # "ios" or "android"
  t.string :device_id              # unique device identifier for dedup
  t.datetime :last_used_at
  t.timestamps
end

add_index :device_tokens, :token, unique: true
add_index :device_tokens, [:user_id, :platform]
```

### 2. Device Token API

```
POST   /api/device_tokens   — register token (called on app launch)
DELETE /api/device_tokens    — unregister token (called on logout)
```

Controller scoped to `current_user` — users can only manage their own tokens.

### 3. Gems

```ruby
gem "googleauth"   # Google API auth — generates OAuth2 tokens for FCM HTTP v1 API
```

**Note:** `googleauth` is NOT for user login. It takes Firebase service account credentials (a JSON key file) and generates short-lived OAuth2 bearer tokens so Rails can authenticate with the FCM HTTP v1 API. Users never see or interact with it.

### 4. `PushNotificationService`

```ruby
# app/services/push_notification_service.rb
class PushNotificationService
  FCM_URL = "https://fcm.googleapis.com/v1/projects/{PROJECT_ID}/messages:send"

  def self.send_to_user(user, title:, body:, data: {})
    tokens = user.device_tokens.where("last_used_at > ?", 30.days.ago)
    tokens.each do |device_token|
      send_to_token(device_token, title:, body:, data:)
    end
  end

  private

  def self.send_to_token(device_token, title:, body:, data:)
    # Build FCM v1 message payload
    # POST to FCM with googleauth-generated bearer token
    # Handle token expiry (delete stale tokens on 404)
  end
end
```

### 5. Update Notification Jobs

All existing notification jobs gain a push notification step alongside email:

| Job | Push trigger |
|-----|-------------|
| `StatusChangeNotificationJob` | Status changed on assigned incident |
| `MessageNotificationJob` | New message on assigned incident |
| `AssignmentNotificationJob` | User assigned to incident |
| `EscalationJob` | Emergency escalation alert |

Each job calls `PushNotificationService.send_to_user` for every recipient who has registered device tokens and hasn't disabled push in their notification preferences.

### 6. Push Payload Structure

```json
{
  "message": {
    "token": "device_fcm_token",
    "notification": {
      "title": "New Message — 123 Main St",
      "body": "John D.: Water damage in unit 4B..."
    },
    "data": {
      "incident_id": "42",
      "type": "new_message",
      "url": "/incidents/42"
    },
    "apns": {
      "payload": {
        "aps": {
          "badge": 3,
          "sound": "default"
        }
      }
    }
  }
}
```

### 7. Badge Count

Badge count = number of incidents with unread activity for that user. Calculated from `incident_read_states` (same logic as the existing unread badges in the web app). Sent in the APNs payload with every push.

---

## Mobile (Capacitor)

### 1. Plugin

```bash
npm install @capacitor/push-notifications
npx cap sync
```

### 2. Token Registration

On app launch (after authentication):

```typescript
import { PushNotifications } from '@capacitor/push-notifications';

// Request permission
const permission = await PushNotifications.requestPermissions();
if (permission.receive === 'granted') {
  await PushNotifications.register();
}

// Listen for token
PushNotifications.addListener('registration', (token) => {
  // POST token to Rails /api/device_tokens
});

// Listen for push received (foreground)
PushNotifications.addListener('pushNotificationReceived', (notification) => {
  // Show in-app toast or update unread badges
});

// Listen for push tapped (background → foreground)
PushNotifications.addListener('pushNotificationActionPerformed', (action) => {
  const incidentId = action.notification.data.incident_id;
  // Navigate to /incidents/{incidentId} via Inertia
});
```

### 3. Deep Linking

Tapping a push notification opens the relevant incident detail page. The `data.url` field in the push payload tells the app which route to navigate to.

### 4. Logout Cleanup

On logout, call `DELETE /api/device_tokens` to unregister the current device token, then `PushNotifications.removeAllListeners()`.

---

## Firebase Setup

1. **Create Firebase project** at console.firebase.google.com
2. **iOS setup:**
   - Add iOS app with bundle ID (`com.genixo.restoration`)
   - Upload APNs authentication key (`.p8` file from Apple Developer → Keys)
3. **Android setup:**
   - Add Android app with package name
   - Download `google-services.json` into `mobile/android/app/`
4. **Service account credentials:**
   - Firebase Console → Project Settings → Service Accounts → Generate New Private Key
   - Save JSON file — this is what `googleauth` uses to authenticate Rails → FCM
   - Store path in `GOOGLE_APPLICATION_CREDENTIALS` env var (never commit the file)

---

## Environment Variables

```bash
GOOGLE_APPLICATION_CREDENTIALS=/path/to/firebase-service-account.json
FCM_PROJECT_ID=genixo-restoration-xxxxx
```

---

## Notification Preferences

Push notifications respect the same per-user and per-incident notification preferences as email:

- Global toggle: `push_notifications` (new column on users, default: true)
- Per-incident overrides: same `incident_notification_overrides` table
- Notification jobs check preferences before calling `PushNotificationService`

---

## Effort Estimate

| Task | Estimate |
|------|----------|
| `device_tokens` migration + model + API | 2 hours |
| `PushNotificationService` + FCM integration | 3 hours |
| Update notification jobs to send push | 2 hours |
| Capacitor push plugin + token registration | 2 hours |
| Deep link handling + badge count | 2 hours |
| Firebase project setup + APNs key | 1 hour |
| Testing (manual + automated) | 3 hours |
| **Total** | **~2 days** |

---

## Dependencies

- Apple Developer account (for APNs key) — needed for App Store anyway
- Firebase project (free tier is sufficient)
- `googleauth` gem added to Gemfile
- `@capacitor/push-notifications` npm package
