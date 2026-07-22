import { useCallback, useMemo, useState } from "react";
import { usePage } from "@inertiajs/react";
import { Plus } from "lucide-react";
import InlineActionFeedback from "@/components/InlineActionFeedback";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import useInertiaAction from "@/hooks/useInertiaAction";
import type { SharedProps } from "@/types";
import type { ConsumableDay, ConsumableType } from "../types";

interface ConsumablesSectionProps {
  consumable_types: ConsumableType[];
  consumable_days: ConsumableDay[];
  consumable_entries_path: string;
  can_manage: boolean;
}

interface WriteInRow {
  name: string;
  quantity: string;
}

const MIN_WRITE_IN_ROWS = 4;

function emptyWriteIns(): WriteInRow[] {
  return Array.from({ length: MIN_WRITE_IN_ROWS }, () => ({ name: "", quantity: "" }));
}

// Daniel's paper sheet, digitized: every standard item prefilled with a
// quantity box for the selected day, plus write-in rows for one-offs. Saving
// replaces that day's entries, so cleared quantities disappear on save.
export default function ConsumablesSection({
  consumable_types = [],
  consumable_days = [],
  consumable_entries_path,
  can_manage,
}: ConsumablesSectionProps) {
  const { today } = usePage<SharedProps>().props;
  const [selectedDate, setSelectedDate] = useState(today);
  const saveAction = useInertiaAction();

  const dayEntries = useMemo(
    () => consumable_days.find((d) => d.log_date === selectedDate)?.entries ?? [],
    [consumable_days, selectedDate]
  );

  const buildQuantities = useCallback(() => {
    const map: Record<number, string> = {};
    for (const entry of dayEntries) {
      if (entry.consumable_type_id != null) map[entry.consumable_type_id] = String(entry.quantity);
    }
    return map;
  }, [dayEntries]);

  const buildWriteIns = useCallback(() => {
    const existing = dayEntries
      .filter((e) => e.consumable_type_id == null)
      .map((e) => ({ name: e.custom_name ?? e.name, quantity: String(e.quantity) }));
    const blanks = Math.max(MIN_WRITE_IN_ROWS - existing.length, 1);
    return [ ...existing, ...Array.from({ length: blanks }, () => ({ name: "", quantity: "" })) ];
  }, [dayEntries]);

  const [quantities, setQuantities] = useState<Record<number, string>>(buildQuantities);
  const [writeIns, setWriteIns] = useState<WriteInRow[]>(buildWriteIns);

  // State-adjustment-during-render: refill the sheet whenever the selected
  // date or that day's saved entries change (e.g. after a save round-trips).
  const [prevKey, setPrevKey] = useState(() => JSON.stringify([ selectedDate, dayEntries ]));
  const currentKey = JSON.stringify([ selectedDate, dayEntries ]);
  if (currentKey !== prevKey) {
    setPrevKey(currentKey);
    setQuantities(buildQuantities());
    setWriteIns(buildWriteIns());
  }

  const setQuantity = (typeId: number, value: string) => {
    setQuantities((prev) => ({ ...prev, [typeId]: value.replace(/[^0-9]/g, "") }));
  };

  const setWriteIn = (index: number, patch: Partial<WriteInRow>) => {
    setWriteIns((prev) => prev.map((row, i) => {
      if (i !== index) return row;
      const next = { ...row, ...patch };
      next.quantity = next.quantity.replace(/[^0-9]/g, "");
      return next;
    }));
  };

  const handleSave = () => {
    const entries = [
      ...consumable_types
        .filter((type) => (quantities[type.id] ?? "") !== "")
        .map((type) => ({ consumable_type_id: type.id, quantity: quantities[type.id] })),
      ...writeIns
        .filter((row) => row.name.trim() !== "" && row.quantity !== "")
        .map((row) => ({ custom_name: row.name.trim(), quantity: row.quantity })),
    ];
    saveAction.runPost(consumable_entries_path, { log_date: selectedDate, entries }, {
      errorMessage: "Could not save consumables. Please try again.",
    });
  };

  const loggedDays = consumable_days.filter((d) => d.entries.length > 0);

  return (
    <div className="flex-1 overflow-y-auto p-4 sm:p-6">
      <div className="mb-4 flex flex-wrap items-end justify-between gap-3">
        <label className="flex flex-col gap-1 text-xs font-medium text-muted-foreground">
          Date
          <Input
            type="date"
            value={selectedDate}
            onChange={(e) => setSelectedDate(e.target.value)}
            data-testid="consumables-date"
            className="h-9 w-auto"
          />
        </label>
        {can_manage && (
          <Button onClick={handleSave} disabled={saveAction.processing || !selectedDate} data-testid="consumables-save">
            {saveAction.processing ? "Saving..." : "Save Consumables"}
          </Button>
        )}
      </div>

      {saveAction.error && (
        <div className="mb-3">
          <InlineActionFeedback error={saveAction.error} onDismiss={saveAction.clearFeedback} />
        </div>
      )}

      <div className="rounded-lg border border-border divide-y divide-border">
        {consumable_types.map((type) => (
          <div key={type.id} className="flex items-center justify-between gap-3 px-3 py-2">
            <span className="text-sm text-foreground">{type.name}</span>
            {can_manage ? (
              <Input
                inputMode="numeric"
                value={quantities[type.id] ?? ""}
                onChange={(e) => setQuantity(type.id, e.target.value)}
                placeholder="0"
                data-testid={`consumable-qty-${type.id}`}
                className="h-8 w-20 text-right"
              />
            ) : (
              <span className="text-sm tabular-nums text-muted-foreground">{quantities[type.id] ?? "—"}</span>
            )}
          </div>
        ))}

        {can_manage && (
          <div className="px-3 py-2 space-y-2">
            <p className="text-xs font-semibold text-muted-foreground uppercase tracking-wide">Write-ins</p>
            {writeIns.map((row, index) => (
              <div key={index} className="flex items-center gap-2">
                <Input
                  value={row.name}
                  onChange={(e) => setWriteIn(index, { name: e.target.value })}
                  placeholder="Item name"
                  data-testid={`consumable-writein-name-${index}`}
                  className="h-8 flex-1"
                />
                <Input
                  inputMode="numeric"
                  value={row.quantity}
                  onChange={(e) => setWriteIn(index, { quantity: e.target.value })}
                  placeholder="0"
                  data-testid={`consumable-writein-qty-${index}`}
                  className="h-8 w-20 text-right"
                />
              </div>
            ))}
            <Button
              variant="ghost"
              size="sm"
              onClick={() => setWriteIns((prev) => [ ...prev, { name: "", quantity: "" } ])}
              className="text-muted-foreground"
            >
              <Plus className="h-3.5 w-3.5 mr-1" />
              Add row
            </Button>
          </div>
        )}

        {!can_manage && dayEntries.filter((e) => e.consumable_type_id == null).length > 0 && (
          <div className="px-3 py-2 space-y-1">
            <p className="text-xs font-semibold text-muted-foreground uppercase tracking-wide">Write-ins</p>
            {dayEntries.filter((e) => e.consumable_type_id == null).map((entry) => (
              <div key={entry.id} className="flex items-center justify-between text-sm">
                <span className="text-foreground">{entry.name}</span>
                <span className="tabular-nums text-muted-foreground">{entry.quantity}</span>
              </div>
            ))}
          </div>
        )}
      </div>

      {loggedDays.length > 0 && (
        <div className="mt-5">
          <p className="text-xs font-semibold text-muted-foreground uppercase tracking-wide mb-2">Days with consumables</p>
          <div className="flex flex-wrap gap-2">
            {loggedDays.map((day) => (
              <Button
                key={day.log_date}
                variant={day.log_date === selectedDate ? "default" : "outline"}
                size="sm"
                onClick={() => setSelectedDate(day.log_date)}
                data-testid={`consumables-day-${day.log_date}`}
                className="h-7 text-xs"
              >
                {day.date_label}
                <span className="ml-1.5 opacity-70">({day.entries.length})</span>
              </Button>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
