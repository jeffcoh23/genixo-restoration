import { useState } from "react";
import { Clock, Plus } from "lucide-react";
import { Button } from "@/components/ui/button";
import EmptyState from "@/components/EmptyState";
import type { AssignableUser, LaborEntry, LaborLog } from "../types";
import LaborForm from "./LaborForm";

interface LaborPanelProps {
  labor_log: LaborLog;
  labor_entries: LaborEntry[];
  can_manage_labor: boolean;
  labor_entries_path: string;
  assignable_labor_users: AssignableUser[];
}

export default function LaborPanel({ labor_log, labor_entries: _labor_entries, can_manage_labor, labor_entries_path, assignable_labor_users }: LaborPanelProps) {
  const [showForm, setShowForm] = useState(false);

  const hasData = labor_log.employees.length > 0;

  return (
    <div className="flex flex-col h-full">
      {can_manage_labor && (
        <div className="flex items-center gap-1 border-b border-border px-4 py-3 shrink-0">
          <Button variant="outline" size="sm" className="h-10 sm:h-8 text-sm sm:text-xs gap-1.5" onClick={() => setShowForm(true)}>
            <Plus className="h-3.5 w-3.5 sm:h-3 sm:w-3" />
            Add Labor
          </Button>
        </div>
      )}

      {!hasData ? (
        <div className="flex-1 flex items-center justify-center">
          <EmptyState
            icon={<Clock className="h-8 w-8" />}
            title="No labor hours recorded yet"
            description="Log work hours for technicians and crew members on this job."
          />
        </div>
      ) : (
        <div className="flex-1 overflow-y-auto">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-muted border-b border-border sticky top-0">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground sticky left-0 bg-muted z-10 min-w-[140px]">
                    Employee
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground min-w-[100px]">
                    Title
                  </th>
                  {labor_log.date_labels.map((label, i) => (
                    <th key={labor_log.dates[i]} className="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-muted-foreground min-w-[80px]">
                      {label}
                    </th>
                  ))}
                  <th className="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-muted-foreground min-w-[70px]">
                    Total
                  </th>
                </tr>
              </thead>
              <tbody>
                {labor_log.employees.map((emp, i) => (
                    <tr key={i} className="border-b border-border last:border-b-0 hover:bg-muted/30 transition-colors">
                      <td className="px-4 py-3 text-sm font-medium text-foreground sticky left-0 bg-background z-10">
                        {emp.name}
                      </td>
                      <td className="px-4 py-3 text-sm text-muted-foreground">
                        {emp.title}
                      </td>
                      {labor_log.dates.map((dateKey) => {
                        const hours = emp.hours_by_date[dateKey];
                        return (
                          <td key={dateKey} className="px-4 py-3 text-sm text-muted-foreground text-right tabular-nums">
                            {hours != null ? hours : ""}
                          </td>
                        );
                      })}
                      <td className="px-4 py-3 text-sm font-medium text-foreground text-right tabular-nums">
                        {emp.total_hours}
                      </td>
                    </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {showForm && (
        <LaborForm
          path={labor_entries_path}
          users={assignable_labor_users}
          onClose={() => setShowForm(false)}
        />
      )}
    </div>
  );
}
