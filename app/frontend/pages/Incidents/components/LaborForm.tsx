import { useForm, usePage } from "@inertiajs/react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { SharedProps } from "@/types";
import type { AssignableUser, LaborEntry } from "../types";

interface LaborFormProps {
  path: string;
  users: AssignableUser[];
  onClose: () => void;
  entry?: LaborEntry;
}

export default function LaborForm({ path, users, onClose, entry }: LaborFormProps) {
  const { today } = usePage<SharedProps>().props;
  const editing = !!entry;
  const initialUserId = entry?.user_id ? String(entry.user_id) : (users.length === 1 ? String(users[0].id) : "");
  const initialRole = entry?.role_label ?? (users.length === 1 ? users[0].role_label : "");

  const { data, setData, post, patch, processing, errors } = useForm({
    user_id: initialUserId,
    role_label: initialRole,
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

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const submit = editing ? patch : post;
    const url = editing ? entry!.edit_path! : path;
    submit(url, { onSuccess: () => onClose() });
  };

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>{editing ? "Edit Labor Entry" : "Add Labor Entry"}</DialogTitle>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-3">
          {users.length > 1 && (
            <div>
              <label className="text-xs font-medium text-muted-foreground">Worker</label>
              <Select value={data.user_id || "unattributed"} onValueChange={(v) => handleUserChange(v === "unattributed" ? "" : v)}>
                <SelectTrigger className="mt-1">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="unattributed">Unattributed</SelectItem>
                  {users.map((u) => (
                    <SelectItem key={u.id} value={String(u.id)}>{u.full_name} ({u.role_label})</SelectItem>
                  ))}
                </SelectContent>
              </Select>
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
                onChange={(e) => setData("started_at", e.target.value)}
                className="mt-1"
                required
              />
            </div>
            <div>
              <label className="text-xs font-medium text-muted-foreground">
                End Time <span className="text-destructive">*</span>
              </label>
              <Input
                type="time"
                value={data.ended_at}
                onChange={(e) => setData("ended_at", e.target.value)}
                className="mt-1"
                required
              />
            </div>
          </div>

          <div>
            <label className="text-xs font-medium text-muted-foreground">
              Notes <span className="text-muted-foreground font-normal">(optional)</span>
            </label>
            <Textarea
              value={data.notes}
              onChange={(e) => setData("notes", e.target.value)}
              rows={2}
              className="mt-1 resize-none"
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
      </DialogContent>
    </Dialog>
  );
}
