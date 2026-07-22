import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { router, usePage, usePoll } from "@inertiajs/react";
import { AlertCircle, FileText, Loader2, RefreshCw } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import type { SharedProps } from "@/types";
import type { DfrSelectablePhoto, IncidentAttachment, WeeklyReport } from "../types";
import DfrPhotoSelectionModal from "./DfrPhotoSelectionModal";

interface WeeklyReportsPanelProps {
  weekly_reports: WeeklyReport[];
  incident_has_photos: boolean;
  incident_has_documents: boolean;
  can_generate: boolean;
  weekly_report_path: string;
  dfr_photos_path: string;
}

// Attachments can't represent job state, so completion is inferred by polling
// the weekly_reports prop. Bounded: past this deadline we stop and tell the
// user instead of polling forever (see TODOS.md — report status tracking).
const POLL_TIMEOUT_MS = 180_000;
const MAX_RANGE_DAYS = 31;

// Date-only ISO strings parse as UTC midnight, so the span math on the two
// picker values is exact and DST-proof. Both default values come from the
// server (today / week_ago shared props) — never from the browser clock.
function daysBetween(startIso: string, endIso: string): number {
  return Math.round((Date.parse(endIso) - Date.parse(startIso)) / 86_400_000);
}

function rangeKey(startIso: string, endIso: string): string {
  return `${startIso}|${endIso}`;
}

