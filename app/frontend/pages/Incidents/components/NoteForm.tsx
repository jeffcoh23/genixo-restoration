import { useForm, usePage } from "@inertiajs/react";
import { X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { SharedProps } from "@/types";

interface NoteFormProps {
  path: string;
  onClose: () => void;
}

export default function NoteForm({ path, onClose }: NoteFormProps) {
  const { today } = usePage<SharedProps>().props;
  const { data, setData, post, processing, errors } = useForm({
    note_text: "",
    log_date: today,
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
          <h3 className="text-sm font-semibold">Add Note</h3>
          <Button variant="ghost" size="sm" className="h-7 w-7 p-0" onClick={onClose}>
            <X className="h-4 w-4" />
          </Button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-3">
          <div>
            <label className="text-xs font-medium text-muted-foreground">Note</label>
            <textarea
              value={data.note_text}
              onChange={(e) => setData("note_text", e.target.value)}
              rows={4}
              className="mt-1 w-full rounded border border-input bg-background px-3 py-2 text-sm resize-none"
              placeholder="What was done? Observations, measurements, next steps..."
              autoFocus
            />
            {errors.note_text && <p className="text-xs text-destructive mt-1">{errors.note_text}</p>}
          </div>

          <div>
            <label className="text-xs font-medium text-muted-foreground">Date</label>
            <Input
              type="date"
              value={data.log_date}
              onChange={(e) => setData("log_date", e.target.value)}
              className="mt-1 w-40"
            />
          </div>

          <div className="flex justify-end gap-2 pt-2">
            <Button type="button" variant="ghost" size="sm" onClick={onClose}>Cancel</Button>
            <Button type="submit" size="sm" disabled={processing}>
              {processing ? "Saving..." : "Add Note"}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}
