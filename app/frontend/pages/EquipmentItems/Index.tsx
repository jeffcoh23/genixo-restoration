import { useState, useMemo } from "react";
import { router, usePage } from "@inertiajs/react";
import { Package, Plus, Pencil, MapPin, CircleCheck, Search, X, Settings2 } from "lucide-react";
import AppLayout from "@/layout/AppLayout";
import PageHeader from "@/components/PageHeader";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetDescription,
} from "@/components/ui/sheet";
import { SharedProps } from "@/types";

interface Placement {
  incident_id: number;
  property_name: string;
  job_id: string | null;
  placed_at: string;
  placed_at_formatted: string;
  removed_at: string | null;
  removed_at_formatted: string | null;
  location_notes: string | null;
}

interface EquipmentItemRow {
  id: number;
  identifier: string;
  equipment_model: string | null;
  type_name: string;
  equipment_type_id: number;
  active: boolean;
  edit_path: string;
  deployed: boolean;
  deployed_property: string | null;
  deployed_incident_id: number | null;
  placements: Placement[];
}

interface EquipmentTypeOption {
  id: number;
  name: string;
}

interface EquipmentTypeRow {
  id: number;
  name: string;
  active: boolean;
  deactivate_path: string | null;
  reactivate_path: string | null;
}

interface Props {
  items: EquipmentItemRow[];
  equipment_types: EquipmentTypeOption[];
  all_types: EquipmentTypeRow[];
  create_item_path: string;
  create_type_path: string;
}

const EMPTY_FORM = { equipment_type_id: "", identifier: "", equipment_model: "" };