export default function WeeklyReportsPanel({
  weekly_reports = [],
  incident_has_photos = false,
  incident_has_documents = false,
  can_generate,
  weekly_report_path,
  dfr_photos_path,
}: WeeklyReportsPanelProps) {
  const { today, week_ago } = usePage<SharedProps>().props;
  const [startDate, setStartDate] = useState(week_ago);
  const [endDate, setEndDate] = useState(today);
  // Requested ranges mapped to the report URL at request time (null = new
  // report) so a regeneration completing is detectable as a URL change.
  const [requested, setRequested] = useState<Map<string, string | null>>(new Map());
  const [timedOut, setTimedOut] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const { start: startPolling, stop: stopPolling } = usePoll(5000, {
    only: ["weekly_reports"],
  }, { autoStart: false });

  const findReport = useCallback(
    (start: string, end: string) =>
      weekly_reports.find((r) => r.log_date === start && r.log_date_end === end),
    [weekly_reports]
  );

  const pendingRanges = useMemo(() => {
    const pending = new Set<string>();
    for (const [key, oldUrl] of requested) {
      const [start, end] = key.split("|");
      const report = findReport(start, end);
      if (!report || report.url === oldUrl) pending.add(key);
    }
    return pending;
  }, [requested, findReport]);

  // Stop polling once every requested report has (re)generated.
  useEffect(() => {
    if (requested.size > 0 && pendingRanges.size === 0) {
      stopPolling();
      const timer = setTimeout(() => setRequested(new Map()), 0);
      return () => clearTimeout(timer);
    }
  }, [pendingRanges.size, requested.size, stopPolling]);

  // Bounded polling: a report that never appears must not spin forever.
  useEffect(() => {
    if (requested.size === 0) return;
    const timer = setTimeout(() => {
      stopPolling();
      setRequested(new Map());
      setTimedOut(true);
    }, POLL_TIMEOUT_MS);
    return () => clearTimeout(timer);
  }, [requested, stopPolling]);

  // Photo/document selection modal state (same flow as DailyLogPanel's DFR,
  // but nothing preselected — the user opts a week of photos in explicitly).
  const [modal, setModal] = useState<{ open: boolean; start: string; end: string }>({ open: false, start: "", end: "" });
  const [modalPhotos, setModalPhotos] = useState<DfrSelectablePhoto[]>([]);
  const [modalDocuments, setModalDocuments] = useState<IncidentAttachment[]>([]);
  const [modalLoading, setModalLoading] = useState(false);
  const [modalError, setModalError] = useState(false);
  const photoFetchSeq = useRef(0);

  const rangeError = useMemo(() => {
    if (!startDate || !endDate) return "Pick a start and end date.";
    const span = daysBetween(startDate, endDate);
    if (span <= 0) return "End date must be after the start date.";
    if (span >= MAX_RANGE_DAYS) return `Date range cannot exceed ${MAX_RANGE_DAYS} days.`;
    return null;
  }, [startDate, endDate]);

  const submitReport = useCallback((start: string, end: string, photoIds?: number[], documentIds?: number[]) => {
    if (submitting) return;
    const currentUrl = findReport(start, end)?.url ?? null;
    const data: Record<string, string | number[]> = { start_date: start, end_date: end };
    if (photoIds) data.photo_ids = photoIds;
    if (documentIds) data.document_ids = documentIds;
    setSubmitting(true);
    setTimedOut(false);
    router.post(weekly_report_path, data, {
      preserveScroll: true,
      onFinish: () => setSubmitting(false),
    });
    setRequested((prev) => new Map(prev).set(rangeKey(start, end), currentUrl));
    startPolling();
  }, [weekly_report_path, findReport, startPolling, submitting]);

  const fetchModalPhotos = useCallback((start: string) => {
    const seq = ++photoFetchSeq.current;
    setModalPhotos([]);
    setModalDocuments([]);
    setModalLoading(true);
    setModalError(false);

    fetch(`${dfr_photos_path}?date=${start}`, { headers: { Accept: "application/json" } })
      .then((res) => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        return res.json();
      })
      .then((payload: { photos: DfrSelectablePhoto[]; documents: IncidentAttachment[] }) => {
        if (seq !== photoFetchSeq.current) return;
        setModalPhotos(payload.photos);
        setModalDocuments(payload.documents);
      })
      .catch(() => {
        if (seq === photoFetchSeq.current) setModalError(true);
      })
      .finally(() => {
        if (seq === photoFetchSeq.current) setModalLoading(false);
      });
  }, [dfr_photos_path]);

  const handleGenerate = useCallback((start: string, end: string) => {
    if (!incident_has_photos && !incident_has_documents) {
      submitReport(start, end);
      return;
    }
    setModal({ open: true, start, end });
    fetchModalPhotos(start);
  }, [incident_has_photos, incident_has_documents, submitReport, fetchModalPhotos]);

  const closeModal = useCallback(() => setModal({ open: false, start: "", end: "" }), []);

  const handleModalSubmit = useCallback((photoIds: number[], documentIds: number[]) => {
    submitReport(modal.start, modal.end, photoIds, documentIds);
    closeModal();
  }, [submitReport, modal.start, modal.end, closeModal]);

  const newReportPending = pendingRanges.size > 0;

  return (
    <div className="h-full overflow-y-auto p-4 sm:p-6">
      {can_generate && (
        <div className="mb-6 rounded-lg border border-border bg-muted/30 p-4">
          <h3 className="text-sm font-semibold text-foreground mb-3">Generate Weekly Report</h3>
          <p className="text-xs text-muted-foreground mb-3">
            Combines each day's activities, labor, notes, and equipment for the selected date
            range into one PDF. Photos are not included unless you select them.
          </p>
          <div className="flex flex-wrap items-end gap-3">
            <label className="flex flex-col gap-1 text-xs font-medium text-muted-foreground">
              Start date
              <Input
                type="date"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
                data-testid="weekly-report-start-date"
                className="h-9 w-auto"
              />
            </label>
            <label className="flex flex-col gap-1 text-xs font-medium text-muted-foreground">
              End date
              <Input
                type="date"
                value={endDate}
                onChange={(e) => setEndDate(e.target.value)}
                data-testid="weekly-report-end-date"
                className="h-9 w-auto"
              />
            </label>
            <Button
              onClick={() => handleGenerate(startDate, endDate)}
              disabled={!!rangeError || submitting || newReportPending}
              data-testid="weekly-report-generate"
            >
              {submitting || newReportPending ? (
                <>
                  <Loader2 className="h-4 w-4 mr-1.5 animate-spin" />
                  Generating…
                </>
              ) : (
                "Generate"
              )}
            </Button>
          </div>
          {rangeError && startDate && endDate && (
            <p className="mt-2 text-xs text-destructive" data-testid="weekly-report-range-error">{rangeError}</p>
          )}
          {timedOut && (
            <div className="mt-3 flex items-start gap-2 rounded-md border border-destructive/40 bg-destructive/5 p-3 text-sm text-foreground" data-testid="weekly-report-timeout">
              <AlertCircle className="h-4 w-4 mt-0.5 shrink-0 text-destructive" />
              <span>
                The report is taking longer than expected. It may still be processing — check
                back in a few minutes, or try generating it again.
              </span>
            </div>
          )}
        </div>
      )}

      <h3 className="text-sm font-semibold text-foreground mb-3">Reports</h3>
      {weekly_reports.length === 0 && !newReportPending ? (
        <div className="flex flex-col items-center justify-center py-12 text-muted-foreground">
          <FileText className="h-8 w-8 mb-2" />
          <p className="text-sm">No weekly reports yet.</p>
          {can_generate && (
            <p className="text-xs mt-1">Pick a date range above to generate the first one.</p>
          )}
        </div>
      ) : (
        <ul className="space-y-2">
          {Array.from(pendingRanges)
            .filter((key) => {
              const [start, end] = key.split("|");
              return !findReport(start, end);
            })
            .map((key) => {
              const [start, end] = key.split("|");
              return (
                <li
                  key={key}
                  className="flex items-center gap-3 rounded-md border border-border bg-muted/20 px-3 py-2.5"
                  data-testid={`weekly-report-pending-${start}`}
                >
                  <Loader2 className="h-4 w-4 animate-spin text-muted-foreground shrink-0" />
                  <span className="text-sm text-muted-foreground">
                    Generating report for {start} – {end}…
                  </span>
                </li>
              );
            })}
          {weekly_reports.map((report) => {
            const key = rangeKey(report.log_date ?? "", report.log_date_end ?? "");
            const regenerating = pendingRanges.has(key);
            return (
              <li
                key={report.id}
                className="flex items-center gap-3 rounded-md border border-border px-3 py-2.5"
                data-testid={`weekly-report-row-${report.log_date}`}
              >
                <FileText className="h-5 w-5 shrink-0 text-muted-foreground" />
                <div className="min-w-0 flex-1">
                  <a
                    href={report.url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="block truncate text-sm font-medium text-foreground hover:text-primary hover:underline"
                    data-testid={`weekly-report-link-${report.log_date}`}
                  >
                    {report.range_label}
                  </a>
                  <p className="truncate text-xs text-muted-foreground">
                    {report.filename} · {report.uploaded_by_name} · {report.created_at_label}
                  </p>
                </div>
                {can_generate && (
                  regenerating ? (
                    <Loader2 className="h-4 w-4 animate-spin text-muted-foreground shrink-0" data-testid={`weekly-report-refreshing-${report.log_date}`} />
                  ) : (
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => handleGenerate(report.log_date ?? "", report.log_date_end ?? "")}
                      disabled={submitting}
                      title="Regenerate this report"
                      data-testid={`weekly-report-refresh-${report.log_date}`}
                      className="shrink-0 text-muted-foreground hover:text-foreground"
                    >
                      <RefreshCw className="h-4 w-4" />
                    </Button>
                  )
                )}
              </li>
            );
          })}
        </ul>
      )}

      <DfrPhotoSelectionModal
        isOpen={modal.open}
        onClose={closeModal}
        onSubmit={handleModalSubmit}
        dateLabel={`${modal.start} – ${modal.end}`}
        photos={modalPhotos}
        documents={modalDocuments}
        isLoading={modalLoading}
        loadError={modalError}
        onRetry={() => fetchModalPhotos(modal.start)}
        reportLabel="Weekly Report"
        defaultSelectNone
      />
    </div>
  );
}
