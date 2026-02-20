import { useState } from "react";
import { router, usePage } from "@inertiajs/react";
import { Package, Plus, Pencil } from "lucide-react";
import AppLayout from "@/layout/AppLayout";
import PageHeader from "@/components/PageHeader";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { SharedProps } from "@/types";

interface EquipmentItemRow {
  id: number;
  identifier: string;
  equipment_model: string | null;
  serial_number: string | null;
  type_name: string;
  equipment_type_id: number;
  active: boolean;
  edit_path: string;
}

interface EquipmentTypeOption {
  id: number;
  name: string;
}

interface Props {
  items: EquipmentItemRow[];
  equipment_types: EquipmentTypeOption[];
  create_path: string;
}

const EMPTY_FORM = { equipment_type_id: "", identifier: "", equipment_model: "", serial_number: "" };

export default function EquipmentItemsIndex() {
  const { items, equipment_types, create_path } = usePage<SharedProps & Props>().props;
  const [form, setForm] = useState(EMPTY_FORM);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [editForm, setEditForm] = useState(EMPTY_FORM);
  const [submitting, setSubmitting] = useState(false);

  const handleAdd = (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.identifier.trim() || !form.equipment_type_id || submitting) return;
    setSubmitting(true);
    router.post(create_path, { equipment_item: form }, {
      onSuccess: () => setForm(EMPTY_FORM),
      onFinish: () => setSubmitting(false),
    });
  };

  const startEdit = (item: EquipmentItemRow) => {
    setEditingId(item.id);
    setEditForm({
      equipment_type_id: String(item.equipment_type_id),
      identifier: item.identifier,
      equipment_model: item.equipment_model || "",
      serial_number: item.serial_number || "",
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

  const handleToggleActive = (item: EquipmentItemRow) => {
    router.patch(item.edit_path, { equipment_item: { active: !item.active } });
  };

  const activeItems = items.filter((i) => i.active);
  const inactiveItems = items.filter((i) => !i.active);

  return (
    <AppLayout wide>
      <PageHeader title="Equipment Inventory" />

      {/* Add form */}
      <form onSubmit={handleAdd} className="flex flex-wrap items-end gap-2 mb-6">
        <div>
          <label className="text-xs font-medium text-muted-foreground">Type *</label>
          <select
            value={form.equipment_type_id}
            onChange={(e) => setForm({ ...form, equipment_type_id: e.target.value })}
            className="mt-1 block w-40 rounded border border-input bg-background px-3 py-2 text-sm"
          >
            <option value="">Select type...</option>
            {equipment_types.map((t) => (
              <option key={t.id} value={t.id}>{t.name}</option>
            ))}
          </select>
        </div>
        <div>
          <label className="text-xs font-medium text-muted-foreground">Identifier *</label>
          <Input
            value={form.identifier}
            onChange={(e) => setForm({ ...form, identifier: e.target.value })}
            placeholder="e.g. DH-042"
            className="mt-1 w-32"
          />
        </div>
        <div>
          <label className="text-xs font-medium text-muted-foreground">Model</label>
          <Input
            value={form.equipment_model}
            onChange={(e) => setForm({ ...form, equipment_model: e.target.value })}
            placeholder="e.g. LGR 7000XLi"
            className="mt-1 w-40"
          />
        </div>
        <div>
          <label className="text-xs font-medium text-muted-foreground">Serial #</label>
          <Input
            value={form.serial_number}
            onChange={(e) => setForm({ ...form, serial_number: e.target.value })}
            placeholder="Optional"
            className="mt-1 w-36"
          />
        </div>
        <Button type="submit" size="sm" disabled={!form.identifier.trim() || !form.equipment_type_id || submitting} className="gap-1">
          <Plus className="h-3.5 w-3.5" />
          Add
        </Button>
      </form>

      {items.length === 0 ? (
        <div className="rounded border border-border bg-card p-8 text-center">
          <div className="mx-auto h-12 w-12 rounded-full bg-muted flex items-center justify-center mb-3">
            <Package className="h-6 w-6 text-muted-foreground" />
          </div>
          <p className="text-muted-foreground">No equipment items yet.</p>
          <p className="text-sm text-muted-foreground mt-1">Add your first item above.</p>
        </div>
      ) : (
        <div className="space-y-6">
          {activeItems.length > 0 && (
            <ItemTable
              items={activeItems}
              editingId={editingId}
              editForm={editForm}
              setEditForm={setEditForm}
              equipment_types={equipment_types}
              submitting={submitting}
              onStartEdit={startEdit}
              onCancelEdit={() => setEditingId(null)}
              onSaveEdit={handleUpdate}
              onToggleActive={handleToggleActive}
            />
          )}

          {inactiveItems.length > 0 && (
            <div>
              <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground mb-2">Inactive</p>
              <ItemTable
                items={inactiveItems}
                editingId={editingId}
                editForm={editForm}
                setEditForm={setEditForm}
                equipment_types={equipment_types}
                submitting={submitting}
                onStartEdit={startEdit}
                onCancelEdit={() => setEditingId(null)}
                onSaveEdit={handleUpdate}
                onToggleActive={handleToggleActive}
                dimmed
              />
            </div>
          )}
        </div>
      )}
    </AppLayout>
  );
}

function ItemTable({
  items,
  editingId,
  editForm,
  setEditForm,
  equipment_types,
  submitting,
  onStartEdit,
  onCancelEdit,
  onSaveEdit,
  onToggleActive,
  dimmed,
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
  onToggleActive: (item: EquipmentItemRow) => void;
  dimmed?: boolean;
}) {
  return (
    <div className={`rounded-lg border bg-card shadow-sm ${dimmed ? "opacity-60" : ""}`}>
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b bg-muted">
            <th className="px-4 py-3 font-medium text-left">Identifier</th>
            <th className="px-4 py-3 font-medium text-left">Type</th>
            <th className="px-4 py-3 font-medium text-left">Model</th>
            <th className="px-4 py-3 font-medium text-left">Serial #</th>
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
                      <select
                        value={editForm.equipment_type_id}
                        onChange={(e) => setEditForm({ ...editForm, equipment_type_id: e.target.value })}
                        className="h-8 rounded border border-input bg-background px-2 text-sm"
                      >
                        {equipment_types.map((t) => (
                          <option key={t.id} value={t.id}>{t.name}</option>
                        ))}
                      </select>
                    </td>
                    <td className="px-4 py-2">
                      <Input
                        value={editForm.equipment_model}
                        onChange={(e) => setEditForm({ ...editForm, equipment_model: e.target.value })}
                        className="h-8 text-sm w-36"
                      />
                    </td>
                    <td className="px-4 py-2">
                      <Input
                        value={editForm.serial_number}
                        onChange={(e) => setEditForm({ ...editForm, serial_number: e.target.value })}
                        className="h-8 text-sm w-32"
                      />
                    </td>
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
                    <td className="px-4 py-3 font-medium">{item.identifier}</td>
                    <td className="px-4 py-3 text-muted-foreground">{item.type_name}</td>
                    <td className="px-4 py-3 text-muted-foreground">{item.equipment_model || "—"}</td>
                    <td className="px-4 py-3 text-muted-foreground">{item.serial_number || "—"}</td>
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
                          onClick={() => onToggleActive(item)}
                        >
                          {item.active ? "Deactivate" : "Reactivate"}
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