export default function EquipmentIndex() {
  const { items, equipment_types, all_types, create_item_path, create_type_path } =
    usePage<SharedProps & Props>().props;

  // Add item dialog
  const [addOpen, setAddOpen] = useState(false);
  const [form, setForm] = useState(EMPTY_FORM);
  const [submitting, setSubmitting] = useState(false);

  // Inline edit
  const [editingId, setEditingId] = useState<number | null>(null);
  const [editForm, setEditForm] = useState(EMPTY_FORM);

  // Filters (client-side)
  const [search, setSearch] = useState("");
  const [typeFilter, setTypeFilter] = useState("");
  const [statusFilter, setStatusFilter] = useState("");

  // History sheet
  const [selectedItem, setSelectedItem] = useState<EquipmentItemRow | null>(null);

  // Types sheet
  const [typesOpen, setTypesOpen] = useState(false);
  const [addTypeOpen, setAddTypeOpen] = useState(false);
  const [typeName, setTypeName] = useState("");
  const [typeSubmitting, setTypeSubmitting] = useState(false);

  // Filtered items
  const filteredItems = useMemo(() => {
    return items.filter((item) => {
      if (typeFilter && String(item.equipment_type_id) !== typeFilter) return false;
      if (statusFilter === "available" && item.deployed) return false;
      if (statusFilter === "deployed" && !item.deployed) return false;
      if (search) {
        const q = search.toLowerCase();
        const match =
          item.identifier.toLowerCase().includes(q) ||
          (item.equipment_model || "").toLowerCase().includes(q);
        if (!match) return false;
      }
      return true;
    });
  }, [items, search, typeFilter, statusFilter]);

  const hasFilters = search || typeFilter || statusFilter;

  const handleAdd = (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.identifier.trim() || !form.equipment_type_id || submitting) return;
    setSubmitting(true);
    router.post(create_item_path, { equipment_item: form }, {
      onSuccess: () => { setForm(EMPTY_FORM); setAddOpen(false); },
      onFinish: () => setSubmitting(false),
    });
  };

  const startEdit = (item: EquipmentItemRow) => {
    setEditingId(item.id);
    setEditForm({
      equipment_type_id: String(item.equipment_type_id),
      identifier: item.identifier,
      equipment_model: item.equipment_model || "",
    });
  };

  const handleUpdate = (item: EquipmentItemRow) => {
    if (!editForm.identifier.trim() || submitting) return;
    setSubmitting(true);
    router.patch(item.edit_path, { equipment_item: editForm }, {
      onSuccess: () => setEditingId(null),
      onFinish: () => setSubmitting(false),
    });
  };

  const handleDeactivate = (item: EquipmentItemRow) => {
    router.patch(item.edit_path, { equipment_item: { active: false } });
  };

  const handleAddType = (e: React.FormEvent) => {
    e.preventDefault();
    if (!typeName.trim() || typeSubmitting) return;
    setTypeSubmitting(true);
    router.post(create_type_path, { name: typeName.trim() }, {
      onSuccess: () => { setTypeName(""); setAddTypeOpen(false); },
      onFinish: () => setTypeSubmitting(false),
    });
  };

  const clearFilters = () => {
    setSearch("");
    setTypeFilter("");
    setStatusFilter("");
  };

  return (
    <AppLayout wide>
      <PageHeader
        title="Equipment"
        action={{ label: "Add Item", onClick: () => setAddOpen(true) }}
      />

      {/* Filter bar */}
      <div className="flex flex-wrap items-center gap-2 mb-4">
        <div className="relative">
          <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-muted-foreground" />
          <Input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search identifier or model..."
            className="h-8 pl-8 pr-8 w-64 text-sm"
          />
          {search && (
            <Button
              type="button"
              variant="ghost"
              size="sm"
              className="absolute right-2 top-1/2 -translate-y-1/2 h-5 w-5 p-0 text-muted-foreground hover:text-foreground"
              onClick={() => setSearch("")}
            >
              <X className="h-3.5 w-3.5" />
            </Button>
          )}
        </div>

        <Select value={typeFilter || "all"} onValueChange={(v) => setTypeFilter(v === "all" ? "" : v)}>
          <SelectTrigger className="h-8 w-[160px] text-sm">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Types</SelectItem>
            {equipment_types.map((t) => (
              <SelectItem key={t.id} value={String(t.id)}>{t.name}</SelectItem>
            ))}
          </SelectContent>
        </Select>

        <Select value={statusFilter || "all"} onValueChange={(v) => setStatusFilter(v === "all" ? "" : v)}>
          <SelectTrigger className="h-8 w-[140px] text-sm">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Statuses</SelectItem>
            <SelectItem value="available">Available</SelectItem>
            <SelectItem value="deployed">Deployed</SelectItem>
          </SelectContent>
        </Select>

        {hasFilters && (
          <Button variant="ghost" size="sm" className="h-8 text-xs text-muted-foreground" onClick={clearFilters}>
            Clear filters
          </Button>
        )}

        <div className="flex items-center gap-3 ml-auto">
          <span className="text-xs text-muted-foreground">
            {filteredItems.length} of {items.length} items
          </span>
          <Button
            variant="outline"
            size="sm"
            className="h-8 gap-1.5 text-xs"
            onClick={() => setTypesOpen(true)}
          >
            <Settings2 className="h-3.5 w-3.5" />
            Manage Types
          </Button>
        </div>
      </div>

      {/* Inventory table */}
      {items.length === 0 ? (
        <div className="rounded border border-border bg-card p-8 text-center">
          <div className="mx-auto h-12 w-12 rounded-full bg-muted flex items-center justify-center mb-3">
            <Package className="h-6 w-6 text-muted-foreground" />
          </div>
          <p className="text-muted-foreground">No equipment items yet.</p>
          <p className="text-sm text-muted-foreground mt-1">Add your first item to get started.</p>
        </div>
      ) : filteredItems.length === 0 ? (
        <div className="rounded border border-border bg-card p-6 text-center">
          <p className="text-muted-foreground text-sm">No items match your filters.</p>
        </div>
      ) : (
        <InventoryTable
          items={filteredItems}
          editingId={editingId}
          editForm={editForm}
          setEditForm={setEditForm}
          equipment_types={equipment_types}
          submitting={submitting}
          onStartEdit={startEdit}
          onCancelEdit={() => setEditingId(null)}
          onSaveEdit={handleUpdate}
          onDeactivate={handleDeactivate}
          onViewHistory={setSelectedItem}
        />
      )}

      {/* Add Item Dialog */}
      <AddItemDialog
        open={addOpen}
        onClose={() => { setAddOpen(false); setForm(EMPTY_FORM); }}
        form={form}
        setForm={setForm}
        equipment_types={equipment_types}
        submitting={submitting}
        onSubmit={handleAdd}
      />

      {/* Equipment Types Sheet */}
      <TypesSheet
        open={typesOpen}
        onClose={() => setTypesOpen(false)}
        all_types={all_types}
        addTypeOpen={addTypeOpen}
        onOpenAddType={() => setAddTypeOpen(true)}
        onCloseAddType={() => { setAddTypeOpen(false); setTypeName(""); }}
        typeName={typeName}
        setTypeName={setTypeName}
        typeSubmitting={typeSubmitting}
        onAddType={handleAddType}
      />

      {/* Placement History Sheet */}
      <PlacementHistorySheet
        item={selectedItem}
        onClose={() => setSelectedItem(null)}
      />
    </AppLayout>
  );
}

