# App Store Submission — Genixo Restoration iOS

## App Identity

| Field | Value |
|-------|-------|
| App Name | Genixo Restoration |
| Subtitle | Incident Management for Restoration Teams |
| Bundle ID | `com.genixo.restoration` |
| SKU | `genixo-ios-001` |
| Category | Business |
| Marketing Version | 1.0.0 |
| Build | 1 |

## Description

Genixo Restoration is an incident management tool built for property restoration teams. Track water damage, fire, mold, and storm restoration jobs from intake through completion — with real-time updates, photo documentation, and team coordination.

Designed for mitigation companies and property managers who need a shared view of every active job:

- Create and track restoration incidents with full status workflows
- Assign technicians, managers, and property contacts to each job
- Upload photos of damage directly from your phone's camera
- Log labor hours, equipment usage, and moisture readings on-site
- Send messages and notes to keep everyone on the same page
- Get notified when incidents are updated or need attention

Whether you're on a job site or in the office, Genixo keeps your entire team connected.

## Keywords

restoration, mitigation, water damage, fire damage, property management, incident management, field service, work order, job tracking, technician

## Privacy Policy URL

https://genixorestoration.com/privacy

## Support URL

https://genixorestoration.com

## Screenshots Required

| Device | Size | Count |
|--------|------|-------|
| iPhone 6.7" (15 Pro Max) | 1290 x 2796 | 3-5 |
| iPhone 5.5" (8 Plus) | 1242 x 2208 | 3-5 |

Suggested screens to capture:
1. Dashboard with active incidents
2. Incident detail view with status and details
3. Photo upload / camera capture
4. Incident list view
5. Login screen (branded)

## App Review Notes

```
This is a business application for property restoration companies.
It requires a valid account to use — there is no public signup.

The app loads our hosted web application (genixorestoration.com)
inside a native WebView using Capacitor. Native features include:
- Camera access for photographing property damage on-site
- Photo library access for uploading existing images
- Network detection with offline fallback screen

TEST ACCOUNT:
Email: demo@genixorestoration.com
Password: GenixoDemo2026!

After logging in, you will see the dashboard with active restoration
incidents. Tap any incident to view details, photos, and team
assignments. Use the camera icon to test photo capture.
```

## Content Rating

- No objectionable content
- No user-generated content visible to other users outside their organization
- Age rating: 4+

## Signing Checklist

- [ ] Xcode → Target "App" → Signing & Capabilities → Automatic signing enabled
- [ ] Team selected (Apple Developer account)
- [ ] Bundle ID matches: `com.genixo.restoration`
- [ ] Marketing Version: `1.0.0`
- [ ] Build: `1`

## Submission Checklist

- [ ] Server URL updated to `genixorestoration.com`
- [ ] Offline fallback screen working
- [ ] Privacy policy live at `/privacy`
- [ ] Screenshots captured for both device sizes
- [ ] Test account credentials added to review notes
- [ ] App icon displays correctly
- [ ] Camera/photo permissions work on real device
- [ ] Archive uploaded to App Store Connect via Xcode
- [ ] Build appears in TestFlight and passes smoke test
- [ ] Review submitted
