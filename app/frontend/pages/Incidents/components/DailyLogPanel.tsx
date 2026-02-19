import { useMemo, useState } from "react";
import { ChevronDown, Pencil, Plus } from "lucide-react";
import { Button } from "@/components/ui/button";
import type {
  AttachableEquipmentEntry,
  DailyActivity,
  DailyLogDate,
  DailyLogTableGroup,
  DailyLogTableRow,
  EquipmentType,
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
  equipment_types: EquipmentType[];
  attachable_equipment_entries: AttachableEquipmentEntry[];
}

export default function DailyLogPanel({
  daily_activities = [],
  daily_log_dates = [],
  daily_log_table_groups = [],
  labor_entries = [],
  can_manage_activities,
  activity_entries_path,
  equipment_types,
  attachable_equipment_entries,
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

  // Enrich date groups with precomputed labor summaries
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

      return {
        ...group,
        activityRows: group.rows.filter((row) => row.row_type === "activity"),
        laborByRole,
      };
    }).filter((g) => g.activityRows.length > 0 || g.laborByRole.length > 0);

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
        <div className="flex gap-1 p-3 border-b border-border overflow-x-auto shrink-0">
          <Button
            variant={selectedDate === null ? "default" : "ghost"}
            size="sm"
            onClick={() => handleDateChange(null)}
            className="h-7 text-xs whitespace-nowrap"
          >
            All Dates
          </Button>
          {daily_log_dates.map((dateEntry) => (
            <Button
              key={dateEntry.key}
              variant={selectedDate === dateEntry.key ? "default" : "ghost"}
              size="sm"
              onClick={() => handleDateChange(dateEntry.key)}
              className="h-7 text-xs whitespace-nowrap"
            >
              {dateEntry.label}
            </Button>
          ))}
        </div>
      )}

      {can_manage_activities && (
        <div className="flex items-center gap-1 border-b border-border px-3 py-2 shrink-0">
          <Button variant="ghost" size="sm" className="h-7 text-xs gap-1" onClick={() => setActivityForm({ open: true })}>
            <Plus className="h-3 w-3" />
            Add Activity
          </Button>
        </div>
      )}

      <div className="flex-1 overflow-y-auto p-3 pb-8 space-y-4">
        {dateGroups.length === 0 ? (
          <div className="text-sm text-muted-foreground italic py-6 text-center">
            No entries for this date.
          </div>
        ) : (
          dateGroups.map((group) => {
            const hasEquipment = group.equipment_summary.length > 0;
            const hasLabor = group.laborByRole.length > 0;

            return (
              <div key={group.date_key} className="rounded border border-border overflow-hidden">
                {/* Date header with summary stats */}
                <div className="px-3 py-2 border-b border-border bg-muted flex items-center justify-between">
                  <span className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">
                    {group.date_label}
                  </span>
                  {(group.total_labor_hours > 0 || group.total_equip_count > 0) && (
                    <div className="flex items-center gap-2 text-xs text-muted-foreground">
                      {group.total_labor_hours > 0 && (
                        <span>{group.total_labor_hours}h labor</span>
                      )}
                      {group.total_labor_hours > 0 && group.total_equip_count > 0 && (
                        <span>·</span>
                      )}
                      {group.total_equip_count > 0 && (
                        <span>{group.total_equip_count} equip</span>
                      )}
                    </div>
                  )}
                </div>

                {/* Activity rows */}
                {group.activityRows.length > 0 && (
                  <div className="divide-y divide-border">
                    {group.activityRows.map((row) => {
                      const isExpanded = isRowExpanded(row.id);
                      const hasDetail = row.detail_label !== "—" && row.detail_label.length > 0;
                      const isLong = hasDetail && row.detail_label.length > 120;
                      const hasRowMetadata = (
                        row.units_label !== "—" ||
                        row.visitors ||
                        row.usable_rooms_returned ||
                        row.estimated_date_of_return
                      );
                      const isExpandable = isLong || hasRowMetadata;

                      return (
                        <div
                          key={row.id}
                          className={isExpandable ? "cursor-pointer hover:bg-muted transition-colors" : ""}
                          onClick={isExpandable ? () => toggleRow(row.id) : undefined}
                        >
                          {/* Row header */}
                          <div className="flex items-start gap-2 px-3 py-2">
                            <div className="w-[80px] shrink-0 text-xs text-muted-foreground pt-0.5">{row.time_label}</div>
                            <div className="flex-1 min-w-0">
                              <div className="flex items-start gap-1">
                                {isExpandable && (
                                  <ChevronDown className={`h-3.5 w-3.5 mt-0.5 shrink-0 text-muted-foreground transition-transform ${isExpanded ? "" : "-rotate-90"}`} />
                                )}
                                <div className="min-w-0 flex-1">
                                  <div className="flex items-center gap-2">
                                    <span className="text-sm font-medium text-foreground">{row.primary_label}</span>
                                    {row.status_label && <span className="text-xs text-muted-foreground">{row.status_label}</span>}
                                  </div>
                                  {hasDetail && (
                                    <div className={`text-xs text-muted-foreground mt-1 whitespace-pre-wrap ${!isExpanded && isLong ? "line-clamp-2" : ""}`}>
                                      {row.detail_label}
                                    </div>
                                  )}
                                </div>
                              </div>
                            </div>
                            <div className="shrink-0 flex items-center gap-2">
                              {row.edit_path && (
                                <Button
                                  variant="ghost"
                                  size="sm"
                                  className="h-6 px-2 text-xs gap-1"
                                  onClick={(e) => { e.stopPropagation(); handleEdit(row); }}
                                >
                                  <Pencil className="h-3 w-3" />
                                </Button>
                              )}
                            </div>
                          </div>

                          {/* Expanded row-specific metadata */}
                          {isExpanded && hasRowMetadata && (
                            <div className="px-3 pb-3 ml-[80px] pl-5">
                              <div className="flex flex-wrap gap-x-6 gap-y-1 text-xs">
                                {row.units_label !== "—" && (
                                  <span>
                                    <span className="text-muted-foreground">Units </span>
                                    <span className="text-foreground">{row.units_label}</span>
                                  </span>
                                )}
                                {row.visitors && (
                                  <span>
                                    <span className="text-muted-foreground">Visitors </span>
                                    <span className="text-foreground">{row.visitors}</span>
                                  </span>
                                )}
                                {row.usable_rooms_returned && (
                                  <span>
                                    <span className="text-muted-foreground">Rooms Returned </span>
                                    <span className="text-foreground">{row.usable_rooms_returned}</span>
                                  </span>
                                )}
                                {row.estimated_date_of_return && (
                                  <span>
                                    <span className="text-muted-foreground">Est. Return </span>
                                    <span className="text-foreground">{row.estimated_date_of_return}</span>
                                  </span>
                                )}
                              </div>
                            </div>
                          )}
                        </div>
                      );
                    })}
                  </div>
                )}

                {/* Group-level resource summary */}
                {(hasEquipment || hasLabor) && (
                  <div className="border-t border-border bg-muted px-3 py-2.5">
                    <div className="flex flex-wrap gap-x-10 gap-y-2 text-xs">
                      {hasEquipment && (
                        <div>
                          <div className="text-muted-foreground uppercase tracking-wide font-semibold mb-1">Equipment</div>
                          <div className="space-y-0.5">
                            {group.equipment_summary.map((eq) => (
                              <div key={eq.type_name} className="text-foreground">
                                {eq.count} {eq.type_name} <span className="text-muted-foreground">{eq.hours}h</span>
                              </div>
                            ))}
                          </div>
                        </div>
                      )}
                      {hasLabor && (
                        <div>
                          <div className="text-muted-foreground uppercase tracking-wide font-semibold mb-1">Labor</div>
                          <div className="space-y-0.5">
                            {group.laborByRole.map((lr) => (
                              <div key={lr.role} className="text-foreground">
                                {lr.count} {lr.role} <span className="text-muted-foreground">{lr.hours}h</span>
                              </div>
                            ))}
                          </div>
                        </div>
                      )}
                    </div>
                  </div>
                )}
              </div>
            );
          })
        )}
      </div>

      {activityForm.open && (
        <ActivityForm
          path={activity_entries_path}
          entry={activityForm.entry}
          equipment_types={equipment_types}
          attachable_equipment_entries={attachable_equipment_entries}
          onClose={() => setActivityForm({ open: false })}
        />
      )}
    </div>
  );
}
