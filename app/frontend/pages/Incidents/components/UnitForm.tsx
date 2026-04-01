import { useForm } from "@inertiajs/react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Checkbox } from "@/components/ui/checkbox";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import type { TimelineUnit } from "../timeline-types";

interface UnitFormProps {
  path: string;
  unit?: TimelineUnit;
  onClose: () => void;
}

export default function UnitForm({ path, unit, onClose }: UnitFormProps) {
  const isEdit = !!unit;
  const { data, setData, post, patch, processing, errors } = useForm({
    unit_number: unit?.unit_number ?? "",
    needs_vacant: unit?.needs_vacant ?? false,
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
          <DialogTitle>{isEdit ? "Edit Unit" : "Add Unit"}</DialogTitle>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-3">
          <div>
            <label className="text-xs font-medium text-muted-foreground">Unit / Area Name</label>
            <Input
              value={data.unit_number}
              onChange={(e) => setData("unit_number", e.target.value)}
              className="mt-1"
              placeholder='e.g. "320", "Common Area", "Lobby"'
              autoFocus
            />
            {errors.unit_number && <p className="text-xs text-destructive mt-1">{errors.unit_number}</p>}
          </div>

          <div className="flex items-center gap-2">
            <Checkbox
              id="needs_vacant"
              checked={data.needs_vacant}
              onCheckedChange={(checked) => setData("needs_vacant", !!checked)}
            />
            <label htmlFor="needs_vacant" className="text-sm text-foreground cursor-pointer">
              Needs vacant
            </label>
          </div>

          <div className="flex justify-end gap-2 pt-2">
            <Button type="button" variant="ghost" size="sm" onClick={onClose}>Cancel</Button>
            <Button type="submit" size="sm" disabled={processing}>
              {processing ? "Saving..." : isEdit ? "Update" : "Add Unit"}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}
