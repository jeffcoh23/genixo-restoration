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

## Weekly-report generation throttling + poll cost

- **What:** (a) Rate-limit / dedupe pending weekly-report jobs per incident+span; (b) serve the panel's 5s poll from a lightweight JSON endpoint instead of a full Inertia partial reload (which runs the whole incident-show eager-prop pipeline server-side, ~36x per generation).
- **Why:** /review 2026-07-22 findings. The endpoint enqueues an expensive PDF job with no pending-job uniqueness; the poll is bounded (3 min) but heavy. Both are insider-only surfaces gated by MANAGE_DAILY_LOGS, so no external risk.
- **Context:** The proper home for both is the report status-tracking work below (a status record gives dedupe and a cheap poll target for free). The Daily Log DFR panel has the same poll pattern.
- **Depends on / blocked by:** Fold into "Report generation status tracking".

## Daily DFR duplicate-row race (index doesn't cover NULL log_date_end)

- **What:** The generated-report unique index protects weeklies only — DFR rows keep NULL `log_date_end` and Postgres NULLs-distinct means concurrent daily generations can still create duplicate rows (pre-existing behavior; the job's RecordNotUnique rescue never fires for dailies).
- **Fix:** `nulls_not_distinct: true` on the index (needs PG15+; local dev is PG14) or a COALESCE(log_date_end, log_date) expression index — either requires deduping any existing duplicate DFR rows first.
- **Why deferred:** /review 2026-07-22; documented status quo, low frequency (needs two humans generating the same DFR in the same seconds), self-corrects on regeneration via find_by.

## Consumables serializer payload growth

- **What:** `serialize_consumable_entries` ships every day the incident ever logged (no cap) in the equipment defer group; a years-long incident logging the ~11-row sheet daily grows unbounded. Weekly-reports serializer is capped at 200; consumables needs a windowing strategy (recent N days + on-demand older) because a bare limit would truncate the day-chips UX.
- **Why deferred:** /review 2026-07-22; real usage is a handful of rows per day on weeks-long incidents.

## Report generation status tracking (queued/running/failed)

- **What:** Explicit job state surfaced in the Daily Log and Weekly Reports panels, replacing inference-by-polling.
- **Why:** Attachments can't represent job state. Weekly panel ships with a bounded-poll timeout message (mitigation); a dead job still can't say why it died. DFR panel still polls forever.
- **Pros:** Honest failure UX for every report type; permanently ends the polls-forever class.
- **Cons:** Needs a state-carrying record or Solid Queue introspection; touches both panels' serializers and UI.
- **Context:** `DailyLogPanel.tsx` polls every 5s until the attachment URL changes. The in-flight `fix/dfr-job-retry` branch is the natural home — whoever finishes it should wire real status through the serializers both panels read.
- **Depends on / blocked by:** `fix/dfr-job-retry` branch direction; land the weekly-report feature first.
