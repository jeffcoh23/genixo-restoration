import { useState } from "react";
import { useForm, usePage } from "@inertiajs/react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { SharedProps } from "@/types";
import useInertiaAction from "@/hooks/useInertiaAction";
import type { PsychrometricPoint } from "../types";

interface PsychrometricBatchFormProps {
  points: PsychrometricPoint[];
  dates: string[];
  batchSavePath: string;
  initialDate?: string | null;
  onClose: () => void;
}

function calculateGpp(temp: string, rh: string): string {
  const t = parseFloat(temp);
  const h = parseFloat(rh);
  if (isNaN(t) || isNaN(h)) return "";
  const tC = (t - 32) * 5.0 / 9.0;
  const pSat = 610.94 * Math.exp(17.625 * tC / (243.04 + tC));
  const sh = 0.622 * (h / 100.0 * pSat) / (101325.0 - h / 100.0 * pSat);
  return (sh * 7000).toFixed(1);
}

export default function PsychrometricBatchForm({ points, dates, batchSavePath, initialDate, onClose }: PsychrometricBatchFormProps) {
  const { today } = usePage<SharedProps>().props;
  const [logDate, setLogDate] = useState(initialDate || today);

  const lastDate = dates.length > 0 ? dates[dates.length - 1] : null;

  const { processing, runPost } = useInertiaAction();

  const { data, setData } = useForm({
    log_date: logDate,
    readings: points.map((p) => {
      const existing = p.readings[logDate];
      return {
        point_id: p.id,
        temperature: existing?.temperature != null ? String(existing.temperature) : "",
        relative_humidity: existing?.relative_humidity != null ? String(existing.relative_humidity) : "",
      };
    }),
  });

  const setReadingField = (index: number, field: "temperature" | "relative_humidity", value: string) => {
    const updated = [...data.readings];
    updated[index] = { ...updated[index], [field]: value };
    setData("readings", updated);
  };

  const handleDateChange = (newDate: string) => {
    setLogDate(newDate);
    setData("log_date", newDate);

    const updated = data.readings.map((r, i) => {
      const existingReading = points[i].readings[newDate];
      return {
        ...r,
        temperature: existingReading?.temperature != null ? String(existingReading.temperature) : "",
        relative_humidity: existingReading?.relative_humidity != null ? String(existingReading.relative_humidity) : "",
      };
    });
    setData("readings", updated);
  };

  const handleCopyPrevious = () => {
    if (!lastDate) return;
    const updated = data.readings.map((r, i) => {
      const prev = points[i].readings[lastDate];
      return {
        ...r,
        temperature: r.temperature || (prev?.temperature != null ? String(prev.temperature) : ""),
        relative_humidity: r.relative_humidity || (prev?.relative_humidity != null ? String(prev.relative_humidity) : ""),
      };
    });
    setData("readings", updated);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const filtered = data.readings.filter((r) => r.temperature !== "" || r.relative_humidity !== "");
    if (filtered.length === 0) return;
    runPost(batchSavePath, {
      log_date: data.log_date,
      readings: filtered,
    }, {
      preserveState: true,
      onSuccess: () => onClose(),
    });
  };

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="sm:max-w-3xl max-h-[80vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Record Psychrometric Readings</DialogTitle>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="flex items-center gap-3">
            <div>
              <label className="text-xs font-medium text-muted-foreground">Date</label>
              <Input
                type="date"
                value={logDate}
                onChange={(e) => handleDateChange(e.target.value)}
                className="mt-1 w-44"
                required
              />
            </div>
            {lastDate && (
              <Button type="button" variant="outline" size="sm" className="mt-5 text-xs" onClick={handleCopyPrevious}>
                Copy from previous
              </Button>
            )}
          </div>

          {/* Desktop: table layout */}
          <div className="hidden sm:block border rounded-lg overflow-hidden">
            <table className="w-full text-sm">
              <thead className="bg-muted">
                <tr>
                  <th className="px-3 py-2 text-left text-xs font-semibold uppercase text-muted-foreground">Unit</th>
                  <th className="px-3 py-2 text-left text-xs font-semibold uppercase text-muted-foreground">Room</th>
                  <th className="px-3 py-2 text-left text-xs font-semibold uppercase text-muted-foreground">Dehu</th>
                  <th className="px-3 py-2 text-center text-xs font-semibold uppercase text-muted-foreground">Rh%</th>
                  <th className="px-3 py-2 text-center text-xs font-semibold uppercase text-muted-foreground">F&deg;</th>
                  <th className="px-3 py-2 text-center text-xs font-semibold uppercase text-muted-foreground">GPP</th>
                </tr>
              </thead>
              <tbody>
                {points.map((point, i) => {
                  const gpp = calculateGpp(data.readings[i].temperature, data.readings[i].relative_humidity);
                  return (
                    <tr key={point.id} className="border-t border-border">
                      <td className="px-3 py-2 text-sm">{point.unit}</td>
                      <td className="px-3 py-2 text-sm text-muted-foreground">{point.room}</td>
                      <td className="px-3 py-2 text-sm text-muted-foreground">{point.dehumidifier_label || "—"}</td>
                      <td className="px-3 py-2">
                        <Input
                          type="number"
                          step="0.1"
                          min="0"
                          max="100"
                          value={data.readings[i].relative_humidity}
                          onChange={(e) => setReadingField(i, "relative_humidity", e.target.value)}
                          className="h-8 w-20 text-center mx-auto"
                        />
                      </td>
                      <td className="px-3 py-2">
                        <Input
                          type="number"
                          step="0.1"
                          value={data.readings[i].temperature}
                          onChange={(e) => setReadingField(i, "temperature", e.target.value)}
                          className="h-8 w-20 text-center mx-auto"
                        />
                      </td>
                      <td className="px-3 py-2 text-center text-sm text-muted-foreground">
                        {gpp || "—"}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>

          {/* Mobile: card layout */}
          <div className="sm:hidden space-y-2">
            {points.map((point, i) => {
              const gpp = calculateGpp(data.readings[i].temperature, data.readings[i].relative_humidity);
              return (
                <div key={point.id} className="border rounded-lg p-3 space-y-2">
                  <div className="flex items-center justify-between">
                    <div className="text-sm font-medium">
                      {point.unit} &middot; {point.room}
                    </div>
                    {point.dehumidifier_label && (
                      <div className="text-xs text-muted-foreground">{point.dehumidifier_label}</div>
                    )}
                  </div>
                  <div className="grid grid-cols-3 gap-2">
                    <div>
                      <label className="text-xs text-muted-foreground">Rh%</label>
                      <Input
                        type="number"
                        step="0.1"
                        min="0"
                        max="100"
                        value={data.readings[i].relative_humidity}
                        onChange={(e) => setReadingField(i, "relative_humidity", e.target.value)}
                        className="h-9"
                      />
                    </div>
                    <div>
                      <label className="text-xs text-muted-foreground">F&deg;</label>
                      <Input
                        type="number"
                        step="0.1"
                        value={data.readings[i].temperature}
                        onChange={(e) => setReadingField(i, "temperature", e.target.value)}
                        className="h-9"
                      />
                    </div>
                    <div>
                      <label className="text-xs text-muted-foreground">GPP</label>
                      <div className="h-9 flex items-center text-sm text-muted-foreground">{gpp || "—"}</div>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>

          <div className="flex justify-end gap-2">
            <Button type="button" variant="outline" onClick={onClose}>Cancel</Button>
            <Button type="submit" disabled={processing}>
              {processing ? "Saving..." : "Save Readings"}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}
