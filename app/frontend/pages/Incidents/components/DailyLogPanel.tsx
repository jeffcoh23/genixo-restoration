import { Fragment, useMemo, useState } from "react";
import { Pencil, Plus } from "lucide-react";
import { Button } from "@/components/ui/button";
import type {
  AttachableEquipmentEntry,
  DailyActivity,
  DailyLogDate,
  DailyLogTableGroup,
  DailyLogTableRow,
  EquipmentType,
} from "../types";
import ActivityForm from "./ActivityForm";

interface DailyLogPanelProps {
  daily_activities: DailyActivity[];
  daily_log_dates: DailyLogDate[];
  daily_log_table_groups: DailyLogTableGroup[];
  can_manage_activities: boolean;
  activity_entries_path: string;
  equipment_types: EquipmentType[];
  attachable_equipment_entries: AttachableEquipmentEntry[];
}

export default function DailyLogPanel({
  daily_activities = [],
  daily_log_dates = [],
  daily_log_table_groups = [],
  can_manage_activities,
  activity_entries_path,
  equipment_types,
  attachable_equipment_entries,
}: DailyLogPanelProps) {
  const [selectedDate, setSelectedDate] = useState<string | null>(null);
  const [activityForm, setActivityForm] = useState<{ open: boolean; entry?: DailyActivity }>({ open: false });

  // Filter to activity rows only
  const activityGroups = useMemo(() => {
    const filtered = daily_log_table_groups.map((group) => ({
      ...group,
      rows: group.rows.filter((row) => row.row_type === "activity"),
    })).filter((group) => group.rows.length > 0);

    if (!selectedDate) return filtered;
    return filtered.filter((group) => group.date_key === selectedDate);
  }, [daily_log_table_groups, selectedDate]);

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
    const entry = daily_activities.find((activity) => activity.edit_path === row.edit_path);
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
            onClick={() => setSelectedDate(null)}
            className="h-7 text-xs whitespace-nowrap"
          >
            All Dates
          </Button>
          {daily_log_dates.map((dateEntry) => (
            <Button
              key={dateEntry.key}
              variant={selectedDate === dateEntry.key ? "default" : "ghost"}
              size="sm"
              onClick={() => setSelectedDate(dateEntry.key)}
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
        {activityGroups.length === 0 ? (
          <div className="text-sm text-muted-foreground italic py-6 text-center">
            No entries for this date.
          </div>
        ) : (
          activityGroups.map((group) => (
            <div key={group.date_key} className="rounded border border-border overflow-hidden">
              <div className="px-3 py-2 border-b border-border bg-muted/40 text-xs font-semibold uppercase tracking-wide text-muted-foreground">
                {group.date_label}
              </div>
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead className="bg-muted/30 border-b border-border">
                    <tr>
                      <th className="px-3 py-2 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground w-[90px]">Time</th>
                      <th className="px-3 py-2 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground">Activity</th>
                      <th className="px-3 py-2 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground w-[120px]">Status</th>
                      <th className="px-3 py-2 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground w-[140px]">Visitors</th>
                      <th className="px-3 py-2 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground w-[120px]">By</th>
                      <th className="px-3 py-2 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground w-[70px]"></th>
                    </tr>
                  </thead>
                  <tbody>
                    {group.rows.map((row) => {
                      const hasRow2 = row.row_type === "activity" && (
                        row.units_label !== "—" ||
                        row.visitors ||
                        row.usable_rooms_returned ||
                        row.estimated_date_of_return
                      );

                      return (
                        <Fragment key={row.id}>
                          <tr className={`${hasRow2 ? "" : "border-b border-border"} align-top`}>
                            <td className="px-3 py-2 text-xs text-muted-foreground whitespace-nowrap">{row.time_label}</td>
                            <td className="px-3 py-2 text-xs text-foreground">
                              {row.primary_label}
                              {row.detail_label !== "—" && (
                                <div className="text-muted-foreground mt-0.5">{row.detail_label}</div>
                              )}
                            </td>
                            <td className="px-3 py-2 text-xs text-muted-foreground">{row.status_label}</td>
                            <td className="px-3 py-2 text-xs text-muted-foreground">{row.visitors || ""}</td>
                            <td className="px-3 py-2 text-xs text-muted-foreground">{row.actor_name}</td>
                            <td className="px-3 py-2">
                              {row.edit_path && (
                                <Button
                                  variant="ghost"
                                  size="sm"
                                  className="h-7 px-2 text-xs gap-1"
                                  onClick={() => handleEdit(row)}
                                >
                                  <Pencil className="h-3 w-3" />
                                  Edit
                                </Button>
                              )}
                            </td>
                          </tr>
                          {hasRow2 && (
                            <tr className="border-b border-border">
                              <td />
                              <td colSpan={5} className="px-3 pb-2 pt-0">
                                <div className="flex gap-8 text-xs">
                                  {row.units_label !== "—" && (
                                    <div>
                                      <div className="text-muted-foreground uppercase tracking-wide text-xs">Units Affected</div>
                                      <div className="text-muted-foreground">{row.units_label}</div>
                                    </div>
                                  )}
                                  {row.usable_rooms_returned && (
                                    <div>
                                      <div className="text-muted-foreground uppercase tracking-wide text-xs">Usable Rooms Returned</div>
                                      <div className="text-muted-foreground">{row.usable_rooms_returned}</div>
                                    </div>
                                  )}
                                  {row.estimated_date_of_return && (
                                    <div>
                                      <div className="text-muted-foreground uppercase tracking-wide text-xs">Est. Date of Return</div>
                                      <div className="text-muted-foreground">{row.estimated_date_of_return}</div>
                                    </div>
                                  )}
                                </div>
                              </td>
                            </tr>
                          )}
                        </Fragment>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          ))
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
