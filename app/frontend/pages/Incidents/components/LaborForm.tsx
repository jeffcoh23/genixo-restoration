import { useForm, usePage } from "@inertiajs/react";
import { X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { SharedProps } from "@/types";
import type { AssignableUser, LaborEntry } from "../types";

const ROLE_SORT_ORDER: Record<string, number> = {
  "Technician": 0,
  "Manager": 1,
  "Office/Sales": 2,
  "Property Manager": 3,
  "Area Manager": 4,
  "PM Manager": 5,
};

function sortedUsers(users: AssignableUser[]): AssignableUser[] {
  return [...users].sort((a, b) => {
    const aOrder = ROLE_SORT_ORDER[a.role_label] ?? 99;
    const bOrder = ROLE_SORT_ORDER[b.role_label] ?? 99;
    if (aOrder !== bOrder) return aOrder - bOrder;
    return a.full_name.localeCompare(b.full_name);
  });
}

function calculateHours(startedAt: string, endedAt: string): string {
  if (!startedAt || !endedAt) return "";
  const [sh, sm] = startedAt.split(":").map(Number);
  const [eh, em] = endedAt.split(":").map(Number);
  let diff = (eh * 60 + em) - (sh * 60 + sm);
  if (diff <= 0) return "";
  const hours = Math.round((diff / 60) * 4) / 4; // round to nearest 0.25
  return String(hours);
}

interface LaborFormProps {
  path: string;
  users: AssignableUser[];
  onClose: () => void;
  entry?: LaborEntry;
}

export default function LaborForm({ path, users, onClose, entry }: LaborFormProps) {
  const { today } = usePage<SharedProps>().props;
  const editing = !!entry;
  const sorted = sortedUsers(users);

  const initialUserId = entry?.user_id ? String(entry.user_id) : (users.length === 1 ? String(users[0].id) : "");
  const initialRole = entry?.role_label ?? (users.length === 1 ? users[0].role_label : "");

  const { data, setData, post, patch, processing, errors } = useForm({
    user_id: initialUserId,
    role_label: initialRole,
    hours: entry ? String(entry.hours) : "",
    started_at: entry?.started_at ?? "",
    ended_at: entry?.ended_at ?? "",
    log_date: entry?.log_date ?? today,
    notes: entry?.notes ?? "",
  });

  const handleUserChange = (userId: string) => {
    const selected = users.find((u) => String(u.id) === userId);
    setData((prev) => ({
      ...prev,
      user_id: userId,
      role_label: selected ? selected.role_label : prev.role_label,
    }));
  };

  const handleTimeChange = (field: "started_at" | "ended_at", value: string) => {
    const newStarted = field === "started_at" ? value : data.started_at;
    const newEnded = field === "ended_at" ? value : data.ended_at;
    const computed = calculateHours(newStarted, newEnded);
    setData((prev) => ({
      ...prev,
      [field]: value,
      ...(computed ? { hours: computed } : {}),
    }));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const submit = editing ? patch : post;
    const url = editing ? entry!.edit_path! : path;
    submit(url, { onSuccess: () => onClose() });
  };

  const hasComputedHours = !!(data.started_at && data.ended_at && calculateHours(data.started_at, data.ended_at));

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center">
      <div className="fixed inset-0 bg-black opacity-40" onClick={onClose} />
      <div className="relative bg-background border border-border rounded-t sm:rounded w-full sm:max-w-md p-4 shadow-lg">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-sm font-semibold">{editing ? "Edit Labor Entry" : "Add Labor Entry"}</h3>
          <Button variant="ghost" size="sm" className="h-7 w-7 p-0" onClick={onClose}>
            <X className="h-4 w-4" />
          </Button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-3">
          {users.length > 1 && (
            <div>
              <label className="text-xs font-medium text-muted-foreground">Worker</label>
              <select
                value={data.user_id}
                onChange={(e) => handleUserChange(e.target.value)}
                className="mt-1 w-full rounded border border-input bg-background px-3 py-2 text-sm"
              >
                <option value="">Unattributed</option>
                {sorted.map((u) => (
                  <option key={u.id} value={u.id}>{u.full_name} ({u.role_label})</option>
                ))}
              </select>
            </div>
          )}

          <div>
            <label className="text-xs font-medium text-muted-foreground">
              Role Label <span className="text-destructive">*</span>
            </label>
            <Input
              value={data.role_label}
              onChange={(e) => setData("role_label", e.target.value)}
              placeholder="e.g. Technician, Supervisor"
              className="mt-1"
              required
            />
            {errors.role_label && <p className="text-xs text-destructive mt-1">{errors.role_label}</p>}
          </div>

          <div>
            <label className="text-xs font-medium text-muted-foreground">
              Date <span className="text-destructive">*</span>
            </label>
            <Input
              type="date"
              value={data.log_date}
              onChange={(e) => setData("log_date", e.target.value)}
              className="mt-1"
              required
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-xs font-medium text-muted-foreground">
                Start Time <span className="text-destructive">*</span>
              </label>
              <Input
                type="time"
                value={data.started_at}
                onChange={(e) => handleTimeChange("started_at", e.target.value)}
                className="mt-1"
                required
              />
            </div>
            <div>
              <label className="text-xs font-medium text-muted-foreground">
                End Time <span className="text-muted-foreground/60 font-normal">(optional)</span>
              </label>
              <Input
                type="time"
                value={data.ended_at}
                onChange={(e) => handleTimeChange("ended_at", e.target.value)}
                className="mt-1"
              />
            </div>
          </div>

          <div>
            <label className="text-xs font-medium text-muted-foreground">
              Hours <span className="text-destructive">*</span>
            </label>
            <Input
              type="number"
              step="0.25"
              min="0"
              value={data.hours}
              onChange={(e) => setData("hours", e.target.value)}
              className="mt-1"
              required
              readOnly={hasComputedHours}
            />
            {hasComputedHours && (
              <p className="text-xs text-muted-foreground mt-1">Calculated from start/end time</p>
            )}
            {errors.hours && <p className="text-xs text-destructive mt-1">{errors.hours}</p>}
          </div>

          <div>
            <label className="text-xs font-medium text-muted-foreground">
              Notes <span className="text-muted-foreground/60 font-normal">(optional)</span>
            </label>
            <textarea
              value={data.notes}
              onChange={(e) => setData("notes", e.target.value)}
              rows={2}
              className="mt-1 w-full rounded border border-input bg-background px-3 py-2 text-sm resize-none"
              placeholder="What was done?"
            />
          </div>

          <div className="flex justify-end gap-2 pt-2">
            <Button type="button" variant="ghost" size="sm" onClick={onClose}>Cancel</Button>
            <Button type="submit" size="sm" disabled={processing}>
              {processing ? "Saving..." : editing ? "Update" : "Add Labor"}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}
