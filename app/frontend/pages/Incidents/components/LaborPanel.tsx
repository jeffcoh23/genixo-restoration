import { useState } from "react";
import { router } from "@inertiajs/react";
import { Pencil, Plus, Trash2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import type { AssignableUser, LaborEntry } from "../types";
import LaborForm from "./LaborForm";

interface LaborPanelProps {
  labor_entries: LaborEntry[];
  can_manage_labor: boolean;
  labor_entries_path: string;
  assignable_labor_users: AssignableUser[];
}

export default function LaborPanel({ labor_entries, can_manage_labor, labor_entries_path, assignable_labor_users }: LaborPanelProps) {
  const [showForm, setShowForm] = useState(false);
  const [editingEntry, setEditingEntry] = useState<LaborEntry | null>(null);
  const [confirmDelete, setConfirmDelete] = useState<LaborEntry | null>(null);

  const handleDelete = (entry: LaborEntry) => {
    if (!entry.edit_path) return;
    router.delete(entry.edit_path, { preserveScroll: true });
    setConfirmDelete(null);
  };

  return (
    <div className="flex flex-col h-full">
      {can_manage_labor && (
        <div className="flex items-center gap-1 border-b border-border px-3 py-2 shrink-0">
          <Button variant="ghost" size="sm" className="h-7 text-xs gap-1" onClick={() => setShowForm(true)}>
            <Plus className="h-3 w-3" />
            Add Labor
          </Button>
        </div>
      )}

      <div className="flex-1 overflow-y-auto">
        {labor_entries.length === 0 ? (
          <div className="flex-1 flex items-center justify-center text-muted-foreground text-sm py-12">
            No labor hours recorded yet.
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-muted/30 border-b border-border sticky top-0">
                <tr>
                  <th className="px-3 py-2 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground">Worker</th>
                  <th className="px-3 py-2 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground">Role</th>
                  <th className="px-3 py-2 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground w-[90px]">Date</th>
                  <th className="px-3 py-2 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground w-[100px]">Time</th>
                  <th className="px-3 py-2 text-right text-xs font-semibold uppercase tracking-wide text-muted-foreground w-[60px]">Hours</th>
                  {can_manage_labor && <th className="px-3 py-2 w-[60px]" />}
                </tr>
              </thead>
              <tbody>
                {labor_entries.map((entry) => (
                  <tr key={entry.id} className="border-b border-border last:border-b-0">
                    <td className="px-3 py-2 text-sm font-medium text-foreground">{entry.user_name || "Unattributed"}</td>
                    <td className="px-3 py-2 text-sm text-muted-foreground">{entry.role_label}</td>
                    <td className="px-3 py-2 text-sm text-muted-foreground">{entry.log_date_label}</td>
                    <td className="px-3 py-2 text-sm text-muted-foreground">
                      {entry.started_at_label && entry.ended_at_label
                        ? `${entry.started_at_label}–${entry.ended_at_label}`
                        : "—"}
                    </td>
                    <td className="px-3 py-2 text-sm text-muted-foreground text-right tabular-nums">{entry.hours}</td>
                    {can_manage_labor && (
                      <td className="px-2 py-2">
                        <div className="flex items-center gap-0.5">
                          {entry.edit_path && (
                            <Button
                              variant="ghost"
                              size="sm"
                              className="h-6 w-6 p-0 text-muted-foreground hover:text-foreground"
                              onClick={() => setEditingEntry(entry)}
                              title="Edit"
                            >
                              <Pencil className="h-3 w-3" />
                            </Button>
                          )}
                          {entry.edit_path && (
                            <Button
                              variant="ghost"
                              size="sm"
                              className="h-6 w-6 p-0 text-muted-foreground hover:text-destructive"
                              onClick={() => setConfirmDelete(entry)}
                              title="Delete"
                            >
                              <Trash2 className="h-3 w-3" />
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
        )}
      </div>

      {showForm && (
        <LaborForm
          path={labor_entries_path}
          users={assignable_labor_users}
          onClose={() => setShowForm(false)}
        />
      )}

      {editingEntry && editingEntry.edit_path && (
        <LaborForm
          path={labor_entries_path}
          users={assignable_labor_users}
          onClose={() => setEditingEntry(null)}
          entry={editingEntry}
        />
      )}

      {confirmDelete && (
        <div className="fixed inset-0 z-50 flex items-center justify-center">
          <div className="fixed inset-0 bg-black opacity-40" onClick={() => setConfirmDelete(null)} />
          <div className="relative bg-background border border-border rounded w-full max-w-sm p-4 shadow-lg">
            <p className="text-sm">
              Delete labor entry for <span className="font-medium">{confirmDelete.user_name || "Unattributed"}</span> on {confirmDelete.log_date_label}?
            </p>
            <div className="flex justify-end gap-2 mt-4">
              <Button variant="ghost" size="sm" onClick={() => setConfirmDelete(null)}>Cancel</Button>
              <Button variant="destructive" size="sm" onClick={() => handleDelete(confirmDelete)}>Delete</Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
