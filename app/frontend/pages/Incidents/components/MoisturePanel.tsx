import { useState } from "react";
import { Pencil, Trash2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import useInertiaAction from "@/hooks/useInertiaAction";
import IncidentPanelAddButton from "./IncidentPanelAddButton";
import MoisturePointForm from "./MoisturePointForm";
import MoistureBatchForm from "./MoistureBatchForm";
import type { MoistureData } from "../types";

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
  const [showPointForm, setShowPointForm] = useState(false);
  const [showBatchForm, setShowBatchForm] = useState(false);
  const [batchDate, setBatchDate] = useState<string | null>(null);
  const [batchPointId, setBatchPointId] = useState<number | null>(null);
  const { runPatch, runDelete } = useInertiaAction();
  const [editingSupervisor, setEditingSupervisor] = useState(false);
  const [supervisorValue, setSupervisorValue] = useState(moisture_data.supervisor_pm || "");
  const [editingCell, setEditingCell] = useState<{ pointId: number; date: string } | null>(null);
  const [editValue, setEditValue] = useState("");

  const hasData = moisture_data.points.length > 0;
  const reversedDates = [...moisture_data.dates].reverse();
  const reversedDateLabels = [...moisture_data.date_labels].reverse();

  const handleSaveSupervisor = () => {
    runPatch(moisture_data.update_supervisor_path, {
      moisture_supervisor_pm: supervisorValue.trim(),
    }, {
      preserveState: true,
      onSuccess: () => setEditingSupervisor(false),
    });
  };

  const handleDeletePoint = (destroyPath: string) => {
    runDelete(destroyPath);
  };

  const handleEditReading = (pointId: number, date: string, readingId: number, currentValue: number | null) => {
    setEditingCell({ pointId, date });
    setEditValue(currentValue !== null ? String(currentValue) : "");
  };

  const handleSaveReading = (readingId: number) => {
    const path = moisture_data.moisture_reading_path_template.replace("READING_ID", String(readingId));
    runPatch(path, { value: editValue === "" ? null : parseFloat(editValue) }, {
      onSuccess: () => setEditingCell(null),
    });
  };

  const handleCancelEdit = () => {
    setEditingCell(null);
  };

  const openBatchForRow = (pointId: number) => {
    setBatchPointId(pointId);
    setShowBatchForm(true);
  };


  return (
    <div className="flex flex-col h-full">
      {/* Action bar */}
      {can_manage_moisture && (
        <div className="flex items-center justify-center sm:justify-start gap-1 border-b border-border px-4 py-3 shrink-0">
          {hasData && (
            <IncidentPanelAddButton label="Record Readings" onClick={() => { setBatchDate(null); setBatchPointId(null); setShowBatchForm(true); }} />
          )}
          <IncidentPanelAddButton label="Add Point" onClick={() => setShowPointForm(true)} />
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

      {/* Content */}
      {!hasData ? (
        <div className="flex-1 flex items-center justify-center text-muted-foreground text-sm py-12">
          No moisture readings recorded yet.
        </div>
      ) : (
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
                  {reversedDateLabels.map((label, i) => (
                    <th key={reversedDates[i]} className="px-3 py-2.5 text-center text-xs font-semibold uppercase tracking-wide text-muted-foreground min-w-[65px]">
                      {label}
                    </th>
                  ))}
                  {can_manage_moisture && (
                    <th className="px-3 py-2.5 text-center text-xs font-semibold uppercase tracking-wide text-muted-foreground min-w-[60px]" />
                  )}
                </tr>
              </thead>
              <tbody>
                {moisture_data.points.map((point) => (
                  <tr key={point.id} className="border-b border-border last:border-b-0 hover:bg-muted/30 transition-colors">
                    <td className="px-3 py-2.5 text-sm font-medium text-foreground sticky left-0 bg-background z-10">{point.unit}</td>
                    <td className="px-3 py-2.5 text-sm text-muted-foreground">{point.room}</td>
                    <td className="px-3 py-2.5 text-sm text-muted-foreground">{point.item}</td>
                    <td className="px-3 py-2.5 text-sm text-muted-foreground">{point.material}</td>
                    <td className="px-3 py-2.5 text-sm text-center text-muted-foreground">
                      {formatGoal(point.goal, point.measurement_unit)}
                    </td>
                    {reversedDates.map((date) => {
                      const reading = point.readings[date];
                      const value = reading?.value ?? null;
                      const colorClass = readingColor(value, point.goal);
                      const isEditing = editingCell?.pointId === point.id && editingCell?.date === date;

                      if (isEditing && reading) {
                        return (
                          <td key={date} className="px-1 py-1.5 text-sm text-center">
                            <Input
                              type="number"
                              step="0.1"
                              min="0"
                              value={editValue}
                              onChange={(e) => setEditValue(e.target.value)}
                              onKeyDown={(e) => {
                                if (e.key === "Enter") handleSaveReading(reading.id);
                                if (e.key === "Escape") handleCancelEdit();
                              }}
                              onBlur={() => handleSaveReading(reading.id)}
                              className="h-7 w-16 text-center text-xs mx-auto"
                              autoFocus
                            />
                          </td>
                        );
                      }

                      return (
                        <td
                          key={date}
                          className={`px-3 py-2.5 text-sm text-center ${can_manage_moisture && reading ? "cursor-pointer" : ""}`}
                          onClick={() => {
                            if (can_manage_moisture && reading) {
                              handleEditReading(point.id, date, reading.id, value);
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
                        <div className="flex items-center justify-center gap-0.5">
                          <Button
                            variant="ghost"
                            size="sm"
                            className="h-6 w-6 p-0 text-muted-foreground hover:text-foreground"
                            onClick={() => openBatchForRow(point.id)}
                            title="Edit readings"
                          >
                            <Pencil className="h-3 w-3" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            className="h-6 w-6 p-0 text-muted-foreground hover:text-destructive"
                            onClick={() => handleDeletePoint(point.destroy_path)}
                            title="Remove point"
                          >
                            <Trash2 className="h-3.5 w-3.5" />
                          </Button>
                        </div>
                      </td>
                    )}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {showPointForm && (
        <MoisturePointForm
          createPath={moisture_data.create_point_path}
          onClose={() => setShowPointForm(false)}
        />
      )}
      {showBatchForm && (
        <MoistureBatchForm
          points={batchPointId ? moisture_data.points.filter(p => p.id === batchPointId) : moisture_data.points}
          dates={moisture_data.dates}
          batchSavePath={moisture_data.batch_save_path}
          initialDate={batchDate}
          onClose={() => { setShowBatchForm(false); setBatchDate(null); setBatchPointId(null); }}
        />
      )}
    </div>
  );
}