function AddItemDialog({
  open,
  onClose,
  form,
  setForm,
  equipment_types,
  submitting,
  onSubmit,
}: {
  open: boolean;
  onClose: () => void;
  form: typeof EMPTY_FORM;
  setForm: (f: typeof EMPTY_FORM) => void;
  equipment_types: EquipmentTypeOption[];
  submitting: boolean;
  onSubmit: (e: React.FormEvent) => void;
}) {
  return (
    <Dialog open={open} onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Add Equipment Item</DialogTitle>
        </DialogHeader>
        <form onSubmit={onSubmit} className="space-y-4 mt-2">
          <div>
            <label className="text-sm font-medium">Type *</label>
            <Select value={form.equipment_type_id} onValueChange={(v) => setForm({ ...form, equipment_type_id: v })}>
              <SelectTrigger className="mt-1">
                <SelectValue placeholder="Select type..." />
              </SelectTrigger>
              <SelectContent>
                {equipment_types.map((t) => (
                  <SelectItem key={t.id} value={String(t.id)}>{t.name}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div>
            <label className="text-sm font-medium">Identifier *</label>
            <Input
              value={form.identifier}
              onChange={(e) => setForm({ ...form, identifier: e.target.value })}
              placeholder="e.g. DH-042"
              className="mt-1"
            />
          </div>
          <div>
            <label className="text-sm font-medium">Model</label>
            <Input
              value={form.equipment_model}
              onChange={(e) => setForm({ ...form, equipment_model: e.target.value })}
              placeholder="e.g. LGR 7000XLi"
              className="mt-1"
            />
          </div>
          <div className="flex justify-end gap-2 pt-2">
            <Button type="button" variant="ghost" onClick={onClose}>Cancel</Button>
            <Button type="submit" disabled={!form.identifier.trim() || !form.equipment_type_id || submitting}>
              Add Item
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}

function TypesSheet({
  open,
  onClose,
  all_types,
  addTypeOpen,
  onOpenAddType,
  onCloseAddType,
  typeName,
  setTypeName,
  typeSubmitting,
  onAddType,
}: {
  open: boolean;
  onClose: () => void;
  all_types: EquipmentTypeRow[];
  addTypeOpen: boolean;
  onOpenAddType: () => void;
  onCloseAddType: () => void;
  typeName: string;
  setTypeName: (s: string) => void;
  typeSubmitting: boolean;
  onAddType: (e: React.FormEvent) => void;
}) {
  return (
    <Sheet open={open} onOpenChange={(o) => !o && onClose()}>
      <SheetContent side="right" className="w-full sm:max-w-lg overflow-y-auto">
        <SheetHeader className="mb-6">
          <SheetTitle>Equipment Types</SheetTitle>
          <SheetDescription>
            Categories like "Dehumidifier" or "Air Mover". Items in your inventory belong to a type.
          </SheetDescription>
        </SheetHeader>

        <Button size="sm" className="mb-4 gap-1" onClick={onOpenAddType}>
          <Plus className="h-3.5 w-3.5" />
          Add Type
        </Button>

        {all_types.length === 0 ? (
          <p className="text-sm text-muted-foreground py-4">No types defined yet. Add one to get started.</p>
        ) : (
          <div className="rounded-lg border bg-card">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b bg-muted">
                  <th className="px-3 py-2 font-medium text-left">Name</th>
                  <th className="px-3 py-2 font-medium text-left">Status</th>
                  <th className="px-3 py-2 font-medium text-right">Actions</th>
                </tr>
              </thead>
              <tbody>
                {all_types.map((et) => (
                  <tr key={et.id} className={`border-b last:border-0 ${!et.active ? "opacity-50" : ""}`}>
                    <td className="px-3 py-2.5 font-medium">{et.name}</td>
                    <td className="px-3 py-2.5">
                      {et.active ? (
                        <Badge variant="secondary" className="text-xs">Active</Badge>
                      ) : (
                        <Badge variant="outline" className="text-xs text-muted-foreground">Inactive</Badge>
                      )}
                    </td>
                    <td className="px-3 py-2.5 text-right">
                      {et.deactivate_path && (
                        <Button
                          variant="ghost"
                          size="sm"
                          className="h-7 text-xs text-muted-foreground hover:text-destructive"
                          onClick={() => router.patch(et.deactivate_path!)}
                        >
                          Deactivate
                        </Button>
                      )}
                      {et.reactivate_path && (
                        <Button
                          variant="ghost"
                          size="sm"
                          className="h-7 text-xs"
                          onClick={() => router.patch(et.reactivate_path!)}
                        >
                          Reactivate
                        </Button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* Add Type Dialog (nested) */}
        <Dialog open={addTypeOpen} onOpenChange={(o) => { if (!o) onCloseAddType(); }}>
          <DialogContent className="sm:max-w-sm">
            <DialogHeader>
              <DialogTitle>Add Equipment Type</DialogTitle>
            </DialogHeader>
            <form onSubmit={onAddType} className="space-y-4 mt-2">
              <div>
                <label className="text-sm font-medium">Name *</label>
                <Input
                  value={typeName}
                  onChange={(e) => setTypeName(e.target.value)}
                  placeholder="e.g. Dehumidifier"
                  className="mt-1"
                  autoFocus
                />
              </div>
              <div className="flex justify-end gap-2 pt-2">
                <Button type="button" variant="ghost" onClick={onCloseAddType}>Cancel</Button>
                <Button type="submit" disabled={!typeName.trim() || typeSubmitting}>
                  Add Type
                </Button>
              </div>
            </form>
          </DialogContent>
        </Dialog>
      </SheetContent>
    </Sheet>
  );
}

function InventoryTable({
  items,
  editingId,
  editForm,
  setEditForm,
  equipment_types,
  submitting,
  onStartEdit,
  onCancelEdit,
  onSaveEdit,
  onDeactivate,
  onViewHistory,
}: {
  items: EquipmentItemRow[];
  editingId: number | null;
  editForm: typeof EMPTY_FORM;
  setEditForm: (f: typeof EMPTY_FORM) => void;
  equipment_types: { id: number; name: string }[];
  submitting: boolean;
  onStartEdit: (item: EquipmentItemRow) => void;
  onCancelEdit: () => void;
  onSaveEdit: (item: EquipmentItemRow) => void;
  onDeactivate: (item: EquipmentItemRow) => void;
  onViewHistory: (item: EquipmentItemRow) => void;
}) {
  return (
    <div className="rounded-lg border bg-card shadow-sm">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b bg-muted">
            <th className="px-4 py-3 font-medium text-left">Identifier</th>
            <th className="px-4 py-3 font-medium text-left">Type</th>
            <th className="px-4 py-3 font-medium text-left">Model</th>
            <th className="px-4 py-3 font-medium text-left">Status</th>
            <th className="px-4 py-3 font-medium text-right">Actions</th>
          </tr>
        </thead>
        <tbody>
          {items.map((item) => {
            const isEditing = editingId === item.id;
            return (
              <tr key={item.id} className="border-b last:border-0 hover:bg-muted">
                {isEditing ? (
                  <>
                    <td className="px-4 py-2">
                      <Input
                        value={editForm.identifier}
                        onChange={(e) => setEditForm({ ...editForm, identifier: e.target.value })}
                        className="h-8 text-sm w-28"
                      />
                    </td>
                    <td className="px-4 py-2">
                      <Select value={editForm.equipment_type_id} onValueChange={(v) => setEditForm({ ...editForm, equipment_type_id: v })}>
                        <SelectTrigger className="h-8 text-sm">
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                          {equipment_types.map((t) => (
                            <SelectItem key={t.id} value={String(t.id)}>{t.name}</SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </td>
                    <td className="px-4 py-2">
                      <Input
                        value={editForm.equipment_model}
                        onChange={(e) => setEditForm({ ...editForm, equipment_model: e.target.value })}
                        className="h-8 text-sm w-36"
                      />
                    </td>
                    <td className="px-4 py-2" />
                    <td className="px-4 py-2 text-right">
                      <div className="flex items-center justify-end gap-1">
                        <Button size="sm" className="h-7 text-xs" disabled={submitting} onClick={() => onSaveEdit(item)}>
                          Save
                        </Button>
                        <Button variant="ghost" size="sm" className="h-7 text-xs" onClick={onCancelEdit}>
                          Cancel
                        </Button>
                      </div>
                    </td>
                  </>
                ) : (
                  <>
                    <td className="px-4 py-3">
                      <Button
                        variant="link"
                        className="h-auto p-0 font-medium"
                        onClick={() => onViewHistory(item)}
                      >
                        {item.identifier}
                      </Button>
                    </td>
                    <td className="px-4 py-3 text-muted-foreground">{item.type_name}</td>
                    <td className="px-4 py-3 text-muted-foreground">{item.equipment_model || "—"}</td>
                    <td className="px-4 py-3">
                      <StatusBadge deployed={item.deployed} property={item.deployed_property} />
                    </td>
                    <td className="px-4 py-3 text-right">
                      <div className="flex items-center justify-end gap-1">
                        <Button
                          variant="ghost"
                          size="sm"
                          className="h-7 w-7 p-0 text-muted-foreground"
                          onClick={() => onStartEdit(item)}
                        >
                          <Pencil className="h-3.5 w-3.5" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="sm"
                          className="h-7 text-xs text-muted-foreground"
                          onClick={() => onDeactivate(item)}
                        >
                          Remove
                        </Button>
                      </div>
                    </td>
                  </>
                )}
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}

function StatusBadge({ deployed, property }: { deployed: boolean; property: string | null }) {
  if (deployed) {
    return (
      <span className="inline-flex items-center gap-1 rounded-full bg-status-warning/15 px-2 py-0.5 text-xs font-medium text-status-warning">
        <MapPin className="h-3 w-3" />
        {property}
      </span>
    );
  }

  return (
    <span className="inline-flex items-center gap-1 rounded-full bg-status-success/15 px-2 py-0.5 text-xs font-medium text-status-success">
      <CircleCheck className="h-3 w-3" />
      Available
    </span>
  );
}

function PlacementHistorySheet({
  item,
  onClose,
}: {
  item: EquipmentItemRow | null;
  onClose: () => void;
}) {
  if (!item) return null;


  return (
    <Sheet open={!!item} onOpenChange={(open) => !open && onClose()}>
      <SheetContent side="right" className="w-full sm:max-w-lg overflow-y-auto">
        <SheetHeader className="mb-6">
          <SheetTitle>{item.identifier}</SheetTitle>
          <SheetDescription>
            {item.type_name}
            {item.equipment_model ? ` — ${item.equipment_model}` : ""}
          </SheetDescription>
        </SheetHeader>

        <div className="mb-4">
          <StatusBadge deployed={item.deployed} property={item.deployed_property} />
        </div>

        {item.placements.length === 0 ? (
          <p className="text-sm text-muted-foreground py-4">No placement history yet.</p>
        ) : (
          <div className="space-y-0">
            <h4 className="text-xs font-semibold uppercase tracking-wider text-muted-foreground mb-3">
              Placement History
            </h4>
            <div className="relative">
              <div className="absolute left-[7px] top-2 bottom-2 w-px bg-border" />
              <div className="space-y-4">
                {item.placements.map((p, i) => (
                  <div key={i} className="relative pl-6">
                    <div
                      className={`absolute left-0 top-1.5 h-[15px] w-[15px] rounded-full border-2 ${
                        !p.removed_at
                          ? "border-status-warning bg-status-warning/15"
                          : "border-muted-foreground/30 bg-muted"
                      }`}
                    />
                    <div className="rounded-lg border bg-card p-3">
                      <div className="flex items-start justify-between gap-2">
                        <div className="min-w-0">
                          <p className="font-medium text-sm truncate">{p.property_name}</p>
                          {p.job_id && (
                            <p className="text-xs text-muted-foreground">Job: {p.job_id}</p>
                          )}
                        </div>
                        {!p.removed_at && (
                          <span className="shrink-0 rounded bg-status-warning/15 px-1.5 py-0.5 text-xs font-semibold uppercase text-status-warning">
                            Active
                          </span>
                        )}
                      </div>
                      <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted-foreground">
                        <span>Placed: {p.placed_at_formatted}</span>
                        {p.removed_at_formatted && <span>Removed: {p.removed_at_formatted}</span>}
                      </div>
                      {p.location_notes && (
                        <p className="mt-1.5 text-xs text-muted-foreground italic">
                          {p.location_notes}
                        </p>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}
      </SheetContent>
    </Sheet>
  );
}
