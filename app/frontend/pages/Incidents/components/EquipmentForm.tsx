import { useMemo, useRef, useState } from "react";
import { useForm, usePage } from "@inertiajs/react";
import { Lock, Search } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { SharedProps } from "@/types";
import type { EquipmentType, EquipmentEntry } from "../types";

interface EquipmentItemOption {
  id: number;
  identifier: string;
  tag_number: string | null;
  make: string | null;
  model_name: string | null;
}

interface SearchableItem extends EquipmentItemOption {
  type_id: string;
  type_name: string;
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
  const [searchQuery, setSearchQuery] = useState("");
  const [showResults, setShowResults] = useState(false);
  const searchRef = useRef<HTMLDivElement>(null);

  const { today } = usePage<SharedProps>().props;
  const { data, setData, post, patch, processing, errors } = useForm({
    equipment_type_id: entry?.equipment_type_id ? String(entry.equipment_type_id) : "",
    equipment_type_other: entry?.equipment_type_other ?? "",
    equipment_item_id: entry?.equipment_item_id ? String(entry.equipment_item_id) : "",
    equipment_make: entry?.equipment_make ?? "",
    equipment_model: entry?.equipment_model ?? "",
    equipment_identifier: entry?.equipment_identifier ?? "",
    tag_number: entry?.tag_number ?? "",
    placed_at: entry?.placed_at ?? today,
    removed_at: entry?.removed_at ?? "",
    location_notes: entry?.location_notes ?? "",
  });

  // Flat searchable list of all inventory items across all types
  const allItems = useMemo<SearchableItem[]>(() =>
    Object.entries(equipment_items_by_type).flatMap(([typeId, items]) => {
      const type = equipment_types.find((t) => String(t.id) === typeId);
      return items.map((item) => ({ ...item, type_id: typeId, type_name: type?.name ?? "" }));
    }),
    [equipment_items_by_type, equipment_types]
  );

  const searchResults = useMemo<SearchableItem[]>(() => {
    const q = searchQuery.trim().toLowerCase();
    if (!q) return [];
    return allItems.filter((item) =>
      item.identifier.toLowerCase().includes(q) ||
      (item.tag_number && item.tag_number.toLowerCase().includes(q)) ||
      (item.make && item.make.toLowerCase().includes(q)) ||
      (item.model_name && item.model_name.toLowerCase().includes(q)) ||
      item.type_name.toLowerCase().includes(q)
    ).slice(0, 10);
  }, [searchQuery, allItems]);

  // Items available for the currently selected type
  const typeItems = data.equipment_type_id ? (equipment_items_by_type[data.equipment_type_id] || []) : [];

  const handleTypeChange = (value: string) => {
    if (value === "__other__") {
      setUseOther(true);
      setData((prev) => ({ ...prev, equipment_type_id: "", equipment_type_other: "", equipment_item_id: "", equipment_make: "", equipment_model: "", equipment_identifier: "", tag_number: "" }));
    } else {
      setUseOther(false);
      setData((prev) => ({ ...prev, equipment_type_id: value, equipment_type_other: "", equipment_item_id: "", equipment_make: "", equipment_model: "", equipment_identifier: "", tag_number: "" }));
    }
  };

  const handleItemChange = (value: string) => {
    if (value === "__manual__" || value === "") {
      setData((prev) => ({ ...prev, equipment_item_id: "", equipment_make: "", equipment_model: "", equipment_identifier: "", tag_number: "" }));
      return;
    }
    const item = typeItems.find((i) => String(i.id) === value);
    if (item) {
      setData((prev) => ({
        ...prev,
        equipment_item_id: value,
        equipment_make: item.make || "",
        equipment_model: item.model_name || "",
        equipment_identifier: item.identifier,
        tag_number: item.tag_number || "",
      }));
    }
  };

  const handleQuickSelect = (item: SearchableItem) => {
    setUseOther(false);
    setSearchQuery("");
    setShowResults(false);
    setData((prev) => ({
      ...prev,
      equipment_type_id: item.type_id,
      equipment_type_other: "",
      equipment_item_id: String(item.id),
      equipment_make: item.make || "",
      equipment_model: item.model_name || "",
      equipment_identifier: item.identifier,
      tag_number: item.tag_number || "",
    }));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const submit = editing ? patch : post;
    const url = editing ? entry!.edit_path! : path;
    submit(url, { onSuccess: () => onClose() });
  };

  const isItemSelected = data.equipment_item_id !== "";
  const inventoryDetails = [
    { label: "Make", value: data.equipment_make || "—" },
    { label: "Model", value: data.equipment_model || "—" },
    { label: "Serial Number", value: data.equipment_identifier || "—" },
    { label: "Tag Number", value: data.tag_number || "—" },
  ];

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="sm:max-w-md overflow-y-auto max-h-[90dvh]">
        <DialogHeader>
          <DialogTitle>{editing ? "Edit Equipment" : "Place Equipment"}</DialogTitle>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-3">
          {/* Quick search — add mode only, only shown when inventory exists */}
          {!editing && allItems.length > 0 && (
            <div ref={searchRef}>
              <label className="text-xs font-medium text-foreground">Quick Find</label>
              <div className="relative mt-1">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-muted-foreground pointer-events-none" />
                <Input
                  value={searchQuery}
                  onChange={(e) => {
                    setSearchQuery(e.target.value);
                    setShowResults(true);
                  }}
                  onFocus={() => setShowResults(true)}
                  onBlur={() => setTimeout(() => setShowResults(false), 150)}
                  onKeyDown={(e) => e.key === "Escape" && (setSearchQuery(""), setShowResults(false))}
                  placeholder="Type tag #, serial, or name..."
                  className="pl-8"
                />
              </div>
              {showResults && searchQuery.trim().length > 0 && (
                <div className="mt-1 rounded-md border border-border bg-popover shadow-md overflow-hidden">
                  {searchResults.length > 0 ? (
                    searchResults.map((item) => (
                      <Button
                        key={item.id}
                        type="button"
                        variant="ghost"
                        onMouseDown={() => handleQuickSelect(item)}
                        className="w-full justify-start px-3 py-2 h-auto gap-3 text-sm font-normal"
                      >
                        {item.tag_number && (
                          <span className="shrink-0 rounded bg-muted px-1.5 py-0.5 text-xs font-mono font-medium text-foreground">
                            #{item.tag_number}
                          </span>
                        )}
                        <span className="min-w-0">
                          <span className="font-medium text-foreground">{item.identifier}</span>
                          <span className="text-muted-foreground"> · {item.type_name}</span>
                          {item.make && <span className="text-muted-foreground"> · {item.make}{item.model_name ? ` ${item.model_name}` : ""}</span>}
                        </span>
                      </Button>
                    ))
                  ) : (
                    searchQuery.trim().length >= 2 && (
                      <p className="px-3 py-2 text-sm text-muted-foreground">No matches found</p>
                    )
                  )}
                </div>
              )}
            </div>
          )}

