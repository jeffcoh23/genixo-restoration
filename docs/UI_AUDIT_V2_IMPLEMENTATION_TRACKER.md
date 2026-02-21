# UI Audit V2 Implementation Tracker

Branch: `feature/ui-audit-v2-remediation`
Source audit: `docs/UI_AUDIT.md`, `docs/UI_AUDIT_V2_CHECKLIST.md`

## P0 Accessibility + Consistency
- [x] Status badge contrast made WCAG AA-compliant for all statuses.
- [x] Automated status contrast check script added and runnable.
- [x] Raw selects replaced in `app/frontend/pages/Properties/New.tsx` and `app/frontend/pages/Incidents/components/AttachmentForm.tsx`.
- [x] `MultiFilterSelect` keyboard and ARIA behavior remediated.
- [x] `Incidents/New` team selection remediated to accessible checkbox controls.
- [x] `OverviewPanel` assign dropdown remediated to accessible select controls.
- [x] Critical mobile touch targets raised to 44px minimum in incident and settings flows.

## P1 UX + Visual Hierarchy
- [x] `Incidents/New` reorganized into sectioned flow with sticky action footer.
- [x] `RightPanelShell` tab priority and narrow-width behavior improved.
- [x] `Incidents/Show` constrained-height/mobile behavior improved.
- [x] `DailyLogPanel` visual hierarchy and contrast reduced gray/white monotony.
- [x] `MessagePanel` supports attachment-only sends.
- [x] List filtering gets applied-filter chips and clear actions.
- [x] Mobile card/list rendering added for key table-heavy index views.

## P2 Quality Consistency
- [x] Browser `confirm()` replaced with shared `Dialog` flow in `Users/Show` and `Properties/Show`.
- [x] Auth/invitation screens aligned to shared card/alert patterns.
- [x] `ResetPassword` includes clear password requirement helper text.
- [x] On-call settings controls improved for sizing and action clarity.
- [x] Photo upload dialog prevents accidental close while uploads are in-flight and improves status messaging.

## Validation
- [x] `npm run lint`
- [x] `npm run typecheck`
- [x] `npm run contrast:status`
