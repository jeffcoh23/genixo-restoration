import { useMemo, useRef, useEffect } from "react";
import { router } from "@inertiajs/react";
import { Gantt, type GanttTask, type GanttApi } from "wx-react-gantt";
import "wx-react-gantt/dist/gantt.css";
import type { TimelineUnit } from "../timeline-types";

interface GanttChartProps {
  units: TimelineUnit[];
  canManage: boolean;
}

// Distinct colors for each unit's tasks
const UNIT_COLORS = [
  "#3b82f6", // blue
  "#10b981", // emerald
  "#f59e0b", // amber
  "#ef4444", // red
  "#8b5cf6", // violet
  "#ec4899", // pink
  "#06b6d4", // cyan
  "#f97316", // orange
];

// Parse ISO date string to Date (noon UTC to avoid timezone edge cases)
function parseDate(iso: string): Date {
  const [y, m, d] = iso.split("-").map(Number);
  return new Date(y, m - 1, d);
}

// Format Date back to ISO date string for server
function toISO(date: Date): string {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, "0");
  const d = String(date.getDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

export default function GanttChart({ units, canManage }: GanttChartProps) {
  const apiRef = useRef<GanttApi>(null);

  // Map backend data to SVAR Gantt task format
  const tasks = useMemo(() => {
    const ganttTasks: GanttTask[] = [];

    units.forEach((unit, unitIndex) => {
      const color = UNIT_COLORS[unitIndex % UNIT_COLORS.length];

      // Parent row (summary) for the unit
      ganttTasks.push({
        id: `unit-${unit.id}`,
        text: unit.unit_number,
        open: true,
        type: "summary",
        start: unit.tasks.length > 0
          ? parseDate(unit.tasks.reduce((min, t) => t.start_date < min ? t.start_date : min, unit.tasks[0].start_date))
          : new Date(),
        duration: 1,
        _color: color,
      });

      // Child rows (tasks)
      unit.tasks.forEach((task) => {
        const start = parseDate(task.start_date);
        const end = parseDate(task.end_date);
        const diffDays = Math.max(1, Math.ceil((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24)) + 1);

        ganttTasks.push({
          id: `task-${task.id}`,
          parent: `unit-${unit.id}`,
          text: task.activity,
          start: start,
          duration: diffDays,
          type: "task",
          progress: 0,
          _updatePath: task.update_path,
          _color: color,
        });
      });
    });

    return ganttTasks;
  }, [units]);

  const scales = useMemo(() => [
    { unit: "month" as const, step: 1, format: "MMMM yyyy" },
    { unit: "day" as const, step: 1, format: "d" },
  ], []);

  const columns = useMemo(() => [
    { id: "text", header: "Unit / Activity", flexgrow: 3 },
    {
      id: "start",
      header: "Start",
      flexgrow: 1,
      align: "center" as const,
    },
    {
      id: "duration",
      header: "Days",
      align: "center" as const,
      flexgrow: 1,
    },
  ], []);

  // Handle drag-to-resize/move task updates
  useEffect(() => {
    if (!apiRef.current || !canManage) return;

    const api = apiRef.current;

    api.on("update-task", (ev) => {
      if (ev.inProgress) return;

      const taskData = ev.task as GanttTask | undefined;
      const taskId = ev.id as string | number;

      // Only handle actual task updates (not summary rows)
      if (typeof taskId === "string" && taskId.startsWith("task-")) {
        const ganttTask = api.getTask(taskId);
        if (!ganttTask) return;
        const updatePath = ganttTask._updatePath as string | null | undefined;
        if (!updatePath) return;

        // Calculate new dates from the updated task
        const startDate = ganttTask.start || taskData?.start;
        const duration = (taskData?.duration as number) || (ganttTask.duration as number);

        if (startDate && duration) {
          const start = new Date(startDate);
          const end = new Date(start);
          end.setDate(end.getDate() + duration - 1);

          router.patch(updatePath, {
            incident_task: {
              start_date: toISO(start),
              end_date: toISO(end),
            },
          }, {
            preserveScroll: true,
          });
        }
      }
    });
  }, [canManage]);

  if (tasks.length === 0) return null;

  return (
    <div className="gantt-wrapper border border-border rounded-lg overflow-hidden">
      <Gantt
        apiRef={apiRef}
        tasks={tasks}
        scales={scales}
        columns={columns}
        cellWidth={40}
        cellHeight={38}
        scaleHeight={36}
        readonly={!canManage}
      />
    </div>
  );
}
