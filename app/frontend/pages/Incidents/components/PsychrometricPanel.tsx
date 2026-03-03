import { Fragment, useState, useRef, useCallback, useMemo } from "react";
import { Trash2, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import useInertiaAction from "@/hooks/useInertiaAction";
import IncidentPanelAddButton from "./IncidentPanelAddButton";
import PsychrometricBatchForm from "./PsychrometricBatchForm";
import type { PsychrometricData, PsychrometricPoint } from "../types";

interface PsychrometricPanelProps {
  psychrometric_data: PsychrometricData;
  can_manage_psychrometric: boolean;
}

function rhColor(rh: number | null): string {
  if (rh === null) return "";
  if (rh <= 50) return "bg-green-100 text-green-800";
  if (rh <= 60) return "bg-amber-100 text-amber-800";
  return "bg-red-100 text-red-800";
}

type PsychField = "relative_humidity" | "temperature";

function calculateGpp(rh: number | null, temp: number | null): number | null {
  if (rh === null || temp === null) return null;
  const tC = (temp - 32) * 5.0 / 9.0;
  const pSat = 610.94 * Math.exp(17.625 * tC / (243.04 + tC));
  const sh = 0.622 * (rh / 100.0 * pSat) / (101325.0 - rh / 100.0 * pSat);
  return Math.round(sh * 7000 * 10) / 10;
}

export default function PsychrometricPanel({ psychrometric_data, can_manage_psychrometric }: PsychrometricPanelProps) {
  const [showBatchForm, setShowBatchForm] = useState(false);
  const [batchPointId, setBatchPointId] = useState<number | null>(null);
  const { runDelete } = useInertiaAction();

  // Simple click-to-edit
  const [editingCell, setEditingCell] = useState<{ pointId: number; date: string; field: PsychField } | null>(null);
  const [editValue, setEditValue] = useState("");
  const originalValue = useRef("");
  const cancelledRef = useRef(false);
  const savedRef = useRef(false);

  // Optimistic UI: locally edited values overlay server props until next full reload
  const [pendingSaves, setPendingSaves] = useState<Record<string, number | null>>({});
  const [saveError, setSaveError] = useState<string | null>(null);

  // Local points added via inline row (avoids Inertia reload)
  const [localPoints, setLocalPoints] = useState<PsychrometricPoint[]>([]);
  const allPoints = useMemo(() => [...psychrometric_data.points, ...localPoints.filter(lp => !psychrometric_data.points.some(sp => sp.id === lp.id))], [psychrometric_data.points, localPoints]);

  // G-Dep: for room points, GPP minus the dehumidifier GPP in the same unit
  const getDehuGpp = useCallback((unit: string, date: string): number | null => {
    const dehuPoint = allPoints.find(p => p.unit === unit && p.dehumidifier_label);
    if (!dehuPoint) return null;
    const rhKey = `${dehuPoint.id}:${date}:relative_humidity`;
    const tempKey = `${dehuPoint.id}:${date}:temperature`;
    const dehuRh = rhKey in pendingSaves ? pendingSaves[rhKey] : (dehuPoint.readings[date]?.relative_humidity ?? null);
    const dehuTemp = tempKey in pendingSaves ? pendingSaves[tempKey] : (dehuPoint.readings[date]?.temperature ?? null);
    if (rhKey in pendingSaves || tempKey in pendingSaves) return calculateGpp(dehuRh, dehuTemp);
    return dehuPoint.readings[date]?.gpp ?? null;
  }, [allPoints, pendingSaves]);

  const orderedDates = psychrometric_data.dates;
  const orderedDateLabels = psychrometric_data.date_labels;
  const hasPoints = allPoints.length > 0;

  // Inline new row
  const [newRow, setNewRow] = useState({
    unit: "", room: "", dehumidifier_label: "",
  });
  const newRowRef = useRef<HTMLTableRowElement>(null);
  const newRowProcessingRef = useRef(false);

  // --- Reading cell editing ---

  const startEdit = useCallback((pointId: number, date: string, field: PsychField, currentValue: number | null) => {
    const val = currentValue !== null ? String(currentValue) : "";
    setEditingCell({ pointId, date, field });
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

  const saveCell = useCallback((pointId: number, date: string, field: PsychField, value: string) => {
    if (savedRef.current) return;
    if (value === originalValue.current) return;
    savedRef.current = true;

    const numValue = value === "" ? null : parseFloat(value);
    // Optimistic: immediately show the new value in the UI
    setPendingSaves(prev => ({ ...prev, [`${pointId}:${date}:${field}`]: numValue }));

    const point = allPoints.find(p => p.id === pointId);
    const reading = point?.readings[date];
    const pendingKey = `${pointId}:${date}:${field}`;
    const rollbackValue = point?.readings[date]?.[field] ?? null;

    if (reading) {
      backgroundSave(reading.update_path, "PATCH", { [field]: numValue }).catch(() => {
        setPendingSaves(prev => ({ ...prev, [pendingKey]: rollbackValue }));
      });
    } else if (numValue !== null) {
      const data: Record<string, unknown> = { point_id: pointId, relative_humidity: null, temperature: null };
      data[field] = numValue;
      backgroundSave(psychrometric_data.batch_save_path, "POST", {
        log_date: date,
        readings: [data],
      }).catch(() => {
        setPendingSaves(prev => {
          const next = { ...prev };
          delete next[pendingKey];
          return next;
        });
      });
    }
  }, [allPoints, psychrometric_data, backgroundSave]);

  // Build flat cell list for Tab navigation (rh, temp per date per point)
  const getNextEditableCell = (pointId: number, date: string, field: PsychField, direction: "next" | "prev") => {
    type Cell = { pointId: number; date: string; field: PsychField; value: number | null };
    const cells: Cell[] = [];
    for (const point of allPoints) {
      for (const d of orderedDates) {
        const reading = point.readings[d];
        const rhKey = `${point.id}:${d}:relative_humidity`;
        const tempKey = `${point.id}:${d}:temperature`;
        cells.push({ pointId: point.id, date: d, field: "relative_humidity", value: rhKey in pendingSaves ? pendingSaves[rhKey] : (reading?.relative_humidity ?? null) });
        cells.push({ pointId: point.id, date: d, field: "temperature", value: tempKey in pendingSaves ? pendingSaves[tempKey] : (reading?.temperature ?? null) });
      }
    }

    const currentIdx = cells.findIndex(c => c.pointId === pointId && c.date === date && c.field === field);
    if (currentIdx === -1) return null;

    const nextIdx = direction === "next" ? currentIdx + 1 : currentIdx - 1;
    return cells[nextIdx] ?? null;
  };

  const handleCellKeyDown = (e: React.KeyboardEvent) => {
    if (!editingCell) return;

    if (e.key === "Tab") {
      e.preventDefault();
      saveCell(editingCell.pointId, editingCell.date, editingCell.field, editValue);
      const next = getNextEditableCell(editingCell.pointId, editingCell.date, editingCell.field, e.shiftKey ? "prev" : "next");
      if (next) {
        startEdit(next.pointId, next.date, next.field, next.value);
      } else {
        setEditingCell(null);
      }
    } else if (e.key === "Enter") {
      e.preventDefault();
      saveCell(editingCell.pointId, editingCell.date, editingCell.field, editValue);
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
      saveCell(blurredCell.pointId, blurredCell.date, blurredCell.field, editValue);
    }
    setTimeout(() => {
      setEditingCell(prev => {
        if (prev?.pointId === blurredCell?.pointId && prev?.date === blurredCell?.date && prev?.field === blurredCell?.field) {
          return null;
        }
        return prev;
      });
    }, 0);
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
      const resp = await fetch(psychrometric_data.create_point_path, {
        method: "POST",
        headers: { "Content-Type": "application/json", "Accept": "application/json", "X-CSRF-Token": csrfToken },
        body: JSON.stringify({
          point: {
            unit: newRow.unit.trim(),
            room: newRow.room.trim(),
            dehumidifier_label: newRow.dehumidifier_label.trim(),
          },
          reading_temperature: "",
          reading_relative_humidity: "",
          reading_date: "",
        }),
      });
      if (resp.ok) {
        const newPoint: PsychrometricPoint = await resp.json();
        setLocalPoints(prev => [...prev, newPoint]);
      }
      setNewRow({ unit: "", room: "", dehumidifier_label: "" });
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
      {can_manage_psychrometric && (
        <div className="flex items-center justify-center sm:justify-start gap-1 border-b border-border px-4 py-3 shrink-0">
          {hasPoints && (
            <IncidentPanelAddButton label="Record Readings" onClick={() => { setBatchPointId(null); setShowBatchForm(true); }} />
          )}
        </div>
      )}

      {/* Table */}
      <div className="flex-1 overflow-y-auto">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-muted border-b border-border sticky top-0">
              <tr>
                <th className="px-3 py-2.5 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground sticky left-0 bg-muted z-10 min-w-[80px]">Unit</th>
                <th className="px-3 py-2.5 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground min-w-[90px]">Room</th>
                <th className="px-3 py-2.5 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground min-w-[80px]">Dehu</th>
                {orderedDateLabels.map((label, i) => (
                  <th key={orderedDates[i]} colSpan={4} className="px-1 py-2.5 text-center text-xs font-semibold uppercase tracking-wide text-muted-foreground border-l border-border">
                    {label}
                  </th>
                ))}
                {can_manage_psychrometric && (
                  <th className="px-3 py-2.5 text-center text-xs font-semibold uppercase tracking-wide text-muted-foreground min-w-[40px]" />
                )}
              </tr>
              <tr className="border-b border-border">
                <th className="sticky left-0 bg-muted z-10" />
                <th />
                <th />
                {orderedDates.map((date) => (
                  <Fragment key={date}>
                    <th className="px-1 py-1 text-center text-xs font-medium uppercase text-muted-foreground/70 border-l border-border min-w-[50px]">Rh%</th>
                    <th className="px-1 py-1 text-center text-xs font-medium uppercase text-muted-foreground/70 min-w-[50px]">F&deg;</th>
                    <th className="px-1 py-1 text-center text-xs font-medium uppercase text-muted-foreground/70 min-w-[50px]">GPP</th>
                    <th className="px-1 py-1 text-center text-xs font-medium uppercase text-muted-foreground/70 min-w-[50px]">G-Dep</th>
                  </Fragment>
                ))}
                {can_manage_psychrometric && <th />}
              </tr>
            </thead>
            <tbody>
              {allPoints.map((point) => (
                <tr key={point.id} className="border-b border-border last:border-b-0 hover:bg-muted/30 transition-colors">
                  <td className="px-3 py-2.5 text-sm font-medium text-foreground sticky left-0 bg-background z-10">{point.unit}</td>
                  <td className="px-3 py-2.5 text-sm text-muted-foreground">{point.room}</td>
                  <td className="px-3 py-2.5 text-sm text-muted-foreground">{point.dehumidifier_label || "\u2014"}</td>
                  {orderedDates.map((date) => {
                    const reading = point.readings[date];
                    const rhKey = `${point.id}:${date}:relative_humidity`;
                    const tempKey = `${point.id}:${date}:temperature`;
                    const rh = rhKey in pendingSaves ? pendingSaves[rhKey] : (reading?.relative_humidity ?? null);
                    const temp = tempKey in pendingSaves ? pendingSaves[tempKey] : (reading?.temperature ?? null);
                    // Recalculate GPP client-side if we have local edits, otherwise use server value
                    const gpp = (rhKey in pendingSaves || tempKey in pendingSaves)
                      ? calculateGpp(rh, temp)
                      : (reading?.gpp ?? null);

                    const isEditingRh = editingCell?.pointId === point.id && editingCell?.date === date && editingCell?.field === "relative_humidity";
                    const isEditingTemp = editingCell?.pointId === point.id && editingCell?.date === date && editingCell?.field === "temperature";

                    return (
                      <Fragment key={date}>
                        {/* Rh% cell */}
                        <td className={`px-1 py-1 text-sm text-center border-l border-border ${can_manage_psychrometric ? "cursor-pointer hover:bg-muted/50" : ""}`}>
                          {isEditingRh ? (
                            <Input
                              type="text"
                              inputMode="decimal"
                              value={editValue}
                              onChange={(e) => {
                                const v = e.target.value;
                                if (v === "" || /^\d*\.?\d*$/.test(v)) setEditValue(v);
                              }}
                              onKeyDown={handleCellKeyDown}
                              onBlur={handleCellBlur}
                              className="h-6 w-12 text-center text-xs border-0 border-b-2 border-primary rounded-none shadow-none focus-visible:ring-0 mx-auto font-medium"
                              autoFocus
                            />
                          ) : (
                            <span
                              className={`inline-block rounded px-1 py-0.5 text-xs font-medium ${rhColor(rh)}`}
                              onClick={() => {
                                if (can_manage_psychrometric) startEdit(point.id, date, "relative_humidity", rh);
                              }}
                            >
                              {rh !== null ? rh : <span className="text-muted-foreground/40">&mdash;</span>}
                            </span>
                          )}
                        </td>
                        {/* F° cell */}
                        <td className={`px-1 py-1 text-sm text-center ${can_manage_psychrometric ? "cursor-pointer hover:bg-muted/50" : ""}`}>
                          {isEditingTemp ? (
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
                              className="h-6 w-12 text-center text-xs border-0 border-b-2 border-primary rounded-none shadow-none focus-visible:ring-0 mx-auto font-medium"
                              autoFocus
                            />
                          ) : (
                            <span
                              className="text-xs"
                              onClick={() => {
                                if (can_manage_psychrometric) startEdit(point.id, date, "temperature", temp);
                              }}
                            >
                              {temp !== null ? temp : <span className="text-muted-foreground/40">&mdash;</span>}
                            </span>
                          )}
                        </td>
                        {/* GPP cell (read-only) */}
                        <td className="px-1 py-1.5 text-sm text-center">
                          <span className="text-xs text-muted-foreground">
                            {gpp !== null ? gpp : <span className="text-muted-foreground/40">&mdash;</span>}
                          </span>
                        </td>
                        {/* G-Dep cell (read-only, calculated) */}
                        <td className="px-1 py-1.5 text-sm text-center">
                          <span className="text-xs text-muted-foreground">
                            {point.dehumidifier_label ? (
                              <span className="text-muted-foreground/40">&mdash;</span>
                            ) : (() => {
                              if (gpp === null) return <span className="text-muted-foreground/40">&mdash;</span>;
                              const dehuGpp = getDehuGpp(point.unit, date);
                              if (dehuGpp === null) return <span className="text-muted-foreground/40">&mdash;</span>;
                              return Math.round((gpp - dehuGpp) * 10) / 10;
                            })()}
                          </span>
                        </td>
                      </Fragment>
                    );
                  })}
                  {can_manage_psychrometric && (
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
              {can_manage_psychrometric && (
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
                      value={newRow.dehumidifier_label}
                      onChange={(e) => setNewRowField("dehumidifier_label", e.target.value)}
                      onKeyDown={handleNewRowKeyDown}
                      onBlur={handleNewRowBlur}
                      placeholder="Dehu label"
                      className="h-7 w-full text-xs"
                    />
                  </td>
                  {orderedDates.map((date) => (
                    <Fragment key={date}>
                      <td className="px-1 py-2.5 text-center border-l border-border"><span className="text-muted-foreground/30">&mdash;</span></td>
                      <td className="px-1 py-2.5 text-center"><span className="text-muted-foreground/30">&mdash;</span></td>
                      <td className="px-1 py-2.5 text-center"><span className="text-muted-foreground/30">&mdash;</span></td>
                      <td className="px-1 py-2.5 text-center"><span className="text-muted-foreground/30">&mdash;</span></td>
                    </Fragment>
                  ))}
                  <td />
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {showBatchForm && (
        <PsychrometricBatchForm
          points={batchPointId ? allPoints.filter(p => p.id === batchPointId) : allPoints}
          dates={psychrometric_data.dates}
          batchSavePath={psychrometric_data.batch_save_path}
          onClose={() => { setShowBatchForm(false); setBatchPointId(null); }}
        />
      )}
    </div>
  );
}
