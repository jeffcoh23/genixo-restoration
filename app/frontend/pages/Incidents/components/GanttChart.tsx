import { useMemo, useRef, useEffect } from "react";
import { router } from "@inertiajs/react";
import { Gantt } from "@svar-ui/react-gantt";
import { Material } from "@svar-ui/react-core";
import "@svar-ui/react-gantt/all.css";
import type { TimelineUnit } from "../timeline-types";
import { parseDate, toISO } from "../gantt-utils";

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
          _startLabel: task.start_date_label,
          _endLabel: task.end_date_label,
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
      template: (task: Record<string, unknown>) =>
        (task._startLabel as string) ?? "",
    },
    {
      id: "end_date",
      header: "End Date",
      width: 90,
      getter: (task: Record<string, unknown>) => task._endDate,
      template: (task: Record<string, unknown>) =>
        (task._endLabel as string) ?? "",
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
        router.patch(updatePath, {
          incident_task: {
            start_date: toISO(startDate),
            duration_days: duration,
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

