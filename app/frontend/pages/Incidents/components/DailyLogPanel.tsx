import { useMemo, useState } from "react";
import { ChevronDown, Download, Pencil, Plus } from "lucide-react";
import { Button } from "@/components/ui/button";
import type {
  DailyActivity,
  DailyLogDate,
  DailyLogTableGroup,
  DailyLogTableRow,
  LaborEntry,
} from "../types";
import ActivityForm from "./ActivityForm";

interface DailyLogPanelProps {
  daily_activities: DailyActivity[];
  daily_log_dates: DailyLogDate[];
  daily_log_table_groups: DailyLogTableGroup[];
  labor_entries: LaborEntry[];
  can_manage_activities: boolean;
  activity_entries_path: string;
  dfr_path: string;
}

export default function DailyLogPanel({
  daily_activities = [],
  daily_log_dates = [],
  daily_log_table_groups = [],
  labor_entries = [],
  can_manage_activities,
  activity_entries_path,
  dfr_path,
}: DailyLogPanelProps) {
  const [selectedDate, setSelectedDate] = useState<string | null>(null);
  const [activityForm, setActivityForm] = useState<{ open: boolean; entry?: DailyActivity }>({ open: false });
  const [collapsedRows, setCollapsedRows] = useState<Set<string>>(new Set());

  // When a specific date is selected, all rows are expanded by default (user collapses them).
  // When "All Dates" is selected, all rows are collapsed by default (user expands them).
  const isRowExpanded = (id: string) => {
    if (selectedDate) return !collapsedRows.has(id);
    return collapsedRows.has(id);
  };

  const toggleRow = (id: string) => {
    setCollapsedRows((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id); else next.add(id);
      return next;
    });
  };

  const handleDateChange = (date: string | null) => {
    setSelectedDate(date);
    setCollapsedRows(new Set());
  };

  // Group labor entries by date for inline display
  const laborByDate = useMemo(() => {
    const map: Record<string, typeof labor_entries> = {};
    for (const entry of labor_entries) {
      const key = entry.log_date;
      if (!map[key]) map[key] = [];
      map[key].push(entry);
    }
    return map;
  }, [labor_entries]);

  // Enrich date groups with precomputed labor summaries and latest situation
  const dateGroups = useMemo(() => {
    const groups = daily_log_table_groups.map((group) => {
      const dateLaborEntries = laborByDate[group.date_key] || [];

      // Group labor by role for the group footer
      const roleMap: Record<string, { count: number; hours: number }> = {};
      for (const entry of dateLaborEntries) {
        const role = entry.role_label;
        if (!roleMap[role]) roleMap[role] = { count: 0, hours: 0 };
        roleMap[role].count += 1;
        roleMap[role].hours += entry.hours;
      }
      const laborByRole = Object.entries(roleMap).map(([role, data]) => ({
        role,
        count: data.count,
        hours: Math.round(data.hours * 10) / 10,
      }));

      // Latest situation from most recent activity row with metadata
      const activityRows = group.rows.filter((row) => row.row_type === "activity");
      const latestWithMeta = [...activityRows].reverse().find(
        (row) => row.units_label !== "—" || row.visitors || row.usable_rooms_returned || row.estimated_date_of_return
      );

      return {
        ...group,
        activityRows,
        laborByRole,
        situation: latestWithMeta ? {
          units_label: latestWithMeta.units_label !== "—" ? latestWithMeta.units_label : null,
          visitors: latestWithMeta.visitors || null,
          usable_rooms_returned: latestWithMeta.usable_rooms_returned || null,
          estimated_date_of_return: latestWithMeta.estimated_date_of_return || null,
        } : null,
      };
    }).filter((g) => g.rows.length > 0 || g.laborByRole.length > 0 || g.equipment_summary.length > 0);

    if (!selectedDate) return groups;
    return groups.filter((g) => g.date_key === selectedDate);
  }, [daily_log_table_groups, selectedDate, laborByDate]);

  const hasNoActivity = daily_activities.length === 0;

  if (hasNoActivity && !can_manage_activities) {
    return (
      <div className="flex-1 flex items-center justify-center text-muted-foreground text-sm py-12">
        No activity recorded yet.
      </div>
    );
  }

  const handleEdit = (row: DailyLogTableRow) => {
    if (!row.edit_path) return;
    const entry = daily_activities.find((a) => a.edit_path === row.edit_path);
    if (!entry) return;
    setActivityForm({ open: true, entry });
  };

  return (
    <div className="flex flex-col h-full">
      {daily_log_dates.length > 0 && (
        <div className="flex gap-2 px-4 py-3 border-b border-border overflow-x-auto shrink-0 bg-background/70">
          <Button
            variant={selectedDate === null ? "default" : "ghost"}
            size="sm"
            onClick={() => handleDateChange(null)}
            className="h-10 sm:h-8 text-sm sm:text-xs whitespace-nowrap"
          >
            All Dates
          </Button>
          {daily_log_dates.map((dateEntry) => (
            <Button
              key={dateEntry.key}
              variant={selectedDate === dateEntry.key ? "default" : "ghost"}
              size="sm"
              onClick={() => handleDateChange(dateEntry.key)}
              className="h-10 sm:h-8 text-sm sm:text-xs whitespace-nowrap"
            >
              {dateEntry.label}
            </Button>
          ))}
        </div>
      )}

      {can_manage_activities && (
        <div className="flex items-center gap-1 border-b border-border px-4 py-3 shrink-0 bg-background/70">
          <Button variant="outline" size="sm" className="h-10 sm:h-8 text-sm sm:text-xs gap-1.5" onClick={() => setActivityForm({ open: true })}>
            <Plus className="h-3 w-3" />
            Add Activity
          </Button>
        </div>
      )}

      <div className="flex-1 overflow-y-auto p-4 pb-10 space-y-6 bg-gradient-to-b from-background via-background to-muted/15">
        {dateGroups.length === 0 ? (
          <div className="text-sm text-muted-foreground italic py-6 text-center">
            No entries for this date.
          </div>
        ) : (
          dateGroups.map((group, groupIndex) => {
            const hasEquipment = group.equipment_summary.length > 0;
            const hasLabor = group.laborByRole.length > 0;
            const headerTone = groupIndex % 2 === 0
              ? "from-accent/80 to-accent/30"
              : "from-muted/90 to-muted/45";
            const edgeTone = groupIndex % 2 === 0
              ? "border-l-primary/40"
              : "border-l-muted-foreground/40";

            return (
              <div key={group.date_key} className={`rounded-xl border border-border/90 border-l-4 ${edgeTone} overflow-hidden bg-card shadow-sm`}>
                {/* Date header */}
                <div className={`px-4 py-3 border-b border-border bg-gradient-to-r ${headerTone} flex items-center justify-between`}>
                  <span className="text-sm font-semibold uppercase tracking-wide text-foreground/85">
                    {group.date_label}
                  </span>
                  <a
                    href={`${dfr_path}?date=${group.date_key}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    data-testid={`dfr-link-${group.date_key}`}
                    className="flex items-center gap-1 text-sm text-foreground/75 hover:text-foreground transition-colors"
                    title="Download Daily Field Report"
                  >
                    <Download className="h-3 w-3" />
                    DFR
                  </a>
                </div>

                {/* Timeline rows (activities, notes, documents, etc.) */}
                {group.rows.length > 0 && (
                  <div className="divide-y divide-border bg-card">
                    {group.rows.map((row) => {
                      const isExpanded = isRowExpanded(row.id);
                      const hasDetail = row.detail_label !== "—" && row.detail_label.length > 0;
                      const isLong = hasDetail && row.detail_label.length > 120;
                      const isExpandable = isLong;

                      return (
                        <div
                          key={row.id}
                          data-testid="daily-log-timeline-row"
                          role={isExpandable ? "button" : undefined}
                          tabIndex={isExpandable ? 0 : undefined}
                          onKeyDown={isExpandable ? (e) => {
                            if (e.key === "Enter" || e.key === " ") {
                              e.preventDefault();
                              toggleRow(row.id);
                            }
                          } : undefined}
                          className={`${isExpandable ? "cursor-pointer" : ""} hover:bg-muted/45 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-inset transition-colors`}
                          onClick={isExpandable ? () => toggleRow(row.id) : undefined}
                        >
                          <div className="flex items-start gap-2 px-4 py-3">
                            <div className="w-[88px] shrink-0 text-sm text-muted-foreground pt-0.5">{row.time_label}</div>
                            <div className="flex-1 min-w-0">
                              <div className="flex items-start gap-1">
                                {isExpandable && (
                                  <ChevronDown className={`h-3.5 w-3.5 mt-0.5 shrink-0 text-muted-foreground transition-transform ${isExpanded ? "" : "-rotate-90"}`} />
                                )}
                                <div className="min-w-0 flex-1">
                                  <div className="flex flex-wrap items-center gap-2">
                                    <span className="text-sm font-semibold text-foreground">{row.primary_label}</span>
                                    {row.status_label && (
                                      <span className="rounded-full border border-border bg-muted/60 px-2 py-0.5 text-xs text-foreground/80">
                                        {row.status_label}
                                      </span>
                                    )}
                                  </div>
                                  {hasDetail && (
                                    <div className={`text-sm text-muted-foreground mt-1 whitespace-pre-wrap ${!isExpanded && isLong ? "line-clamp-2" : ""}`}>
                                      {row.detail_label}
                                    </div>
                                  )}
                                </div>
                              </div>
                            </div>
                            <div className="shrink-0 flex items-center gap-2">
                              {row.row_type === "activity" && row.edit_path && (
                                <Button
                                  data-testid="edit-activity-btn"
                                  variant="ghost"
                                  size="sm"
                                  className="h-9 sm:h-7 px-2 text-sm sm:text-xs gap-1"
                                  onClick={(e) => { e.stopPropagation(); handleEdit(row); }}
                                >
                                  <Pencil className="h-3 w-3" />
                                </Button>
                              )}
                            </div>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                )}

                {/* Group-level resource summary */}
                <div className="border-t border-border bg-muted/30 px-4 py-3">
                  <div className="grid grid-cols-1 md:grid-cols-5 gap-x-4 gap-y-3 text-sm">
                    <div>
                      <div className="text-xs text-muted-foreground uppercase tracking-wide font-semibold mb-1">Equipment</div>
                      {hasEquipment ? (
                        <div className="space-y-0.5">
                          {group.equipment_summary.map((eq) => (
                            <div key={eq.type_name} className="text-foreground">
                              {eq.count} {eq.type_name} <span className="text-muted-foreground">{eq.hours}h</span>
                            </div>
                          ))}
                        </div>
                      ) : (
                        <div className="text-muted-foreground">—</div>
                      )}
                    </div>
                    <div>
                      <div className="text-xs text-muted-foreground uppercase tracking-wide font-semibold mb-1">Labor</div>
                      {hasLabor ? (
                        <div className="space-y-0.5">
                          {group.laborByRole.map((lr) => (
                            <div key={lr.role} className="text-foreground">
                              {lr.count} {lr.role} <span className="text-muted-foreground">{lr.hours}h</span>
                            </div>
                          ))}
                        </div>
                      ) : (
                        <div className="text-muted-foreground">—</div>
                      )}
                    </div>
                    <div>
                      <div className="text-xs text-muted-foreground uppercase tracking-wide font-semibold mb-1">Units Affected</div>
                      <div className="text-foreground">{group.situation?.units_label || <span className="text-muted-foreground">—</span>}</div>
                    </div>
                    <div>
                      <div className="text-xs text-muted-foreground uppercase tracking-wide font-semibold mb-1">Rooms Returned</div>
                      <div className="text-foreground">{group.situation?.usable_rooms_returned || <span className="text-muted-foreground">—</span>}</div>
                    </div>
                    <div>
                      <div className="text-xs text-muted-foreground uppercase tracking-wide font-semibold mb-1">Est. Return</div>
                      <div className="text-foreground">{group.situation?.estimated_date_of_return || <span className="text-muted-foreground">—</span>}</div>
                    </div>
                  </div>
                </div>
              </div>
            );
          })
        )}
      </div>

      {activityForm.open && (
        <ActivityForm
          path={activity_entries_path}
          entry={activityForm.entry}
          onClose={() => setActivityForm({ open: false })}
        />
      )}
    </div>
  );
}
