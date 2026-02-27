import { useForm, usePage } from "@inertiajs/react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { SharedProps } from "@/types";

interface MoisturePointFormProps {
  createPath: string;
  onClose: () => void;
}

export default function MoisturePointForm({ createPath, onClose }: MoisturePointFormProps) {
  const { today } = usePage<SharedProps>().props;

  const { data, setData, post, processing, errors } = useForm({
    point: {
      unit: "",
      room: "",
      item: "",
      material: "",
      goal: "",
      measurement_unit: "Pts",
    },
    reading_value: "",
    reading_date: today,
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    post(createPath, { onSuccess: () => onClose() });
  };

  const setPointField = (field: string, value: string) => {
    setData("point", { ...data.point, [field]: value });
  };

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="sm:max-w-lg max-h-[85vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Add Measurement Point</DialogTitle>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-3">
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-xs font-medium text-muted-foreground">
                Unit <span className="text-destructive">*</span>
              </label>
              <Input
                value={data.point.unit}
                onChange={(e) => setPointField("unit", e.target.value)}
                placeholder="e.g. 1107"
                className="mt-1"
                required
              />
              {errors["point.unit"] && <p className="text-xs text-destructive mt-0.5">{errors["point.unit"]}</p>}
            </div>
            <div>
              <label className="text-xs font-medium text-muted-foreground">
                Room <span className="text-destructive">*</span>
              </label>
              <Input
                value={data.point.room}
                onChange={(e) => setPointField("room", e.target.value)}
                placeholder="e.g. Bathroom"
                className="mt-1"
                required
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-xs font-medium text-muted-foreground">
                Item <span className="text-destructive">*</span>
              </label>
              <Input
                value={data.point.item}
                onChange={(e) => setPointField("item", e.target.value)}
                placeholder="e.g. Wall, Ceiling"
                className="mt-1"
                required
              />
            </div>
            <div>
              <label className="text-xs font-medium text-muted-foreground">
                Material <span className="text-destructive">*</span>
              </label>
              <Input
                value={data.point.material}
                onChange={(e) => setPointField("material", e.target.value)}
                placeholder="e.g. Drywall, Wood"
                className="mt-1"
                required
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-xs font-medium text-muted-foreground">
                Goal <span className="text-destructive">*</span>
              </label>
              <Input
                value={data.point.goal}
                onChange={(e) => setPointField("goal", e.target.value)}
                placeholder="e.g. 7.5, Dry"
                className="mt-1"
                required
              />
            </div>
            <div>
              <label className="text-xs font-medium text-muted-foreground">
                Unit <span className="text-destructive">*</span>
              </label>
              <Select value={data.point.measurement_unit} onValueChange={(v) => setPointField("measurement_unit", v)}>
                <SelectTrigger className="mt-1">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="Pts">Pts</SelectItem>
                  <SelectItem value="%">%</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="border-t border-border pt-3 mt-3">
            <p className="text-xs text-muted-foreground mb-2">Optional: add first reading</p>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-xs font-medium text-muted-foreground">Date</label>
                <Input
                  type="date"
                  value={data.reading_date}
                  onChange={(e) => setData("reading_date", e.target.value)}
                  className="mt-1"
                />
              </div>
              <div>
                <label className="text-xs font-medium text-muted-foreground">Value</label>
                <Input
                  type="number"
                  step="0.1"
                  min="0"
                  value={data.reading_value}
                  onChange={(e) => setData("reading_value", e.target.value)}
                  placeholder="e.g. 18.2"
                  className="mt-1"
                />
              </div>
            </div>
          </div>

          <div className="flex justify-end gap-2 pt-2">
            <Button type="button" variant="outline" onClick={onClose}>Cancel</Button>
            <Button type="submit" disabled={processing}>
              {processing ? "Saving..." : "Add Point"}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}
