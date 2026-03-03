import { useState, useRef, useCallback, useMemo } from "react";
import { Trash2, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import useInertiaAction from "@/hooks/useInertiaAction";
import IncidentPanelAddButton from "./IncidentPanelAddButton";
import MoistureBatchForm from "./MoistureBatchForm";
import type { MoistureData, MoisturePoint } from "../types";

interface MoisturePanelProps {
  moisture_data: MoistureData;
  can_manage_moisture: boolean;
}

function readingColor(value: number | null, goal: string): string {
  if (value === null) return "";
  const goalLower = goal.toLowerCase().trim();
  if (goalLower === "dry") {
    if (value <= 15) return "bg-green-100 text-green-800";
    if (value <= 20) return "bg-amber-100 text-amber-800";
    return "bg-red-100 text-red-800";
  }
  const goalNum = parseFloat(goal);
  if (isNaN(goalNum)) return "";
  if (value <= goalNum) return "bg-green-100 text-green-800";
  if (value <= goalNum * 1.25) return "bg-amber-100 text-amber-800";
  return "bg-red-100 text-red-800";
}

function formatGoal(goal: string, unit: string): string {
  if (goal.toLowerCase() === "dry") return "Dry";
  return unit === "%" ? `${goal}%` : `${goal} ${unit}`;
}

function formatReading(value: number, unit: string): string {
  return unit === "%" ? `${value}%` : String(value);
}

export default function MoisturePanel({ moisture_data, can_manage_moisture }: MoisturePanelProps) {
  const [showBatchForm, setShowBatchForm] = useState(false);
  const [batchDate, setBatchDate] = useState<string | null>(null);
  const [batchPointId, setBatchPointId] = useState<number | null>(null);
  const { runPatch, runDelete } = useInertiaAction();
  const [editingSupervisor, setEditingSupervisor] = useState(false);
  const [supervisorValue, setSupervisorValue] = useState(moisture_data.supervisor_pm || "");

  // Simple click-to-edit: one cell at a time
  const [editingCell, setEditingCell] = useState<{ pointId: number; date: string } | null>(null);
  const [editValue, setEditValue] = useState("");
  const originalValue = useRef("");
  const cancelledRef = useRef(false);
  const savedRef = useRef(false);

  // Optimistic UI: locally edited values overlay server props until next full reload
  const [pendingSaves, setPendingSaves] = useState<Record<string, number | null>>({});
  const [saveError, setSaveError] = useState<string | null>(null);

  // Local points added via inline row (avoids Inertia reload)
  const [localPoints, setLocalPoints] = useState<MoisturePoint[]>([]);
  const allPoints = useMemo(() => [...moisture_data.points, ...localPoints.filter(lp => !moisture_data.points.some(sp => sp.id === lp.id))], [moisture_data.points, localPoints]);

  const orderedDates = moisture_data.dates;
  const orderedDateLabels = moisture_data.date_labels;
  const hasPoints = allPoints.length > 0;

  // Inline new row
  const [newRow, setNewRow] = useState({
    unit: "", room: "", item: "", material: "", goal: "", measurement_unit: "Pts",
  });
  const newRowRef = useRef<HTMLTableRowElement>(null);
  const newRowProcessingRef = useRef(false);

  // --- Reading cell editing ---

  const startEdit = useCallback((pointId: number, date: string, currentValue: number | null) => {
    const val = currentValue !== null ? String(currentValue) : "";
    setEditingCell({ pointId, date });
    setEditValue(val);
    originalValue.current = val;
    cancelledRef.current = false;
    savedRef.current = false;
  }, []);

  // Fire-and-forget background save — no Inertia visit, no table reload
  const backgroundSave = useCallback(async (url: string, method: "PATCH" | "POST", body: Record<string, unknown>) => {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content") || "";
    try {
      const resp = await fetch(url, {
        method,
        headers: { "Content-Type": "application/json", "X-CSRF-Token": csrfToken },
        body: JSON.stringify(body),
        redirect: "manual",
      });
      if (!resp.ok) {
        throw new Error(`Save failed with status ${resp.status}`);
      }
      setSaveError(null);
    } catch {
      setSaveError("Failed to save. Changes may be lost.");
      throw new Error("background save failed");
    }
  }, []);

  const saveCell = useCallback((pointId: number, date: string, value: string) => {
    if (savedRef.current) return;
    if (value === originalValue.current) return;
    savedRef.current = true;

    const numValue = value === "" ? null : parseFloat(value);
    // Optimistic: immediately show the new value in the UI
    setPendingSaves(prev => ({ ...prev, [`${pointId}:${date}`]: numValue }));

    const point = allPoints.find(p => p.id === pointId);
    const reading = point?.readings[date];
    const pendingKey = `${pointId}:${date}`;
    const rollbackValue = point?.readings[date]?.value ?? null;

    if (reading) {
      backgroundSave(reading.update_path, "PATCH", { value: numValue }).catch(() => {
        setPendingSaves(prev => ({ ...prev, [pendingKey]: rollbackValue }));
      });
    } else if (numValue !== null) {
      backgroundSave(moisture_data.batch_save_path, "POST", {
        log_date: date,
        readings: [{ point_id: pointId, value: numValue }],
      }).catch(() => {
        setPendingSaves(prev => {
          const next = { ...prev };
          delete next[pendingKey];
          return next;
        });
      });
    }
  }, [allPoints, moisture_data, backgroundSave]);

  // Tab: save current cell + start editing next date column
  const getNextReadingCell = (pointId: number, date: string, direction: "next" | "prev") => {
    const dateIdx = orderedDates.indexOf(date);
    const pointIdx = allPoints.findIndex(p => p.id === pointId);
    if (dateIdx === -1 || pointIdx === -1) return null;

    const resolveValue = (p: typeof allPoints[0], d: string) => {
      const key = `${p.id}:${d}`;
      return key in pendingSaves ? pendingSaves[key] : (p.readings[d]?.value ?? null);
    };

    if (direction === "next") {
      if (dateIdx < orderedDates.length - 1) {
        const p = allPoints[pointIdx];
        return { pointId: p.id, date: orderedDates[dateIdx + 1], value: resolveValue(p, orderedDates[dateIdx + 1]) };
      }
      if (pointIdx < allPoints.length - 1) {
        const p = allPoints[pointIdx + 1];
        return { pointId: p.id, date: orderedDates[0], value: resolveValue(p, orderedDates[0]) };
      }
    } else {
      if (dateIdx > 0) {
        const p = allPoints[pointIdx];
        return { pointId: p.id, date: orderedDates[dateIdx - 1], value: resolveValue(p, orderedDates[dateIdx - 1]) };
      }
      if (pointIdx > 0) {
        const p = allPoints[pointIdx - 1];
        const lastDate = orderedDates[orderedDates.length - 1];
        return { pointId: p.id, date: lastDate, value: resolveValue(p, lastDate) };
      }
    }
    return null;
  };

  const handleCellKeyDown = (e: React.KeyboardEvent) => {
    if (!editingCell) return;

    if (e.key === "Tab") {
      e.preventDefault();
      saveCell(editingCell.pointId, editingCell.date, editValue);
      const next = getNextReadingCell(editingCell.pointId, editingCell.date, e.shiftKey ? "prev" : "next");
      if (next) {
        startEdit(next.pointId, next.date, next.value);
      } else {
        setEditingCell(null);
      }
    } else if (e.key === "Enter") {
      e.preventDefault();
      saveCell(editingCell.pointId, editingCell.date, editValue);
      setEditingCell(null);
    } else if (e.key === "Escape") {
      e.preventDefault();
      cancelledRef.current = true;
      setEditingCell(null);
    }
  };

  const handleCellBlur = () => {
    if (cancelledRef.current) {
      cancelledRef.current = false;
      return;
    }
    const blurredCell = editingCell;
    if (blurredCell) {
      saveCell(blurredCell.pointId, blurredCell.date, editValue);
    }
    setTimeout(() => {
      setEditingCell(prev => {
        if (prev?.pointId === blurredCell?.pointId && prev?.date === blurredCell?.date) {
          return null;
        }
        return prev;
      });
    }, 0);
  };

  // --- Supervisor ---

  const handleSaveSupervisor = () => {
    runPatch(moisture_data.update_supervisor_path, {
      moisture_supervisor_pm: supervisorValue.trim(),
    }, {
      preserveState: true,
      onSuccess: () => setEditingSupervisor(false),
    });
  };

  // --- Delete ---

  const handleDeletePoint = (pointId: number, destroyPath: string) => {
    runDelete(destroyPath, undefined, {
      preserveState: true,
      onSuccess: () => {
        setLocalPoints(prev => prev.filter((point) => point.id !== pointId));
      },
    });
  };

  // --- New row ---

  const setNewRowField = (field: string, value: string) => {
    setNewRow(prev => ({ ...prev, [field]: value }));
  };

  const canSaveNewRow = newRow.unit.trim() && newRow.room.trim();

  const saveNewRow = async () => {
    if (!canSaveNewRow || newRowProcessingRef.current) return;
    newRowProcessingRef.current = true;
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content") || "";
    try {
      const resp = await fetch(moisture_data.create_point_path, {
        method: "POST",
        headers: { "Content-Type": "application/json", "Accept": "application/json", "X-CSRF-Token": csrfToken },
        body: JSON.stringify({
          point: {
            unit: newRow.unit.trim(),
            room: newRow.room.trim(),
            item: newRow.item.trim(),
            material: newRow.material.trim(),
            goal: newRow.goal.trim(),
            measurement_unit: newRow.measurement_unit,
          },
          reading_value: "",
          reading_date: "",
        }),
      });
      if (resp.ok) {
        const newPoint: MoisturePoint = await resp.json();
        setLocalPoints(prev => [...prev, newPoint]);
      }
      setNewRow({ unit: "", room: "", item: "", material: "", goal: "", measurement_unit: "Pts" });
    } catch {
      setSaveError("Failed to save. Changes may be lost.");
    } finally {
      newRowProcessingRef.current = false;
    }
  };

  const handleNewRowKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Enter" && canSaveNewRow) {
      e.preventDefault();
      saveNewRow();
    }
  };

  const handleNewRowBlur = () => {
    setTimeout(() => {
      if (newRowRef.current && !newRowRef.current.contains(document.activeElement)) {
        if (canSaveNewRow) saveNewRow();
      }
    }, 0);
  };

  return (
    <div className="flex flex-col h-full">
      {saveError && (
        <div className="flex items-center justify-between gap-2 bg-destructive/10 text-destructive px-4 py-2 text-sm shrink-0">
          <span>{saveError}</span>
          <Button variant="ghost" size="sm" onClick={() => setSaveError(null)} className="h-5 w-5 p-0 hover:bg-destructive/20">
            <X className="h-4 w-4" />
          </Button>
        </div>
      )}
      {/* Action bar */}
      {can_manage_moisture && (
        <div className="flex items-center justify-center sm:justify-start gap-1 border-b border-border px-4 py-3 shrink-0">
          {hasPoints && (
            <IncidentPanelAddButton label="Record Readings" onClick={() => { setBatchDate(null); setBatchPointId(null); setShowBatchForm(true); }} />
          )}
        </div>
      )}

      {/* Supervisor/PM bar */}
      <div className="flex items-center gap-2 border-b border-border px-4 py-2.5 shrink-0 bg-muted/30">
        <span className="text-xs font-semibold uppercase tracking-wide text-muted-foreground whitespace-nowrap">Supervisor/PM:</span>
        {editingSupervisor ? (
          <>
            <Input
              value={supervisorValue}
              onChange={(e) => setSupervisorValue(e.target.value)}
              onKeyDown={(e) => { if (e.key === "Enter") handleSaveSupervisor(); }}
              className="h-8 w-36 sm:w-48 text-sm"
              placeholder="Enter name"
              autoFocus
            />
            <Button variant="outline" size="sm" className="h-8 text-xs" onClick={handleSaveSupervisor}>Save</Button>
            <Button variant="ghost" size="sm" className="h-8 text-xs" onClick={() => { setEditingSupervisor(false); setSupervisorValue(moisture_data.supervisor_pm || ""); }}>Cancel</Button>
          </>
        ) : (
          <>
            <span className="text-sm text-foreground">{moisture_data.supervisor_pm || "Not set"}</span>
            {can_manage_moisture && (
              <Button variant="outline" size="sm" className="h-7 text-xs" onClick={() => { setSupervisorValue(moisture_data.supervisor_pm || ""); setEditingSupervisor(true); }}>
                Edit
              </Button>
            )}
          </>
        )}
      </div>

      {/* Table */}
      <div className="flex-1 overflow-y-auto">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-muted border-b border-border sticky top-0">
              <tr>
                <th className="px-3 py-2.5 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground sticky left-0 bg-muted z-10 min-w-[80px]">Unit</th>
                <th className="px-3 py-2.5 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground min-w-[90px]">Room</th>
                <th className="px-3 py-2.5 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground min-w-[80px]">Item</th>
                <th className="px-3 py-2.5 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground min-w-[80px]">Material</th>
                <th className="px-3 py-2.5 text-center text-xs font-semibold uppercase tracking-wide text-muted-foreground min-w-[70px]">Goal</th>
                {orderedDateLabels.map((label, i) => (
                  <th key={orderedDates[i]} className="px-3 py-2.5 text-center text-xs font-semibold uppercase tracking-wide text-muted-foreground min-w-[65px]">
                    {label}
                  </th>
                ))}
                {can_manage_moisture && (
                  <th className="px-3 py-2.5 text-center text-xs font-semibold uppercase tracking-wide text-muted-foreground min-w-[40px]" />
                )}
              </tr>
            </thead>
            <tbody>
              {allPoints.map((point) => (
                <tr key={point.id} className="border-b border-border last:border-b-0 hover:bg-muted/30 transition-colors">
                  <td className="px-3 py-2.5 text-sm font-medium text-foreground sticky left-0 bg-background z-10">{point.unit}</td>
                  <td className="px-3 py-2.5 text-sm text-muted-foreground">{point.room}</td>
                  <td className="px-3 py-2.5 text-sm text-muted-foreground">{point.item}</td>
                  <td className="px-3 py-2.5 text-sm text-muted-foreground">{point.material}</td>
                  <td className="px-3 py-2.5 text-sm text-center text-muted-foreground">
                    {formatGoal(point.goal, point.measurement_unit)}
                  </td>
                  {orderedDates.map((date) => {
                    const reading = point.readings[date];
                    const pendingKey = `${point.id}:${date}`;
                    const value = pendingKey in pendingSaves ? pendingSaves[pendingKey] : (reading?.value ?? null);
                    const colorClass = readingColor(value, point.goal);
                    const isEditing = editingCell?.pointId === point.id && editingCell?.date === date;

                    if (isEditing) {
                      return (
                        <td key={date} className="px-1 py-1 text-sm text-center">
                          <Input
                            type="text"
                            inputMode="decimal"
                            value={editValue}
                            onChange={(e) => {
                              const v = e.target.value;
                              if (v === "" || v === "-" || /^-?\d*\.?\d*$/.test(v)) setEditValue(v);
                            }}
                            onKeyDown={handleCellKeyDown}
                            onBlur={handleCellBlur}
                            className="h-6 w-14 text-center text-xs border-0 border-b-2 border-primary rounded-none shadow-none focus-visible:ring-0 mx-auto font-medium"
                            autoFocus
                          />
                        </td>
                      );
                    }

                    return (
                      <td
                        key={date}
                        className={`px-1 py-1 text-sm text-center ${can_manage_moisture ? "cursor-pointer hover:bg-muted/50" : ""}`}
                        onClick={() => {
                          if (can_manage_moisture) {
                            startEdit(point.id, date, value);
                          }
                        }}
                      >
                        {value !== null ? (
                          <span className={`inline-block rounded px-1.5 py-0.5 text-xs font-medium ${colorClass}`}>
                            {formatReading(value, point.measurement_unit)}
                          </span>
                        ) : (
                          <span className="text-muted-foreground/40">&mdash;</span>
                        )}
                      </td>
                    );
                  })}
                  {can_manage_moisture && (
                    <td className="px-3 py-2.5 text-center">
                      <Button
                        variant="ghost"
                        size="sm"
                        className="h-6 w-6 p-0 text-muted-foreground hover:text-destructive"
                        onClick={() => handleDeletePoint(point.id, point.destroy_path)}
                        title="Remove point"
                      >
                        <Trash2 className="h-3.5 w-3.5" />
                      </Button>
                    </td>
                  )}
                </tr>
              ))}

              {/* Inline new row */}
              {can_manage_moisture && (
                <tr ref={newRowRef} className="border-b border-border bg-muted/10">
                  <td className="px-1.5 py-1.5 sticky left-0 bg-muted/10 z-10">
                    <Input
                      value={newRow.unit}
                      onChange={(e) => setNewRowField("unit", e.target.value)}
                      onKeyDown={handleNewRowKeyDown}
                      onBlur={handleNewRowBlur}
                      placeholder="Unit"
                      className="h-7 w-full text-xs"
                    />
                  </td>
                  <td className="px-1.5 py-1.5">
                    <Input
                      value={newRow.room}
                      onChange={(e) => setNewRowField("room", e.target.value)}
                      onKeyDown={handleNewRowKeyDown}
                      onBlur={handleNewRowBlur}
                      placeholder="Room"
                      className="h-7 w-full text-xs"
                    />
                  </td>
                  <td className="px-1.5 py-1.5">
                    <Input
                      value={newRow.item}
                      onChange={(e) => setNewRowField("item", e.target.value)}
                      onKeyDown={handleNewRowKeyDown}
                      onBlur={handleNewRowBlur}
                      placeholder="Item"
                      className="h-7 w-full text-xs"
                    />
                  </td>
                  <td className="px-1.5 py-1.5">
                    <Input
                      value={newRow.material}
                      onChange={(e) => setNewRowField("material", e.target.value)}
                      onKeyDown={handleNewRowKeyDown}
                      onBlur={handleNewRowBlur}
                      placeholder="Material"
                      className="h-7 w-full text-xs"
                    />
                  </td>
                  <td className="px-1.5 py-1.5">
                    <div className="flex items-center gap-1">
                      <Input
                        value={newRow.goal}
                        onChange={(e) => setNewRowField("goal", e.target.value)}
                        onKeyDown={handleNewRowKeyDown}
                        onBlur={handleNewRowBlur}
                        placeholder="Goal"
                        className="h-7 w-16 text-xs"
                      />
                      <select
                        value={newRow.measurement_unit}
                        onChange={(e) => setNewRowField("measurement_unit", e.target.value)}
                        className="h-7 text-xs border border-border rounded px-1 bg-background text-foreground"
                      >
                        <option value="Pts">Pts</option>
                        <option value="%">%</option>
                      </select>
                    </div>
                  </td>
                  {orderedDates.map((date) => (
                    <td key={date} className="px-3 py-2.5 text-center">
                      <span className="text-muted-foreground/30">&mdash;</span>
                    </td>
                  ))}
                  <td />
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {showBatchForm && (
        <MoistureBatchForm
          points={batchPointId ? allPoints.filter(p => p.id === batchPointId) : allPoints}
          dates={moisture_data.dates}
          batchSavePath={moisture_data.batch_save_path}
          initialDate={batchDate}
          onClose={() => { setShowBatchForm(false); setBatchDate(null); setBatchPointId(null); }}
        />
      )}
    </div>
  );
}
