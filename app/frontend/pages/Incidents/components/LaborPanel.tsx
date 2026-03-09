import { useMemo, useState } from "react";
import { router } from "@inertiajs/react";
import { Clock, Pencil, Trash2, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
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

const PAGE_SIZE = 10;

export default function LaborPanel({ labor_log, labor_entries, can_manage_labor, labor_entries_path, assignable_labor_users }: LaborPanelProps) {
  const [showForm, setShowForm] = useState(false);
  const [editingEntry, setEditingEntry] = useState<LaborEntry | null>(null);
  const [confirmDelete, setConfirmDelete] = useState<LaborEntry | null>(null);
  const [visibleCount, setVisibleCount] = useState(PAGE_SIZE);

  // Filters
  const [employee, setEmployee] = useState("all");
  const [role, setRole] = useState("all");
  const [fromDate, setFromDate] = useState("");
  const [toDate, setToDate] = useState("");

  const hasData = labor_log.employees.length > 0;

  const employeeOptions = useMemo(
    () => [...new Map(
      labor_entries
        .map((e) => [e.user_name || e.role_label, e.user_name || e.role_label])
    ).values()].sort((a, b) => a.localeCompare(b)),
    [labor_entries]
  );

  const roleOptions = useMemo(
    () => [...new Set(labor_entries.map((e) => e.role_label))].sort((a, b) => a.localeCompare(b)),
    [labor_entries]
  );

  const filteredEntries = useMemo(() => {
    return labor_entries.filter((entry) => {
      if (employee !== "all" && (entry.user_name || entry.role_label) !== employee) return false;
      if (role !== "all" && entry.role_label !== role) return false;
      if (fromDate && entry.log_date < fromDate) return false;
      if (toDate && entry.log_date > toDate) return false;
      return true;
    });
  }, [labor_entries, employee, role, fromDate, toDate]);

  const visibleEntries = filteredEntries.slice(0, visibleCount);
  const hasMore = visibleCount < filteredEntries.length;
  const hasActiveFilters = employee !== "all" || role !== "all" || fromDate !== "" || toDate !== "";

  const clearFilters = () => {
    setEmployee("all");
    setRole("all");
    setFromDate("");
    setToDate("");
    setVisibleCount(PAGE_SIZE);
  };

  const totalFilteredHours = useMemo(() => {
    let sum = 0;
    for (const e of filteredEntries) sum += e.hours;
    return sum;
  }, [filteredEntries]);

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
            <div className="mt-6 border-t-2 border-border">
              {/* Entries header + count */}
              <div className="flex items-center justify-between px-4 py-2.5 bg-muted/40 border-b border-border">
                <h3 className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">Entries</h3>
                <span className="text-xs text-muted-foreground tabular-nums">
                  {filteredEntries.length} {filteredEntries.length === 1 ? "entry" : "entries"}
                  {hasActiveFilters && ` of ${labor_entries.length}`}
                  {" · "}
                  {totalFilteredHours}h total
                </span>
              </div>

              {/* Filters */}
              <div className="border-b border-border bg-card/60 px-4 py-2.5">
                <div className="grid grid-cols-1 sm:grid-cols-4 gap-2">
                  <select
                    value={employee}
                    onChange={(e) => { setEmployee(e.target.value); setVisibleCount(PAGE_SIZE); }}
                    className="h-9 rounded-md border border-input bg-background px-3 text-sm"
                  >
                    <option value="all">All employees</option>
                    {employeeOptions.map((name) => (
                      <option key={name} value={name}>{name}</option>
                    ))}
                  </select>
                  <select
                    value={role}
                    onChange={(e) => { setRole(e.target.value); setVisibleCount(PAGE_SIZE); }}
                    className="h-9 rounded-md border border-input bg-background px-3 text-sm"
                  >
                    <option value="all">All roles</option>
                    {roleOptions.map((r) => (
                      <option key={r} value={r}>{r}</option>
                    ))}
                  </select>
                  <Input
                    type="date"
                    value={fromDate}
                    onChange={(e) => { setFromDate(e.target.value); setVisibleCount(PAGE_SIZE); }}
                    placeholder="From"
                    className="h-9 text-sm"
                  />
                  <div className="flex gap-2">
                    <Input
                      type="date"
                      value={toDate}
                      onChange={(e) => { setToDate(e.target.value); setVisibleCount(PAGE_SIZE); }}
                      placeholder="To"
                      className="h-9 text-sm flex-1"
                    />
                    {hasActiveFilters && (
                      <Button
                        variant="ghost"
                        size="sm"
                        className="h-9 px-2 text-muted-foreground hover:text-foreground shrink-0"
                        onClick={clearFilters}
                        title="Clear filters"
                      >
                        <X className="h-4 w-4" />
                      </Button>
                    )}
                  </div>
                </div>
              </div>

              {filteredEntries.length === 0 ? (
                <div className="px-4 py-8 text-center text-sm text-muted-foreground">
                  No entries match the current filters.
                </div>
              ) : (
                <>
                  {/* Desktop table */}
                  <div className="hidden sm:block">
                    <table className="w-full text-sm">
                      <thead className="bg-muted border-b border-border sticky top-0 z-10">
                        <tr>
                          <th className="px-4 py-2.5 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground">Employee</th>
                          <th className="px-4 py-2.5 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground">Date</th>
                          <th className="px-4 py-2.5 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground">Time</th>
                          <th className="px-4 py-2.5 text-right text-xs font-semibold uppercase tracking-wide text-muted-foreground">Hours</th>
                          {can_manage_labor && (
                            <th className="px-4 py-2.5 text-right text-xs font-semibold uppercase tracking-wide text-muted-foreground w-[80px]" />
                          )}
                        </tr>
                      </thead>
                      <tbody>
                        {visibleEntries.map((entry, i) => (
                          <tr key={entry.id} className={`border-b border-border last:border-b-0 transition-colors hover:bg-muted/30 ${i % 2 === 0 ? "bg-background" : "bg-muted/10"}`}>
                            <td className="px-4 py-2.5 text-sm font-medium text-foreground">
                              {entry.user_name || entry.role_label}
                            </td>
                            <td className="px-4 py-2.5 text-sm text-muted-foreground">
                              {entry.log_date_label}
                            </td>
                            <td className="px-4 py-2.5 text-sm text-muted-foreground">
                              {entry.started_at_label && entry.ended_at_label
                                ? `${entry.started_at_label} – ${entry.ended_at_label}`
                                : entry.time_label}
                            </td>
                            <td className="px-4 py-2.5 text-right">
                              <span className="inline-flex items-center gap-1 text-sm font-medium text-foreground tabular-nums">
                                <Clock className="h-3 w-3 text-muted-foreground/50" />
                                {entry.hours}h
                              </span>
                            </td>
                            {can_manage_labor && (
                              <td className="px-4 py-2.5 text-right">
                                <div className="flex items-center justify-end gap-0.5">
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
                    {visibleEntries.map((entry) => (
                      <div key={entry.id} className="px-4 py-3">
                        <div className="flex items-start justify-between gap-2">
                          <div className="min-w-0">
                            <p className="text-sm font-medium text-foreground truncate">
                              {entry.user_name || entry.role_label}
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

                  {/* Pagination footer */}
                  {filteredEntries.length > PAGE_SIZE && (
                    <div className="flex items-center justify-between px-4 py-2.5 border-t border-border bg-muted/30">
                      <p className="text-xs text-muted-foreground">
                        Showing {visibleEntries.length} of {filteredEntries.length}
                      </p>
                      {hasMore && (
                        <Button
                          variant="outline"
                          size="sm"
                          className="h-8 text-xs"
                          onClick={() => setVisibleCount((prev) => prev + PAGE_SIZE)}
                        >
                          Show more
                        </Button>
                      )}
                    </div>
                  )}
                </>
              )}
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
            Delete {confirmDelete?.hours}h entry for <span className="font-medium text-foreground">{confirmDelete?.user_name || confirmDelete?.role_label}</span> on {confirmDelete?.log_date_label}? This cannot be undone.
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
