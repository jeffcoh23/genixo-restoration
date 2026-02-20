import { useState } from "react";
import { useForm, usePage } from "@inertiajs/react";
import { X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { SharedProps } from "@/types";
import type { EquipmentType, EquipmentEntry } from "../types";

interface EquipmentItemOption {
  id: number;
  identifier: string;
  model_name: string | null;
  serial_number: string | null;
}

interface EquipmentFormProps {
  path: string;
  equipment_types: EquipmentType[];
  equipment_items_by_type?: Record<string, EquipmentItemOption[]>;
  onClose: () => void;
  entry?: EquipmentEntry;
}

export default function EquipmentForm({ path, equipment_types, equipment_items_by_type = {}, onClose, entry }: EquipmentFormProps) {
  const editing = !!entry;
  const hasOtherType = editing && !entry.equipment_type_id && !!entry.equipment_type_other;
  const [useOther, setUseOther] = useState(hasOtherType);

  const { today } = usePage<SharedProps>().props;
  const { data, setData, post, patch, processing, errors } = useForm({
    equipment_type_id: entry?.equipment_type_id ? String(entry.equipment_type_id) : "",
    equipment_type_other: entry?.equipment_type_other ?? "",
    equipment_item_id: "",
    equipment_model: entry?.equipment_model ?? "",
    equipment_identifier: entry?.equipment_identifier ?? "",
    placed_at: entry?.placed_at ?? today,
    removed_at: entry?.removed_at ?? "",
    location_notes: entry?.location_notes ?? "",
  });

  // Items available for the currently selected type
  const typeItems = data.equipment_type_id ? (equipment_items_by_type[data.equipment_type_id] || []) : [];

  const handleTypeChange = (value: string) => {
    if (value === "__other__") {
      setUseOther(true);
      setData((prev) => ({ ...prev, equipment_type_id: "", equipment_type_other: "", equipment_item_id: "", equipment_model: "", equipment_identifier: "" }));
    } else {
      setUseOther(false);
      setData((prev) => ({ ...prev, equipment_type_id: value, equipment_type_other: "", equipment_item_id: "", equipment_model: "", equipment_identifier: "" }));
    }
  };

  const handleItemChange = (value: string) => {
    if (value === "__manual__" || value === "") {
      setData((prev) => ({ ...prev, equipment_item_id: "", equipment_model: "", equipment_identifier: "" }));
      return;
    }
    const item = typeItems.find((i) => String(i.id) === value);
    if (item) {
      setData((prev) => ({
        ...prev,
        equipment_item_id: value,
        equipment_model: item.model_name || "",
        equipment_identifier: item.identifier,
      }));
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const submit = editing ? patch : post;
    const url = editing ? entry!.edit_path! : path;
    submit(url, { onSuccess: () => onClose() });
  };

  const isItemSelected = data.equipment_item_id !== "";

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center">
      <div className="fixed inset-0 bg-black opacity-40" />
      <div className="relative bg-background border border-border rounded-t sm:rounded w-full sm:max-w-md p-4 shadow-lg">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-sm font-semibold">{editing ? "Edit Equipment" : "Place Equipment"}</h3>
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

          {/* Item picker — only shown when a known type is selected and items exist */}
          {!useOther && typeItems.length > 0 && (
            <div>
              <label className="text-xs font-medium text-muted-foreground">Select Unit</label>
              <select
                value={data.equipment_item_id || "__manual__"}
                onChange={(e) => handleItemChange(e.target.value)}
                className="mt-1 w-full rounded border border-input bg-background px-3 py-2 text-sm"
              >
                <option value="__manual__">Enter manually</option>
                {typeItems.map((item) => (
                  <option key={item.id} value={item.id}>
                    {item.identifier}{item.model_name ? ` — ${item.model_name}` : ""}
                  </option>
                ))}
              </select>
            </div>
          )}

          <div>
            <label className="text-xs font-medium text-muted-foreground">Model</label>
            <Input
              value={data.equipment_model}
              onChange={(e) => setData("equipment_model", e.target.value)}
              placeholder="e.g. LGR 7000XLi"
              className="mt-1"
              readOnly={isItemSelected}
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-xs font-medium text-muted-foreground">Identifier / Serial</label>
              <Input
                value={data.equipment_identifier}
                onChange={(e) => setData("equipment_identifier", e.target.value)}
                placeholder="e.g. DH-042"
                className="mt-1"
                readOnly={isItemSelected}
              />
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
          </div>

          <div className={editing ? "grid grid-cols-2 gap-3" : ""}>
            <div>
              <label className="text-xs font-medium text-muted-foreground">Placed On</label>
              <Input
                type="date"
                value={data.placed_at || ""}
                onChange={(e) => setData("placed_at", e.target.value)}
                className="mt-1"
                required
              />
            </div>
            {editing && (
              <div>
                <div className="flex items-baseline justify-between">
                  <label className="text-xs font-medium text-muted-foreground">Removed On</label>
                  {!data.removed_at ? (
                    <Button
                      type="button"
                      variant="link"
                      size="sm"
                      className="h-auto p-0 text-xs"
                      onClick={() => setData("removed_at", today)}
                    >
                      Today
                    </Button>
                  ) : (
                    <Button
                      type="button"
                      variant="link"
                      size="sm"
                      className="h-auto p-0 text-xs text-muted-foreground"
                      onClick={() => setData("removed_at", "")}
                    >
                      Clear
                    </Button>
                  )}
                </div>
                <Input
                  type="date"
                  value={data.removed_at || ""}
                  onChange={(e) => setData("removed_at", e.target.value)}
                  className="mt-1"
                />
              </div>
            )}
          </div>

          <div className="flex justify-end gap-2 pt-2">
            <Button type="button" variant="ghost" size="sm" onClick={onClose}>Cancel</Button>
            <Button type="submit" size="sm" disabled={processing}>
              {processing ? "Saving..." : editing ? "Update" : "Place Equipment"}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}
