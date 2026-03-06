import { useState } from "react";
import { router } from "@inertiajs/react";
import { Pencil, Trash2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import type { AssignableUser, LaborEntry, LaborLog } from "../types";
import IncidentPanelAddButton from "./IncidentPanelAddButton";
import LaborForm from "./LaborForm";

interface LaborPanelProps {
  labor_log: LaborLog;
  labor_entries: LaborEntry[];
  can_manage_labor: boolean;
  labor_entries_path: string;
  assignable_labor_users: AssignableUser[];
}

export default function LaborPanel({ labor_log, labor_entries, can_manage_labor, labor_entries_path, assignable_labor_users }: LaborPanelProps) {
  const [showForm, setShowForm] = useState(false);
  const [editingEntry, setEditingEntry] = useState<LaborEntry | null>(null);
  const [confirmDelete, setConfirmDelete] = useState<LaborEntry | null>(null);

  const hasData = labor_log.employees.length > 0;

  const handleDelete = (entry: LaborEntry) => {
    if (!entry.delete_path) return;
    router.delete(entry.delete_path, {
      preserveScroll: true,
      onSuccess: () => setConfirmDelete(null),
    });
  };

  return (
    <div className="flex flex-col h-full">
      {can_manage_labor && (
        <div className="flex items-center justify-center sm:justify-start gap-1 border-b border-border px-4 py-3 shrink-0">
          <IncidentPanelAddButton label="Add Labor" onClick={() => setShowForm(true)} />
        </div>
      )}

      {!hasData ? (
        <div className="flex-1 flex items-center justify-center text-muted-foreground text-sm py-12">
          No labor hours recorded yet.
        </div>
      ) : (
        <div className="flex-1 overflow-y-auto">
          {/* Summary grid */}
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

          {/* Individual entries */}
          {labor_entries.length > 0 && (
            <div className="border-t border-border">
              <div className="px-4 py-2 bg-muted/30 border-b border-border">
                <h3 className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">Entries</h3>
              </div>

              {/* Desktop table */}
              <div className="hidden sm:block">
                <table className="w-full text-sm">
                  <thead className="bg-muted/15 border-b border-border">
                    <tr>
                      <th className="px-4 py-2 text-left text-xs font-medium text-muted-foreground">Employee</th>
                      <th className="px-4 py-2 text-left text-xs font-medium text-muted-foreground">Date</th>
                      <th className="px-4 py-2 text-left text-xs font-medium text-muted-foreground">Time</th>
                      <th className="px-4 py-2 text-right text-xs font-medium text-muted-foreground">Hours</th>
                      {can_manage_labor && (
                        <th className="px-4 py-2 text-right text-xs font-medium text-muted-foreground w-[80px]" />
                      )}
                    </tr>
                  </thead>
                  <tbody>
                    {labor_entries.map((entry) => (
                      <tr key={entry.id} className="border-b border-border last:border-b-0 hover:bg-muted/20 transition-colors">
                        <td className="px-4 py-2 text-sm text-foreground">
                          {entry.user_name || "Unattributed"}
                        </td>
                        <td className="px-4 py-2 text-sm text-muted-foreground">
                          {entry.log_date_label}
                        </td>
                        <td className="px-4 py-2 text-sm text-muted-foreground">
                          {entry.started_at_label && entry.ended_at_label
                            ? `${entry.started_at_label} – ${entry.ended_at_label}`
                            : entry.time_label}
                        </td>
                        <td className="px-4 py-2 text-sm text-foreground text-right tabular-nums">
                          {entry.hours}h
                        </td>
                        {can_manage_labor && (
                          <td className="px-4 py-2 text-right">
                            <div className="flex items-center justify-end gap-1">
                              {entry.edit_path && (
                                <Button
                                  variant="ghost"
                                  size="sm"
                                  className="h-7 w-7 p-0 text-muted-foreground hover:text-foreground"
                                  onClick={() => setEditingEntry(entry)}
                                  title="Edit entry"
                                >
                                  <Pencil className="h-3.5 w-3.5" />
                                </Button>
                              )}
                              {entry.delete_path && (
                                <Button
                                  variant="ghost"
                                  size="sm"
                                  className="h-7 w-7 p-0 text-muted-foreground hover:text-destructive"
                                  onClick={() => setConfirmDelete(entry)}
                                  title="Delete entry"
                                >
                                  <Trash2 className="h-3.5 w-3.5" />
                                </Button>
                              )}
                            </div>
                          </td>
                        )}
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              {/* Mobile card stack */}
              <div className="sm:hidden divide-y divide-border">
                {labor_entries.map((entry) => (
                  <div key={entry.id} className="px-4 py-3">
                    <div className="flex items-start justify-between gap-2">
                      <div className="min-w-0">
                        <p className="text-sm font-medium text-foreground truncate">
                          {entry.user_name || "Unattributed"}
                        </p>
                        <p className="text-xs text-muted-foreground mt-0.5">
                          {entry.log_date_label}
                          {(entry.started_at_label && entry.ended_at_label) &&
                            ` · ${entry.started_at_label} – ${entry.ended_at_label}`
                          }
                        </p>
                      </div>
                      <div className="flex items-center gap-1 shrink-0">
                        <span className="text-sm font-medium text-foreground tabular-nums mr-1">
                          {entry.hours}h
                        </span>
                        {can_manage_labor && entry.edit_path && (
                          <Button
                            variant="ghost"
                            size="sm"
                            className="h-7 w-7 p-0 text-muted-foreground hover:text-foreground"
                            onClick={() => setEditingEntry(entry)}
                          >
                            <Pencil className="h-3.5 w-3.5" />
                          </Button>
                        )}
                        {can_manage_labor && entry.delete_path && (
                          <Button
                            variant="ghost"
                            size="sm"
                            className="h-7 w-7 p-0 text-muted-foreground hover:text-destructive"
                            onClick={() => setConfirmDelete(entry)}
                          >
                            <Trash2 className="h-3.5 w-3.5" />
                          </Button>
                        )}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      )}

      {/* Add labor form */}
      {showForm && (
        <LaborForm
          path={labor_entries_path}
          users={assignable_labor_users}
          onClose={() => setShowForm(false)}
        />
      )}

      {/* Edit labor form */}
      {editingEntry && (
        <LaborForm
          path={labor_entries_path}
          users={assignable_labor_users}
          entry={editingEntry}
          onClose={() => setEditingEntry(null)}
        />
      )}

      {/* Confirm delete dialog */}
      <Dialog open={!!confirmDelete} onOpenChange={(open) => !open && setConfirmDelete(null)}>
        <DialogContent className="sm:max-w-sm">
          <DialogHeader>
            <DialogTitle>Delete Labor Entry</DialogTitle>
          </DialogHeader>
          <p className="text-sm text-muted-foreground">
            Delete {confirmDelete?.hours}h entry for <span className="font-medium text-foreground">{confirmDelete?.user_name || "Unattributed"}</span> on {confirmDelete?.log_date_label}? This cannot be undone.
          </p>
          <div className="flex justify-end gap-2 pt-2">
            <Button variant="ghost" size="sm" onClick={() => setConfirmDelete(null)}>Cancel</Button>
            <Button variant="destructive" size="sm" onClick={() => confirmDelete && handleDelete(confirmDelete)}>
              Delete
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
