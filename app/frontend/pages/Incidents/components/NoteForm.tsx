import { useForm, usePage } from "@inertiajs/react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
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
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Add Note</DialogTitle>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-3">
          <div>
            <label className="text-xs font-medium text-muted-foreground">Note</label>
            <Textarea
              value={data.note_text}
              onChange={(e) => setData("note_text", e.target.value)}
              rows={4}
              className="mt-1 resize-none"
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
      </DialogContent>
    </Dialog>
  );
}
