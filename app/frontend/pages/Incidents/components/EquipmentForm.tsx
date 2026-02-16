import { useState } from "react";
import { useForm } from "@inertiajs/react";
import { X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import type { EquipmentType } from "../types";

interface EquipmentFormProps {
  path: string;
  equipment_types: EquipmentType[];
  onClose: () => void;
}

export default function EquipmentForm({ path, equipment_types, onClose }: EquipmentFormProps) {
  const [useOther, setUseOther] = useState(false);

  const { data, setData, post, processing, errors } = useForm({
    equipment_type_id: "",
    equipment_type_other: "",
    equipment_identifier: "",
    placed_at: new Date().toISOString().slice(0, 16),
    location_notes: "",
  });

  const handleTypeChange = (value: string) => {
    if (value === "__other__") {
      setUseOther(true);
      setData("equipment_type_id", "");
    } else {
      setUseOther(false);
      setData((prev) => ({ ...prev, equipment_type_id: value, equipment_type_other: "" }));
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    post(path, { onSuccess: () => onClose() });
  };

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center">
      <div className="fixed inset-0 bg-black/40" onClick={onClose} />
      <div className="relative bg-background border border-border rounded-t sm:rounded w-full sm:max-w-md p-4 shadow-lg">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-sm font-semibold">Place Equipment</h3>
          <Button variant="ghost" size="sm" className="h-7 w-7 p-0" onClick={onClose}>
            <X className="h-4 w-4" />
          </Button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-3">
          <div>
            <label className="text-xs font-medium text-muted-foreground">Equipment Type</label>
            <select
              value={useOther ? "__other__" : data.equipment_type_id}
              onChange={(e) => handleTypeChange(e.target.value)}
              className="mt-1 w-full rounded border border-input bg-background px-3 py-2 text-sm"
            >
              <option value="">Select type...</option>
              {equipment_types.map((t) => (
                <option key={t.id} value={t.id}>{t.name}</option>
              ))}
              <option value="__other__">Other (specify)</option>
            </select>
            {(errors as Record<string, string>).base && (
              <p className="text-xs text-destructive mt-1">{(errors as Record<string, string>).base}</p>
            )}
          </div>

          {useOther && (
            <div>
              <label className="text-xs font-medium text-muted-foreground">Other Type</label>
              <Input
                value={data.equipment_type_other}
                onChange={(e) => setData("equipment_type_other", e.target.value)}
                placeholder="e.g. Industrial Blower"
                className="mt-1"
              />
            </div>
          )}

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-xs font-medium text-muted-foreground">Identifier / Serial</label>
              <Input
                value={data.equipment_identifier}
                onChange={(e) => setData("equipment_identifier", e.target.value)}
                placeholder="e.g. DH-042"
                className="mt-1"
              />
            </div>
            <div>
              <label className="text-xs font-medium text-muted-foreground">Placed At</label>
              <Input
                type="datetime-local"
                value={data.placed_at}
                onChange={(e) => setData("placed_at", e.target.value)}
                className="mt-1"
              />
            </div>
          </div>

          <div>
            <label className="text-xs font-medium text-muted-foreground">Location</label>
            <Input
              value={data.location_notes}
              onChange={(e) => setData("location_notes", e.target.value)}
              placeholder="e.g. Unit 238, bedroom"
              className="mt-1"
            />
          </div>

          <div className="flex justify-end gap-2 pt-2">
            <Button type="button" variant="ghost" size="sm" onClick={onClose}>Cancel</Button>
            <Button type="submit" size="sm" disabled={processing}>
              {processing ? "Saving..." : "Place Equipment"}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}
