import { Link, router, usePage } from "@inertiajs/react";
import { useState } from "react";
import { Plus, Pencil, Trash2, CalendarRange, Home } from "lucide-react";
import AppLayout from "@/layout/AppLayout";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { SharedProps } from "@/types";
import { statusColor } from "@/lib/statusColor";
import GanttChart from "./components/GanttChart";
import UnitForm from "./components/UnitForm";
import TaskForm from "./components/TaskForm";
import type { TimelineProps, TimelineUnit } from "./timeline-types";

export default function Timeline() {
  const { incident, units, can_manage, create_unit_path, back_path } =
    usePage<SharedProps & TimelineProps>().props;

  const [showUnitForm, setShowUnitForm] = useState(false);
  const [editingUnit, setEditingUnit] = useState<TimelineUnit | null>(null);
  const [taskFormUnit, setTaskFormUnit] = useState<{ unit: TimelineUnit; task?: TimelineUnit["tasks"][0] } | null>(null);

  const handleDeleteUnit = (unit: TimelineUnit) => {
    if (!unit.destroy_path) return;
    if (!confirm(`Delete unit "${unit.unit_number}" and all its tasks?`)) return;
    router.delete(unit.destroy_path, { preserveScroll: true });
  };

  const handleDeleteTask = (unit: TimelineUnit, task: TimelineUnit["tasks"][0]) => {
    if (!task.destroy_path) return;
    if (!confirm(`Delete task "${task.activity}"?`)) return;
    router.delete(task.destroy_path, { preserveScroll: true });
  };

  const hasAnyTasks = units.some((u) => u.tasks.length > 0);

  return (
    <AppLayout full>
      {/* Back link */}
      <div className="mb-4">
        <Link href={back_path} className="text-sm text-muted-foreground hover:text-foreground">
          &larr; Back to Incident
        </Link>
      </div>

      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 mb-6">
        <div>
          <div className="flex items-center gap-2 text-sm text-muted-foreground mb-1">
            <span>{incident.property.organization_name}</span>
            <span>&middot;</span>
            <span>{incident.property.name}</span>
          </div>
          <div className="flex items-center gap-3">
            <h1 className="text-xl font-semibold text-foreground flex items-center gap-2">
              <CalendarRange className="h-5 w-5" />
              Project Timeline
            </h1>
            <Badge className={`text-xs ${statusColor(incident.display_status)}`}>
              {incident.status_label}
            </Badge>
          </div>
        </div>

        {can_manage && create_unit_path && (
          <Button size="sm" onClick={() => setShowUnitForm(true)} className="gap-1.5">
            <Plus className="h-3.5 w-3.5" />
            Add Unit
          </Button>
        )}
      </div>

      {/* Gantt chart */}
      {hasAnyTasks && (
        <div className="mb-6">
          <GanttChart units={units} canManage={can_manage} />
        </div>
      )}

      {/* Units + tasks table */}
      {units.length === 0 ? (
        <div className="bg-card rounded-lg border border-border shadow-sm p-12 text-center">
          <Home className="h-10 w-10 text-muted-foreground mx-auto mb-3" />
          <h2 className="text-lg font-medium text-foreground mb-1">No units yet</h2>
          <p className="text-sm text-muted-foreground mb-4">
            Add units (rooms, areas, common spaces) and then schedule activities for each.
          </p>
          {can_manage && create_unit_path && (
            <Button size="sm" onClick={() => setShowUnitForm(true)} className="gap-1.5">
              <Plus className="h-3.5 w-3.5" />
              Add First Unit
            </Button>
          )}
        </div>
      ) : (
        <div className="bg-card rounded-lg border border-border shadow-sm overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-border bg-muted/30">
                <th className="text-left px-4 py-2.5 font-medium text-muted-foreground">Unit / Activity</th>
                <th className="text-left px-4 py-2.5 font-medium text-muted-foreground">Start</th>
                <th className="text-left px-4 py-2.5 font-medium text-muted-foreground">End</th>
                <th className="text-center px-4 py-2.5 font-medium text-muted-foreground">Vacant</th>
                {can_manage && (
                  <th className="text-right px-4 py-2.5 font-medium text-muted-foreground w-28">Actions</th>
                )}
              </tr>
            </thead>
            <tbody>
              {units.map((unit) => (
                <UnitSection
                  key={unit.id}
                  unit={unit}
                  canManage={can_manage}
                  onEditUnit={() => setEditingUnit(unit)}
                  onDeleteUnit={() => handleDeleteUnit(unit)}
                  onAddTask={() => setTaskFormUnit({ unit })}
                  onEditTask={(task) => setTaskFormUnit({ unit, task })}
                  onDeleteTask={(task) => handleDeleteTask(unit, task)}
                />
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Dialogs */}
      {showUnitForm && create_unit_path && (
        <UnitForm path={create_unit_path} onClose={() => setShowUnitForm(false)} />
      )}
      {editingUnit && editingUnit.update_path && (
        <UnitForm
          path={editingUnit.update_path}
          unit={editingUnit}
          onClose={() => setEditingUnit(null)}
        />
      )}
      {taskFormUnit && (
        <TaskForm
          path={taskFormUnit.task?.update_path ?? taskFormUnit.unit.create_task_path!}
          unitName={taskFormUnit.unit.unit_number}
          task={taskFormUnit.task}
          onClose={() => setTaskFormUnit(null)}
        />
      )}
    </AppLayout>
  );
}

// --- Sub-component for each unit section in the table ---

interface UnitSectionProps {
  unit: TimelineUnit;
  canManage: boolean;
  onEditUnit: () => void;
  onDeleteUnit: () => void;
  onAddTask: () => void;
  onEditTask: (task: TimelineUnit["tasks"][0]) => void;
  onDeleteTask: (task: TimelineUnit["tasks"][0]) => void;
}

function UnitSection({ unit, canManage, onEditUnit, onDeleteUnit, onAddTask, onEditTask, onDeleteTask }: UnitSectionProps) {
  return (
    <>
      {/* Unit header row */}
      <tr className="border-b border-border bg-muted/10">
        <td className="px-4 py-2.5 font-medium text-foreground">{unit.unit_number}</td>
        <td className="px-4 py-2.5" />
        <td className="px-4 py-2.5" />
        <td className="px-4 py-2.5 text-center">
          {unit.needs_vacant && (
            <Badge variant="outline" className="text-xs">Yes</Badge>
          )}
        </td>
        {canManage && (
          <td className="px-4 py-2.5 text-right">
            <div className="flex items-center justify-end gap-1">
              <Button variant="ghost" size="sm" className="h-7 w-7 p-0" onClick={onAddTask} title="Add task">
                <Plus className="h-3.5 w-3.5" />
              </Button>
              <Button variant="ghost" size="sm" className="h-7 w-7 p-0" onClick={onEditUnit} title="Edit unit">
                <Pencil className="h-3.5 w-3.5" />
              </Button>
              <Button variant="ghost" size="sm" className="h-7 w-7 p-0 text-destructive hover:text-destructive" onClick={onDeleteUnit} title="Delete unit">
                <Trash2 className="h-3.5 w-3.5" />
              </Button>
            </div>
          </td>
        )}
      </tr>

      {/* Task rows */}
      {unit.tasks.map((task) => (
        <tr key={task.id} className="border-b border-border last:border-b-0">
          <td className="px-4 py-2 pl-8 text-foreground">{task.activity}</td>
          <td className="px-4 py-2 text-muted-foreground">{task.start_date_label}</td>
          <td className="px-4 py-2 text-muted-foreground">{task.end_date_label}</td>
          <td className="px-4 py-2" />
          {canManage && (
            <td className="px-4 py-2 text-right">
              <div className="flex items-center justify-end gap-1">
                <Button variant="ghost" size="sm" className="h-7 w-7 p-0" onClick={() => onEditTask(task)} title="Edit task">
                  <Pencil className="h-3.5 w-3.5" />
                </Button>
                <Button variant="ghost" size="sm" className="h-7 w-7 p-0 text-destructive hover:text-destructive" onClick={() => onDeleteTask(task)} title="Delete task">
                  <Trash2 className="h-3.5 w-3.5" />
                </Button>
              </div>
            </td>
          )}
        </tr>
      ))}

      {/* Empty state for unit with no tasks */}
      {unit.tasks.length === 0 && (
        <tr className="border-b border-border">
          <td colSpan={canManage ? 5 : 4} className="px-4 py-3 pl-8 text-sm text-muted-foreground italic">
            No tasks yet.{" "}
            {canManage && (
              <Button variant="link" size="sm" className="h-auto p-0 not-italic" onClick={onAddTask}>
                Add one
              </Button>
            )}
          </td>
        </tr>
      )}
    </>
  );
}