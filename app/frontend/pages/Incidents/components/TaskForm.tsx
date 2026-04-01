import { useForm, usePage } from "@inertiajs/react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { SharedProps } from "@/types";
import type { TimelineTask } from "../timeline-types";

interface TaskFormProps {
  path: string;
  unitName: string;
  task?: TimelineTask;
  onClose: () => void;
}

export default function TaskForm({ path, unitName, task, onClose }: TaskFormProps) {
  const { today } = usePage<SharedProps>().props;
  const isEdit = !!task;
  const { data, setData, post, patch, processing, errors } = useForm({
    activity: task?.activity ?? "",
    start_date: task?.start_date ?? today,
    end_date: task?.end_date ?? today,
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const method = isEdit ? patch : post;
    method(path, { onSuccess: () => onClose() });
  };

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="sm:max-w-sm">
        <DialogHeader>
          <DialogTitle>{isEdit ? "Edit Task" : `Add Task — ${unitName}`}</DialogTitle>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-3">
          <div>
            <label className="text-xs font-medium text-muted-foreground">Activity</label>
            <Input
              value={data.activity}
              onChange={(e) => setData("activity", e.target.value)}
              className="mt-1"
              placeholder='e.g. "Remediation", "Rebuild", "Painting"'
              autoFocus
            />
            {errors.activity && <p className="text-xs text-destructive mt-1">{errors.activity}</p>}
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-xs font-medium text-muted-foreground">Start Date</label>
              <Input
                type="date"
                value={data.start_date}
                onChange={(e) => setData("start_date", e.target.value)}
                className="mt-1"
              />
              {errors.start_date && <p className="text-xs text-destructive mt-1">{errors.start_date}</p>}
            </div>
            <div>
              <label className="text-xs font-medium text-muted-foreground">End Date</label>
              <Input
                type="date"
                value={data.end_date}
                onChange={(e) => setData("end_date", e.target.value)}
                className="mt-1"
              />
              {errors.end_date && <p className="text-xs text-destructive mt-1">{errors.end_date}</p>}
            </div>
          </div>

          <div className="flex justify-end gap-2 pt-2">
            <Button type="button" variant="ghost" size="sm" onClick={onClose}>Cancel</Button>
            <Button type="submit" size="sm" disabled={processing}>
              {processing ? "Saving..." : isEdit ? "Update" : "Add Task"}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}
