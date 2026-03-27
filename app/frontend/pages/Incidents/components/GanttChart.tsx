import { useMemo, useRef, useEffect } from "react";
import { router } from "@inertiajs/react";
import { Gantt } from "wx-react-gantt";
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

export default function GanttChart({ units, canManage }: GanttChartProps) {
  const apiRef = useRef<any>(null);

  // Map backend data to SVAR Gantt task format
  const tasks = useMemo(() => {
    const ganttTasks: any[] = [];

    units.forEach((unit, unitIndex) => {
      const color = UNIT_COLORS[unitIndex % UNIT_COLORS.length];

      // Parent row (summary) for the unit
      ganttTasks.push({
        id: `unit-${unit.id}`,
        text: unit.unit_number,
        open: true,
        type: "summary",
        start: unit.tasks.length > 0
          ? new Date(Math.min(...unit.tasks.map(t => new Date(t.start_date).getTime())))
          : new Date(),
        duration: 1,
        // Custom fields for display
        _unitId: unit.id,
        _isUnit: true,
        _needsVacant: unit.needs_vacant,
        _color: color,
      });

      // Child rows (tasks)
      unit.tasks.forEach((task) => {
        const start = new Date(task.start_date);
        const end = new Date(task.end_date);
        const diffDays = Math.max(1, Math.ceil((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24)) + 1);

        ganttTasks.push({
          id: `task-${task.id}`,
          parent: `unit-${unit.id}`,
          text: task.activity,
          start: start,
          duration: diffDays,
          type: "task",
          progress: 0,
          // Custom fields
          _taskId: task.id,
          _unitId: unit.id,
          _startDate: task.start_date,
          _endDate: task.end_date,
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

    api.on("update-task", (ev: any) => {
      if (ev.inProgress) return;

      const taskData = ev.task;
      const taskId = ev.id;

      // Only handle actual task updates (not summary rows)
      if (typeof taskId === "string" && taskId.startsWith("task-")) {
        const ganttTask = api.getTask(taskId);
        if (!ganttTask?._updatePath) return;

        // Calculate new dates from the updated task
        const startDate = ganttTask.start || taskData.start;
        const duration = taskData.duration || ganttTask.duration;

        if (startDate && duration) {
          const start = new Date(startDate);
          const end = new Date(start);
          end.setDate(end.getDate() + duration - 1);

          router.patch(ganttTask._updatePath, {
            incident_task: {
              start_date: start.toISOString().split("T")[0],
              end_date: end.toISOString().split("T")[0],
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
