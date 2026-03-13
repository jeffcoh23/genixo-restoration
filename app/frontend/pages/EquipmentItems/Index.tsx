import { useState, useMemo } from "react";
import { usePage } from "@inertiajs/react";
import { Package, Search, X, Settings2 } from "lucide-react";
import AppLayout from "@/layout/AppLayout";
import InlineActionFeedback from "@/components/InlineActionFeedback";
import PageHeader from "@/components/PageHeader";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { SharedProps } from "@/types";
import useInertiaAction from "@/hooks/useInertiaAction";
import type { EquipmentItemRow, EquipmentTypeOption, EquipmentTypeRow, ItemForm } from "./types";
import InventoryTable from "./InventoryTable";
import ItemFormDialog from "./ItemFormDialog";
import TypesSheet from "./TypesSheet";
import PlacementHistorySheet from "./PlacementHistorySheet";

interface Props {
  items: EquipmentItemRow[];
  equipment_types: EquipmentTypeOption[];
  all_types: EquipmentTypeRow[];
  create_item_path: string;
  create_type_path: string;
}

const EMPTY_FORM: ItemForm = { equipment_type_id: "", identifier: "", tag_number: "", equipment_make: "", equipment_model: "" };

export default function EquipmentIndex() {
  const { items, equipment_types, all_types, create_item_path, create_type_path } =
    usePage<SharedProps & Props>().props;

  // Add item dialog
  const [addOpen, setAddOpen] = useState(false);
  const [form, setForm] = useState(EMPTY_FORM);
  const itemAction = useInertiaAction();

  // Edit modal
  const [editingItem, setEditingItem] = useState<EquipmentItemRow | null>(null);
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
  const typeAction = useInertiaAction();

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
          (item.equipment_make || "").toLowerCase().includes(q) ||
          (item.equipment_model || "").toLowerCase().includes(q) ||
          (item.tag_number || "").toLowerCase().includes(q);
        if (!match) return false;
      }
      return true;
    });
  }, [items, search, typeFilter, statusFilter]);

  const hasFilters = search || typeFilter || statusFilter;

  const handleAdd = (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.identifier.trim() || !form.equipment_type_id || itemAction.processing) return;
    itemAction.runPost(create_item_path, { equipment_item: form }, {
      errorMessage: "Could not add equipment item.",
      onSuccess: () => { setForm(EMPTY_FORM); setAddOpen(false); },
    });
  };

  const startEdit = (item: EquipmentItemRow) => {
    setEditingItem(item);
    setEditForm({
      equipment_type_id: String(item.equipment_type_id),
      identifier: item.identifier,
      tag_number: item.tag_number || "",
      equipment_make: item.equipment_make || "",
      equipment_model: item.equipment_model || "",
    });
  };

  const handleUpdate = (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingItem || !editForm.identifier.trim() || itemAction.processing) return;
    itemAction.runPatch(editingItem.edit_path, { equipment_item: editForm }, {
      errorMessage: "Could not update equipment item.",
      onSuccess: () => setEditingItem(null),
    });
  };

  const handleDeactivate = (item: EquipmentItemRow) => {
    if (itemAction.processing) return;
    itemAction.runPatch(item.edit_path, { equipment_item: { active: false } }, {
      errorMessage: "Could not remove equipment item.",
    });
  };

  const handleAddType = (e: React.FormEvent) => {
    e.preventDefault();
    if (!typeName.trim() || typeAction.processing) return;
    typeAction.runPost(create_type_path, { name: typeName.trim() }, {
      errorMessage: "Could not add equipment type.",
      onSuccess: () => { setTypeName(""); setAddTypeOpen(false); },
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
      <InlineActionFeedback error={itemAction.error} onDismiss={itemAction.clearFeedback} className="mb-4" />

      {/* Filter bar */}
      <div className="flex flex-wrap items-center gap-2 mb-4">
        <div className="relative">
          <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-muted-foreground" />
          <Input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search serial, tag, or model..."
            className="h-8 pl-8 pr-8 w-64 text-sm bg-card"
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
          <SelectTrigger className="h-8 w-[160px] text-sm bg-card">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Categories</SelectItem>
            {equipment_types.map((t) => (
              <SelectItem key={t.id} value={String(t.id)}>{t.name}</SelectItem>
            ))}
          </SelectContent>
        </Select>

        <Select value={statusFilter || "all"} onValueChange={(v) => setStatusFilter(v === "all" ? "" : v)}>
          <SelectTrigger className="h-8 w-[140px] text-sm bg-card">
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
            data-testid="equipment-manage-types"
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
          submitting={itemAction.processing}
          onEdit={startEdit}
          onDeactivate={handleDeactivate}
          onViewHistory={setSelectedItem}
        />
      )}

      {/* Add Item Dialog */}
      <ItemFormDialog
        open={addOpen}
        onClose={() => { setAddOpen(false); setForm(EMPTY_FORM); }}
        form={form}
        setForm={setForm}
        equipment_types={equipment_types}
        submitting={itemAction.processing}
        onSubmit={handleAdd}
        title="Add Equipment Item"
        submitLabel="Add Item"
        submittingLabel="Adding..."
      />

      {/* Edit Item Dialog */}
      <ItemFormDialog
        open={!!editingItem}
        onClose={() => setEditingItem(null)}
        form={editForm}
        setForm={setEditForm}
        equipment_types={equipment_types}
        submitting={itemAction.processing}
        onSubmit={handleUpdate}
        title="Edit Equipment Item"
        submitLabel="Save Changes"
        submittingLabel="Saving..."
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
        setTypeName={(value) => { typeAction.clearFeedback(); setTypeName(value); }}
        typeSubmitting={typeAction.processing}
        onAddType={handleAddType}
        actionError={typeAction.error}
        onDismissActionError={typeAction.clearFeedback}
        onDeactivateType={(path) => typeAction.runPatch(path, {}, { errorMessage: "Could not deactivate equipment type." })}
        onReactivateType={(path) => typeAction.runPatch(path, {}, { errorMessage: "Could not reactivate equipment type." })}
      />

      {/* Placement History Sheet */}
      <PlacementHistorySheet
        item={selectedItem}
        onClose={() => setSelectedItem(null)}
      />
    </AppLayout>
  );
}
