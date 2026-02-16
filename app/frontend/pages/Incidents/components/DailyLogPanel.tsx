import { useState } from "react";
import {
  ArrowDown,
  ArrowUp,
  Clock,
  Ellipsis,
  FileText,
  MoveRight,
  Pencil,
  Plus,
  StickyNote,
  Upload,
  Wrench,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import type {
  AssignableUser,
  AttachableEquipmentEntry,
  DailyActivity,
  DailyLogDate,
  EquipmentType,
  IncidentAttachment,
  LaborEntry,
  OperationalNote,
} from "../types";
import ActivityForm from "./ActivityForm";
import AttachmentForm from "./AttachmentForm";
import LaborForm from "./LaborForm";
import NoteForm from "./NoteForm";

interface DailyLogPanelProps {
  daily_activities: DailyActivity[];
  daily_log_dates: DailyLogDate[];
  labor_entries: LaborEntry[];
  operational_notes: OperationalNote[];
  attachments: IncidentAttachment[];
  can_manage_activities: boolean;
  can_manage_labor: boolean;
  can_create_notes: boolean;
  activity_entries_path: string;
  labor_entries_path: string;
  operational_notes_path: string;
  attachments_path: string;
  assignable_labor_users: AssignableUser[];
  equipment_types: EquipmentType[];
  attachable_equipment_entries: AttachableEquipmentEntry[];
}

export default function DailyLogPanel({
  daily_activities = [],
  daily_log_dates = [],
  labor_entries = [],
  operational_notes = [],
  attachments = [],
  can_manage_activities,
  can_manage_labor,
  can_create_notes,
  activity_entries_path,
  labor_entries_path,
  operational_notes_path,
  attachments_path,
  assignable_labor_users,
  equipment_types,
  attachable_equipment_entries,
}: DailyLogPanelProps) {
  const dates = daily_log_dates;
  const [selectedDate, setSelectedDate] = useState<string | null>(dates[0]?.key ?? null);
  const [activityForm, setActivityForm] = useState<{ open: boolean; entry?: DailyActivity }>({ open: false });
  const [laborForm, setLaborForm] = useState<{ open: boolean; entry?: LaborEntry }>({ open: false });
  const [showNoteForm, setShowNoteForm] = useState(false);
  const [showAttachmentForm, setShowAttachmentForm] = useState(false);

  const hasNoActivity = daily_activities.length === 0 &&
    labor_entries.length === 0 &&
    operational_notes.length === 0 &&
    attachments.length === 0;

  if (hasNoActivity && !can_manage_activities && !can_manage_labor && !can_create_notes) {
    return (
      <div className="flex-1 flex items-center justify-center text-muted-foreground text-sm py-12">
        No activity recorded yet.
      </div>
    );
  }

  const filteredActivities = selectedDate
    ? daily_activities.filter((entry) => entry.date_key === selectedDate)
    : daily_activities;
  const filteredLabor = selectedDate ? labor_entries.filter((entry) => entry.log_date === selectedDate) : labor_entries;
  const filteredNotes = selectedDate ? operational_notes.filter((entry) => entry.log_date === selectedDate) : operational_notes;
  const filteredAttachments = selectedDate ? attachments.filter((entry) => entry.log_date === selectedDate) : attachments;

  return (
    <div className="flex flex-col h-full">
      {dates.length > 0 && (
        <div className="flex gap-1 p-3 border-b border-border overflow-x-auto shrink-0">
          <Button
            variant={selectedDate === null ? "default" : "ghost"}
            size="sm"
            onClick={() => setSelectedDate(null)}
            className="h-7 text-xs whitespace-nowrap"
          >
            All Dates
          </Button>
          {dates.map((dateEntry) => {
            return (
              <Button
                key={dateEntry.key}
                variant={selectedDate === dateEntry.key ? "default" : "ghost"}
                size="sm"
                onClick={() => setSelectedDate(dateEntry.key)}
                className="h-7 text-xs whitespace-nowrap"
              >
                {dateEntry.label}
              </Button>
            );
          })}
        </div>
      )}

      <div className="flex-1 overflow-y-auto p-3 pb-8 space-y-5">
        <LogSection
          title="Activities"
          icon={<Wrench className="h-4 w-4" />}
          count={filteredActivities.length}
          showAdd={can_manage_activities}
          onAdd={() => setActivityForm({ open: true })}
          addLabel="Add Activity"
        >
          {filteredActivities.map((entry) => (
            <ActivityEntryRow
              key={entry.id}
              entry={entry}
              onEdit={entry.edit_path ? () => setActivityForm({ open: true, entry }) : undefined}
            />
          ))}
        </LogSection>

        <LogSection
          title="Labor"
          icon={<Clock className="h-4 w-4" />}
          count={filteredLabor.length}
          showAdd={can_manage_labor}
          onAdd={() => setLaborForm({ open: true })}
          addLabel="Add Labor"
        >
          {filteredLabor.map((entry) => (
            <LaborEntryRow key={entry.id} entry={entry} onEdit={() => setLaborForm({ open: true, entry })} />
          ))}
        </LogSection>

        <LogSection
          title="Notes"
          icon={<StickyNote className="h-4 w-4" />}
          count={filteredNotes.length}
          showAdd={can_create_notes}
          onAdd={() => setShowNoteForm(true)}
          addLabel="Add Note"
        >
          {filteredNotes.map((note) => (
            <NoteRow key={note.id} note={note} />
          ))}
        </LogSection>

        <LogSection
          title="Documents"
          icon={<FileText className="h-4 w-4" />}
          count={filteredAttachments.length}
          showAdd={true}
          onAdd={() => setShowAttachmentForm(true)}
          addLabel="Upload"
          addIcon={<Upload className="h-3 w-3" />}
        >
          {filteredAttachments.map((attachment) => (
            <AttachmentRow key={attachment.id} attachment={attachment} />
          ))}
        </LogSection>
      </div>

      {activityForm.open && (
        <ActivityForm
          path={activity_entries_path}
          entry={activityForm.entry}
          equipment_types={equipment_types}
          attachable_equipment_entries={attachable_equipment_entries}
          onClose={() => setActivityForm({ open: false })}
        />
      )}
      {laborForm.open && (
        <LaborForm
          path={labor_entries_path}
          users={assignable_labor_users}
          entry={laborForm.entry}
          onClose={() => setLaborForm({ open: false })}
        />
      )}
      {showNoteForm && (
        <NoteForm path={operational_notes_path} onClose={() => setShowNoteForm(false)} />
      )}
      {showAttachmentForm && (
        <AttachmentForm path={attachments_path} onClose={() => setShowAttachmentForm(false)} />
      )}
    </div>
  );
}

function LogSection({
  title,
  icon,
  count,
  showAdd,
  onAdd,
  addLabel,
  addIcon,
  children,
}: {
  title: string;
  icon: React.ReactNode;
  count: number;
  showAdd: boolean;
  onAdd: () => void;
  addLabel: string;
  addIcon?: React.ReactNode;
  children: React.ReactNode;
}) {
  return (
    <div>
      <div className="flex items-center justify-between mb-2">
        <div className="flex items-center gap-1.5 text-xs font-semibold uppercase tracking-wider text-muted-foreground">
          {icon}
          {title}
          {count > 0 && <span className="text-foreground ml-1">({count})</span>}
        </div>
        {showAdd && (
          <Button variant="ghost" size="sm" className="h-7 text-xs gap-1" onClick={onAdd}>
            {addIcon ?? <Plus className="h-3 w-3" />}
            {addLabel}
          </Button>
        )}
      </div>
      {count === 0 ? <p className="text-xs text-muted-foreground italic">None</p> : <div className="space-y-1.5">{children}</div>}
    </div>
  );
}

function ActivityEntryRow({
  entry,
  onEdit,
}: {
  entry: DailyActivity;
  onEdit?: () => void;
}) {
  return (
    <div className="bg-muted rounded border border-border p-2.5 text-sm">
      <div className="flex items-start justify-between gap-2">
        <div className="min-w-0">
          <div className="flex flex-wrap items-center gap-1.5">
            <span className="font-medium text-foreground">{entry.title}</span>
            <span className="text-xs rounded border border-border bg-background px-1.5 py-0.5">{entry.status_label}</span>
            <span className="text-xs text-muted-foreground">{entry.occurred_at_label}</span>
          </div>
          <p className="text-xs text-muted-foreground mt-0.5">{entry.created_by_name}</p>
        </div>
        {onEdit && (
          <Button variant="ghost" size="sm" className="h-6 px-2 gap-1 text-xs" onClick={onEdit}>
            <Pencil className="h-3 w-3" />
            Edit
          </Button>
        )}
      </div>

      {(entry.units_affected || entry.units_affected_description) && (
        <p className="text-xs mt-1.5">
          <span className="font-medium">Units affected:</span>{" "}
          {entry.units_affected ? `${entry.units_affected}` : "n/a"}
          {entry.units_affected_description ? ` · ${entry.units_affected_description}` : ""}
        </p>
      )}

      {entry.details && (
        <p className="text-xs mt-1.5 whitespace-pre-wrap">
          <span className="font-medium">Details:</span> {entry.details}
        </p>
      )}

      {entry.equipment_actions.length > 0 && (
        <div className="mt-2 space-y-1">
          {entry.equipment_actions.map((action) => (
            <div key={action.id} className="flex items-start gap-1.5 text-xs">
              <EquipmentActionIcon action={action.action_type} />
              <span className="font-medium">{action.action_label}</span>
              {action.quantity && <span>{action.quantity}</span>}
              {action.type_name && <span>{action.type_name}</span>}
              {action.note && <span className="text-muted-foreground">· {action.note}</span>}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

function EquipmentActionIcon({ action }: { action: "add" | "remove" | "move" | "other" }) {
  if (action === "add") return <ArrowUp className="h-3.5 w-3.5 text-green-600 mt-0.5 shrink-0" />;
  if (action === "remove") return <ArrowDown className="h-3.5 w-3.5 text-destructive mt-0.5 shrink-0" />;
  if (action === "move") return <MoveRight className="h-3.5 w-3.5 text-muted-foreground mt-0.5 shrink-0" />;
  return <Ellipsis className="h-3.5 w-3.5 text-muted-foreground mt-0.5 shrink-0" />;
}

function LaborEntryRow({ entry, onEdit }: { entry: LaborEntry; onEdit: () => void }) {
  return (
    <div className="bg-muted rounded p-2.5 text-sm">
      <div className="flex items-center justify-between">
        <span className="font-medium">
          {entry.role_label}
          {entry.user_name && <span className="text-muted-foreground font-normal"> · {entry.user_name}</span>}
        </span>
        <div className="flex items-center gap-1.5">
          <span className="text-xs font-medium">{entry.hours}h</span>
          {entry.edit_path && (
            <Button variant="ghost" size="sm" className="h-6 w-6 p-0" onClick={onEdit}>
              <Pencil className="h-3 w-3" />
            </Button>
          )}
        </div>
      </div>
      {(entry.started_at_label || entry.notes) && (
        <div className="text-xs text-muted-foreground mt-1">
          {entry.started_at_label && entry.ended_at_label && <span>{entry.started_at_label} - {entry.ended_at_label}</span>}
          {entry.started_at_label && entry.notes && <span> · </span>}
          {entry.notes && <span>{entry.notes}</span>}
        </div>
      )}
    </div>
  );
}

function NoteRow({ note }: { note: OperationalNote }) {
  return (
    <div className="bg-muted rounded p-2.5 text-sm">
      <p className="text-sm whitespace-pre-wrap">{note.note_text}</p>
      <p className="text-xs text-muted-foreground mt-1">
        {note.created_by_name} · {note.created_at_label}
      </p>
    </div>
  );
}

function AttachmentRow({ attachment }: { attachment: IncidentAttachment }) {
  return (
    <a
      href={attachment.url}
      target="_blank"
      rel="noopener noreferrer"
      className="block bg-muted rounded p-2.5 hover:bg-accent transition-colors"
    >
      <div className="flex items-start gap-2">
        <FileText className="h-4 w-4 text-muted-foreground mt-0.5 shrink-0" />
        <div className="min-w-0">
          <p className="text-sm font-medium truncate">{attachment.filename}</p>
          {attachment.description && (
            <p className="text-xs text-muted-foreground">{attachment.description}</p>
          )}
          <p className="text-xs text-muted-foreground mt-0.5">
            {attachment.category_label} · {attachment.log_date_label ?? attachment.created_at_label} · {attachment.uploaded_by_name}
          </p>
        </div>
      </div>
    </a>
  );
}
