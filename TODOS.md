# TODOS

Deferred work with context. Added by /plan-eng-review 2026-07-19 (Weekly Field Report review).

## Report timezone authority

- **What:** Give properties (or incidents) an authoritative timezone for report day-bucketing instead of using the generating user's timezone.
- **Why:** `DfrPdfService` buckets activities/equipment into days via `Time.use_zone(caller's timezone)` (`app/services/dfr_pdf_service.rb:32`, `date_range` at :587). The same incident can bucket an 11pm activity into different days depending on who clicks Generate. Weekly reports inherit this.
- **Pros:** Deterministic reports regardless of generator; removes a discrepancy class before multi-region clients exist.
- **Cons:** Timezone column on properties + backfill + touching every report path; no observed user pain today (all users one region).
- **Context:** Add `timezone` to properties (default `America/Chicago`), pass property timezone at `DfrPdfJob` enqueue sites instead of `current_user.timezone`. Update DFR + weekly + IncidentReportService.
- **Depends on / blocked by:** Nothing; do after the weekly-report feature lands.

## Self-serve Consumable Types manager (Settings)

- **What:** Org-scoped add/deactivate page for `consumable_types`, copying the Settings → Equipment Types pattern (`settings_controller.rb:199+`, `routes.rb:139`).
- **Why:** The seeded list is Daniel's 11 items; today a new standard item needs a console `ConsumableType.create!`. Self-serve removes the dev round-trip.
- **Pros:** ~30-45 min (existing pattern); write-ins stay one-offs instead of a workaround.
- **Cons:** UI surface Daniel didn't ask for; his printed sheet suggests the list rarely changes.
- **Trigger:** Ship when write-ins for the same item keep recurring or Daniel asks to change the list.
- **Depends on / blocked by:** Consumables feature (2026-07 weekly-report branch) must land first.

## Report generation status tracking (queued/running/failed)

- **What:** Explicit job state surfaced in the Daily Log and Weekly Reports panels, replacing inference-by-polling.
- **Why:** Attachments can't represent job state. Weekly panel ships with a bounded-poll timeout message (mitigation); a dead job still can't say why it died. DFR panel still polls forever.
- **Pros:** Honest failure UX for every report type; permanently ends the polls-forever class.
- **Cons:** Needs a state-carrying record or Solid Queue introspection; touches both panels' serializers and UI.
- **Context:** `DailyLogPanel.tsx` polls every 5s until the attachment URL changes. The in-flight `fix/dfr-job-retry` branch is the natural home — whoever finishes it should wire real status through the serializers both panels read.
- **Depends on / blocked by:** `fix/dfr-job-retry` branch direction; land the weekly-report feature first.
