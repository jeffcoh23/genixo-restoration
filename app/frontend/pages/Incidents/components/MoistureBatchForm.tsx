import { useState } from "react";
import { router, useForm, usePage } from "@inertiajs/react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { SharedProps } from "@/types";
import type { MoisturePoint } from "../types";

interface MoistureBatchFormProps {
  points: MoisturePoint[];
  dates: string[];
  batchSavePath: string;
  onClose: () => void;
}

export default function MoistureBatchForm({ points, dates, batchSavePath, onClose }: MoistureBatchFormProps) {
  const { today } = usePage<SharedProps>().props;
  const [logDate, setLogDate] = useState(today);

  const lastDate = dates.length > 0 ? dates[dates.length - 1] : null;

  const [submitting, setSubmitting] = useState(false);

  const { data, setData } = useForm({
    log_date: logDate,
    readings: points.map((p) => ({
      point_id: p.id,
      value: "",
    })),
  });

  const setReadingValue = (index: number, value: string) => {
    const updated = [...data.readings];
    updated[index] = { ...updated[index], value };
    setData("readings", updated);
  };

  const handleDateChange = (newDate: string) => {
    setLogDate(newDate);
    setData("log_date", newDate);

    const updated = data.readings.map((r, i) => {
      const existingReading = points[i].readings[newDate];
      return {
        ...r,
        value: existingReading?.value !== null && existingReading?.value !== undefined
          ? String(existingReading.value)
          : "",
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
        value: r.value || (prev?.value !== null && prev?.value !== undefined ? String(prev.value) : ""),
      };
    });
    setData("readings", updated);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const filtered = data.readings.filter((r) => r.value !== "");
    if (filtered.length === 0) return;
    setSubmitting(true);
    router.post(batchSavePath, {
      log_date: data.log_date,
      readings: filtered,
    }, {
      onSuccess: () => onClose(),
      onFinish: () => setSubmitting(false),
    });
  };

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="sm:max-w-2xl max-h-[80vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Record Moisture Readings</DialogTitle>
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
                  <th className="px-3 py-2 text-left text-xs font-semibold uppercase text-muted-foreground">Item</th>
                  <th className="px-3 py-2 text-left text-xs font-semibold uppercase text-muted-foreground">Material</th>
                  <th className="px-3 py-2 text-center text-xs font-semibold uppercase text-muted-foreground">Goal</th>
                  <th className="px-3 py-2 text-center text-xs font-semibold uppercase text-muted-foreground">Prev</th>
                  <th className="px-3 py-2 text-center text-xs font-semibold uppercase text-muted-foreground">Value</th>
                </tr>
              </thead>
              <tbody>
                {points.map((point, i) => {
                  const prevReading = lastDate ? point.readings[lastDate] : null;
                  const prevValue = prevReading?.value;
                  return (
                    <tr key={point.id} className="border-t border-border">
                      <td className="px-3 py-2 text-sm">{point.unit}</td>
                      <td className="px-3 py-2 text-sm text-muted-foreground">{point.room}</td>
                      <td className="px-3 py-2 text-sm text-muted-foreground">{point.item}</td>
                      <td className="px-3 py-2 text-sm text-muted-foreground">{point.material}</td>
                      <td className="px-3 py-2 text-sm text-center text-muted-foreground">{point.goal}</td>
                      <td className="px-3 py-2 text-sm text-center text-muted-foreground">
                        {prevValue !== null && prevValue !== undefined ? prevValue : "—"}
                      </td>
                      <td className="px-3 py-2">
                        <Input
                          type="number"
                          step="0.1"
                          min="0"
                          value={data.readings[i].value}
                          onChange={(e) => setReadingValue(i, e.target.value)}
                          className="h-8 w-20 text-center mx-auto"
                        />
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
              const prevReading = lastDate ? point.readings[lastDate] : null;
              const prevValue = prevReading?.value;
              return (
                <div key={point.id} className="border rounded-lg p-3 space-y-2">
                  <div className="flex items-center justify-between">
                    <div className="text-sm font-medium">
                      {point.unit} &middot; {point.room} &middot; {point.item}
                    </div>
                    <div className="text-xs text-muted-foreground">
                      Goal: {point.goal} {point.measurement_unit}
                    </div>
                  </div>
                  <div className="flex items-center gap-3">
                    <Input
                      type="number"
                      step="0.1"
                      min="0"
                      value={data.readings[i].value}
                      onChange={(e) => setReadingValue(i, e.target.value)}
                      className="h-9 flex-1"
                      placeholder={prevValue !== null && prevValue !== undefined ? `Prev: ${prevValue}` : ""}
                    />
                    <div className="text-xs text-muted-foreground whitespace-nowrap">
                      {point.material}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>

          <div className="flex justify-end gap-2">
            <Button type="button" variant="outline" onClick={onClose}>Cancel</Button>
            <Button type="submit" disabled={submitting}>
              {submitting ? "Saving..." : "Save Readings"}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}