          <div>
            <label className="text-xs font-medium text-foreground">Category</label>
            <Select value={useOther ? "__other__" : data.equipment_type_id || undefined} onValueChange={handleTypeChange}>
              <SelectTrigger className="mt-1">
                <SelectValue placeholder="Select type..." />
              </SelectTrigger>
              <SelectContent>
                {equipment_types.map((t) => (
                  <SelectItem key={t.id} value={String(t.id)}>{t.name}</SelectItem>
                ))}
                <SelectItem value="__other__">Other (specify)</SelectItem>
              </SelectContent>
            </Select>
            {(errors as Record<string, string>).base && (
              <p className="text-xs text-destructive mt-1">{(errors as Record<string, string>).base}</p>
            )}
          </div>

          {useOther && (
            <div>
              <label className="text-xs font-medium text-foreground">Other Type</label>
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
              <label className="text-xs font-medium text-foreground">Select Unit</label>
              <Select value={data.equipment_item_id || "__manual__"} onValueChange={handleItemChange}>
                <SelectTrigger className="mt-1">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="__manual__">Enter manually</SelectItem>
                  {typeItems.map((item) => (
                    <SelectItem key={item.id} value={String(item.id)}>
                      {item.tag_number ? `#${item.tag_number} — ` : ""}{item.identifier}{item.model_name ? ` — ${item.model_name}` : ""}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          )}

          {isItemSelected ? (
            <div className="rounded-xl border border-border bg-muted/30 p-3">
              <div className="flex items-start gap-2">
                <div className="mt-0.5 rounded-full bg-background p-1 text-muted-foreground">
                  <Lock className="h-3.5 w-3.5" />
                </div>
                <div className="min-w-0">
                  <p className="text-sm font-medium text-foreground">Using inventory item details</p>
                  <p className="text-xs text-muted-foreground">
                    These values come from the selected unit and are locked here. Switch the unit dropdown to
                    <span className="font-medium text-foreground"> Enter manually</span> to edit them.
                  </p>
                </div>
              </div>
              <div className="mt-3 grid grid-cols-2 gap-3">
                {inventoryDetails.map((detail) => (
                  <div key={detail.label} className="rounded-lg border border-border bg-background px-3 py-2">
                    <div className="text-xs font-medium uppercase tracking-wide text-muted-foreground">{detail.label}</div>
                    <div className="mt-1 text-sm font-medium text-foreground break-words">{detail.value}</div>
                  </div>
                ))}
              </div>
            </div>
          ) : (
            <>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-xs font-medium text-foreground">Make</label>
                  <Input
                    value={data.equipment_make}
                    onChange={(e) => setData("equipment_make", e.target.value)}
                    placeholder="e.g. Drieaz"
                    className="mt-1"
                  />
                </div>
                <div>
                  <label className="text-xs font-medium text-foreground">Model</label>
                  <Input
                    value={data.equipment_model}
                    onChange={(e) => setData("equipment_model", e.target.value)}
                    placeholder="e.g. LGR 5000 LI-127690"
                    className="mt-1"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-xs font-medium text-foreground">Serial Number</label>
                  <Input
                    value={data.equipment_identifier}
                    onChange={(e) => setData("equipment_identifier", e.target.value)}
                    placeholder="e.g. 108447"
                    className="mt-1"
                  />
                </div>
                <div>
                  <label className="text-xs font-medium text-foreground">Tag Number</label>
                  <Input
                    value={data.tag_number}
                    onChange={(e) => setData("tag_number", e.target.value)}
                    placeholder="e.g. 1010"
                    className="mt-1"
                  />
                </div>
              </div>
            </>
          )}

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-xs font-medium text-foreground">Placed On</label>
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
                <label className="text-xs font-medium text-foreground">Removed On</label>
                <Input
                  type="date"
                  value={data.removed_at || ""}
                  onChange={(e) => setData("removed_at", e.target.value)}
                  className="mt-1"
                />
                <div className="mt-1 flex justify-end">
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
              </div>
            )}
          </div>

          <div>
            <label className="text-xs font-medium text-foreground">Location</label>
            <Input
              value={data.location_notes}
              onChange={(e) => setData("location_notes", e.target.value)}
              placeholder="Unit 806, kitchen"
              className="mt-1"
            />
          </div>

          <div className="flex justify-end gap-2 pt-2">
            <Button type="button" variant="ghost" size="sm" onClick={onClose}>Cancel</Button>
            <Button type="submit" size="sm" disabled={processing}>
              {processing ? "Saving..." : editing ? "Update" : "Place Equipment"}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}
