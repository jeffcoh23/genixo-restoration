import { useMemo, useRef, useEffect } from "react";
import { router } from "@inertiajs/react";
import { Gantt } from "@svar-ui/react-gantt";
import { Material } from "@svar-ui/react-core";
import "@svar-ui/react-gantt/all.css";
import type { TimelineUnit } from "../timeline-types";

interface GanttChartProps {
  units: TimelineUnit[];
  canManage: boolean;
}

export default function GanttChart({ units, canManage }: GanttChartProps) {
  const apiRef = useRef(null);

  const tasks = useMemo(() => {
    const ganttTasks: Record<string, unknown>[] = [];

    units.forEach((unit) => {
      ganttTasks.push({
        id: `unit-${unit.id}`,
        text: unit.unit_number,
        open: true,
        type: "summary",
        start: unit.min_start_date ? parseDate(unit.min_start_date) : new Date(),
        duration: 1,
        _needsVacant: unit.needs_vacant,
      });

      unit.tasks.forEach((task) => {
        const start = parseDate(task.start_date);
        const end = parseDate(task.end_date);
        const diffDays = Math.max(1, Math.ceil((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24)) + 1);

        ganttTasks.push({
          id: `task-${task.id}`,
          parent: `unit-${unit.id}`,
          text: task.activity,
          start,
          duration: diffDays,
          type: "task",
          progress: 0,
          _endDate: end,
          _needsVacant: unit.needs_vacant,
          _updatePath: task.update_path,
        });
      });
    });

    return ganttTasks;
  }, [units]);

  const scales = useMemo(() => [
    { unit: "month", step: 1, format: "MMMM yyy" },
    { unit: "day", step: 1, format: "d" },
  ], []);

  const columns = useMemo(() => [
    { id: "text", header: "Activity", flexgrow: 1 },
    {
      id: "start",
      header: "Start Date",
      width: 90,
      template: (task: Record<string, unknown>) => {
        const d = task.start as Date | undefined;
        return d ? formatDate(d) : "";
      },
    },
    {
      id: "end_date",
      header: "End Date",
      width: 90,
      getter: (task: Record<string, unknown>) => task._endDate,
      template: (task: Record<string, unknown>) => {
        const d = task._endDate as Date | undefined;
        return d ? formatDate(d) : "";
      },
    },
    {
      id: "needs_vacant",
      header: "Vacant",
      width: 60,
      align: "center" as const,
      getter: (task: Record<string, unknown>) => task._needsVacant,
      template: (task: Record<string, unknown>) =>
        task._needsVacant ? "Yes" : "",
    },
  ], []);

  useEffect(() => {
    const api = apiRef.current as Record<string, unknown> | null;
    if (!api || !canManage) return;

    const onFn = api.on as ((event: string, cb: (ev: Record<string, unknown>) => void) => void) | undefined;
    const getTaskFn = api.getTask as ((id: string | number) => Record<string, unknown> | null) | undefined;
    if (!onFn || !getTaskFn) return;

    onFn("update-task", (ev) => {
      if (ev.inProgress) return;

      const taskId = ev.id as string | number;
      if (typeof taskId !== "string" || !taskId.startsWith("task-")) return;

      const ganttTask = getTaskFn(taskId);
      if (!ganttTask) return;
      const updatePath = ganttTask._updatePath as string | null | undefined;
      if (!updatePath) return;

      const taskData = ev.task as Record<string, unknown> | undefined;
      const startDate = (ganttTask.start || taskData?.start) as Date | undefined;
      const duration = ((taskData?.duration || ganttTask.duration) as number) || 0;

      if (startDate && duration) {
        const start = new Date(startDate);
        const end = new Date(start);
        end.setDate(end.getDate() + duration - 1);

        router.patch(updatePath, {
          incident_task: {
            start_date: toISO(start),
            end_date: toISO(end),
          },
        }, { preserveScroll: true });
      }
    });
  }, [canManage]);

  if (tasks.length === 0) return null;

  return (
    <Material>
      <div className="gantt-wrapper border border-border rounded-lg overflow-hidden" style={{ height: 500 }}>
        <Gantt
          api={apiRef}
          tasks={tasks}
          scales={scales}
          columns={columns}
          readonly={!canManage}
        />
      </div>
    </Material>
  );
}

function formatDate(date: Date): string {
  return date.toLocaleDateString("en-US", { month: "short", day: "numeric" });
}

function parseDate(iso: string): Date {
  const [y, m, d] = iso.split("-").map(Number);
  return new Date(y, m - 1, d);
}

function toISO(date: Date): string {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, "0");
  const d = String(date.getDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}
