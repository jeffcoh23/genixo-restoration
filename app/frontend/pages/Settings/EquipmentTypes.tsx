import { useState } from "react";
import { usePage } from "@inertiajs/react";
import { Plus, Wrench } from "lucide-react";
import AppLayout from "@/layout/AppLayout";
import InlineActionFeedback from "@/components/InlineActionFeedback";
import PageHeader from "@/components/PageHeader";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import useInertiaAction from "@/hooks/useInertiaAction";
import { SharedProps } from "@/types";

interface EquipmentTypeItem {
  id: number;
  name: string;
  active: boolean;
  deactivate_path: string | null;
  reactivate_path: string | null;
}

interface Props {
  active_types: EquipmentTypeItem[];
  inactive_types: EquipmentTypeItem[];
  create_path: string;
}

export default function EquipmentTypesSettings() {
  const { active_types, inactive_types, create_path } = usePage<SharedProps & Props>().props;
  const [name, setName] = useState("");
  const typeAction = useInertiaAction();

  const handleAdd = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim() || typeAction.processing) return;
    typeAction.runPost(create_path, { name: name.trim() }, {
      errorMessage: "Could not add equipment type.",
      onSuccess: () => setName(""),
    });
  };

  return (
    <AppLayout>
      <PageHeader title="Equipment Types" />

      <InlineActionFeedback error={typeAction.error} onDismiss={typeAction.clearFeedback} className="mb-4" />

      <form onSubmit={handleAdd} className="flex items-center gap-2 mb-6">
        <Input
          value={name}
          onChange={(e) => { typeAction.clearFeedback(); setName(e.target.value); }}
          placeholder="New equipment type name..."
          className="max-w-xs"
        />
        <Button type="submit" size="sm" disabled={!name.trim() || typeAction.processing} className="gap-1">
          <Plus className="h-3.5 w-3.5" />
          {typeAction.processing ? "Adding..." : "Add"}
        </Button>
      </form>

      {active_types.length === 0 && inactive_types.length === 0 ? (
        <div className="rounded border border-border bg-card p-8 text-center">
          <div className="mx-auto h-12 w-12 rounded-full bg-muted flex items-center justify-center mb-3">
            <Wrench className="h-6 w-6 text-muted-foreground" />
          </div>
          <p className="text-muted-foreground">No equipment types defined yet.</p>
          <p className="text-sm text-muted-foreground mt-1">Add your first type above.</p>
        </div>
      ) : (
        <div className="space-y-6">
          {active_types.length > 0 && (
            <div className="space-y-1.5">
              {active_types.map((et) => (
                <div key={et.id} className="flex items-center justify-between rounded border border-border bg-card px-4 py-3">
                  <span className="text-sm font-medium">{et.name}</span>
                  <div className="flex items-center gap-2">
                    <Badge variant="secondary" className="text-xs">Active</Badge>
                    {et.deactivate_path && (
                      <Button
                        variant="ghost"
                        size="sm"
                        className="h-7 text-xs text-muted-foreground hover:text-destructive"
                        onClick={() => typeAction.runPatch(et.deactivate_path!, {}, { errorMessage: "Could not deactivate equipment type." })}
                        disabled={typeAction.processing}
                      >
                        Deactivate
                      </Button>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}

          {inactive_types.length > 0 && (
            <div>
              <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground mb-2">Inactive</p>
              <div className="space-y-1.5">
                {inactive_types.map((et) => (
                  <div key={et.id} className="flex items-center justify-between rounded border border-border bg-card px-4 py-3 opacity-60">
                    <span className="text-sm font-medium">{et.name}</span>
                    {et.reactivate_path && (
                      <Button
                        variant="ghost"
                        size="sm"
                        className="h-7 text-xs"
                        onClick={() => typeAction.runPatch(et.reactivate_path!, {}, { errorMessage: "Could not reactivate equipment type." })}
                        disabled={typeAction.processing}
                      >
                        Reactivate
                      </Button>
                    )}
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      )}
    </AppLayout>
  );
}
