import { useForm, usePage } from "@inertiajs/react";
import { X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { SharedProps } from "@/types";
import type { AssignableUser } from "../types";

interface LaborFormProps {
  path: string;
  users: AssignableUser[];
  onClose: () => void;
}

export default function LaborForm({ path, users, onClose }: LaborFormProps) {
  const { today } = usePage<SharedProps>().props;
  const { data, setData, post, processing, errors } = useForm({
    role_label: "",
    hours: "",
    started_at: "",
    ended_at: "",
    log_date: today,
    notes: "",
    user_id: users.length === 1 ? String(users[0].id) : "",
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    post(path, { onSuccess: () => onClose() });
  };

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center">
      <div className="fixed inset-0 bg-black opacity-40" onClick={onClose} />
      <div className="relative bg-background border border-border rounded-t sm:rounded w-full sm:max-w-md p-4 shadow-lg">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-sm font-semibold">Add Labor Entry</h3>
          <Button variant="ghost" size="sm" className="h-7 w-7 p-0" onClick={onClose}>
            <X className="h-4 w-4" />
          </Button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-3">
          <div>
            <label className="text-xs font-medium text-muted-foreground">Role Label</label>
            <Input
              value={data.role_label}
              onChange={(e) => setData("role_label", e.target.value)}
              placeholder="e.g. Technician, Supervisor"
              className="mt-1"
            />
            {errors.role_label && <p className="text-xs text-destructive mt-1">{errors.role_label}</p>}
          </div>

          {users.length > 1 && (
            <div>
              <label className="text-xs font-medium text-muted-foreground">Worker</label>
              <select
                value={data.user_id}
                onChange={(e) => setData("user_id", e.target.value)}
                className="mt-1 w-full rounded border border-input bg-background px-3 py-2 text-sm"
              >
                <option value="">Unattributed</option>
                {users.map((u) => (
                  <option key={u.id} value={u.id}>{u.full_name} ({u.role_label})</option>
                ))}
              </select>
            </div>
          )}

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-xs font-medium text-muted-foreground">Hours</label>
              <Input
                type="number"
                step="0.25"
                min="0"
                value={data.hours}
                onChange={(e) => setData("hours", e.target.value)}
                className="mt-1"
              />
              {errors.hours && <p className="text-xs text-destructive mt-1">{errors.hours}</p>}
            </div>
            <div>
              <label className="text-xs font-medium text-muted-foreground">Date</label>
              <Input
                type="date"
                value={data.log_date}
                onChange={(e) => setData("log_date", e.target.value)}
                className="mt-1"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-xs font-medium text-muted-foreground">Start Time</label>
              <Input
                type="time"
                value={data.started_at}
                onChange={(e) => setData("started_at", e.target.value)}
                className="mt-1"
              />
            </div>
            <div>
              <label className="text-xs font-medium text-muted-foreground">End Time</label>
              <Input
                type="time"
                value={data.ended_at}
                onChange={(e) => setData("ended_at", e.target.value)}
                className="mt-1"
              />
            </div>
          </div>

          <div>
            <label className="text-xs font-medium text-muted-foreground">Notes</label>
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
              {processing ? "Saving..." : "Add Labor"}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}
