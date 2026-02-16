import { useState } from "react";
import { router } from "@inertiajs/react";
import { ArrowUp, ArrowDown, Clock, FileText, Wrench, StickyNote, Plus, Upload, Pencil } from "lucide-react";
import { Button } from "@/components/ui/button";
import type {
  LaborEntry, EquipmentEntry, OperationalNote,
  IncidentAttachment, AssignableUser, EquipmentType,
} from "../types";
import LaborForm from "./LaborForm";
import EquipmentForm from "./EquipmentForm";
import NoteForm from "./NoteForm";
import AttachmentForm from "./AttachmentForm";

interface DailyLogPanelProps {
  labor_entries: LaborEntry[];
  equipment_entries: EquipmentEntry[];
  operational_notes: OperationalNote[];
  attachments: IncidentAttachment[];
  can_manage_labor: boolean;
  can_manage_equipment: boolean;
  can_create_notes: boolean;
  labor_entries_path: string;
  equipment_entries_path: string;
  operational_notes_path: string;
  attachments_path: string;
  assignable_labor_users: AssignableUser[];
  equipment_types: EquipmentType[];
}

function collectDates(
  labor: LaborEntry[],
  equipment: EquipmentEntry[],
  notes: OperationalNote[],
  attachments: IncidentAttachment[],
): string[] {
  const dateSet = new Set<string>();
  labor.forEach((e) => dateSet.add(e.log_date));
  equipment.forEach((_e) => {
    // Equipment entries use placed_at/removed_at timestamps, not log_date.
    // Shown in all date views.
  });
  notes.forEach((e) => dateSet.add(e.log_date));
  attachments.forEach((e) => { if (e.log_date) dateSet.add(e.log_date); });
  return Array.from(dateSet).sort().reverse();
}

export default function DailyLogPanel({
  labor_entries, equipment_entries, operational_notes, attachments,
  can_manage_labor, can_manage_equipment, can_create_notes,
  labor_entries_path, equipment_entries_path, operational_notes_path, attachments_path,
  assignable_labor_users, equipment_types,
}: DailyLogPanelProps) {
  const dates = collectDates(labor_entries, equipment_entries, operational_notes, attachments);
  const [selectedDate, setSelectedDate] = useState<string | null>(dates[0] ?? null);
  const [laborForm, setLaborForm] = useState<{ open: boolean; entry?: LaborEntry }>({ open: false });
  const [equipmentForm, setEquipmentForm] = useState<{ open: boolean; entry?: EquipmentEntry }>({ open: false });
  const [showNoteForm, setShowNoteForm] = useState(false);
  const [showAttachmentForm, setShowAttachmentForm] = useState(false);

  const hasNoActivity = labor_entries.length === 0 && equipment_entries.length === 0
    && operational_notes.length === 0 && attachments.length === 0;

  if (hasNoActivity && !can_manage_labor && !can_manage_equipment && !can_create_notes) {
    return (
      <div className="flex-1 flex items-center justify-center text-muted-foreground text-sm py-12">
        No activity recorded yet.
      </div>
    );
  }

  // Filter entries by selected date
  const filteredLabor = selectedDate
    ? labor_entries.filter((e) => e.log_date === selectedDate)
    : labor_entries;
  const filteredNotes = selectedDate
    ? operational_notes.filter((e) => e.log_date === selectedDate)
    : operational_notes;
  const filteredAttachments = selectedDate
    ? attachments.filter((e) => e.log_date === selectedDate)
    : attachments;
  // Equipment doesn't have log_date — show all when a date is selected
  const filteredEquipment = equipment_entries;

  return (
    <div className="flex flex-col h-full">
      {/* Date selector */}
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
          {dates.map((d) => {
            const label =
              labor_entries.find((e) => e.log_date === d)?.log_date_label ??
              operational_notes.find((e) => e.log_date === d)?.log_date_label ??
              attachments.find((e) => e.log_date === d)?.log_date_label ??
              d;
            return (
              <Button
                key={d}
                variant={selectedDate === d ? "default" : "ghost"}
                size="sm"
                onClick={() => setSelectedDate(d)}
                className="h-7 text-xs whitespace-nowrap"
              >
                {label}
              </Button>
            );
          })}
        </div>
      )}

      {/* Scrollable content */}
      <div className="flex-1 overflow-y-auto p-3 space-y-5">
        {/* Labor section */}
        <LogSection
          title="Labor"
          icon={<Clock className="h-4 w-4" />}
          count={filteredLabor.length}
          showAdd={can_manage_labor}
          onAdd={() => setLaborForm({ open: true })}
          addLabel="Add Labor"
        >
          {filteredLabor.map((entry) => (
            <LaborEntryRow
              key={entry.id}
              entry={entry}
              onEdit={() => setLaborForm({ open: true, entry })}
            />
          ))}
        </LogSection>

        {/* Equipment section */}
        <LogSection
          title="Equipment"
          icon={<Wrench className="h-4 w-4" />}
          count={filteredEquipment.length}
          showAdd={can_manage_equipment}
          onAdd={() => setEquipmentForm({ open: true })}
          addLabel="Add Equipment"
        >
          {filteredEquipment.map((entry) => (
            <EquipmentEntryRow
              key={entry.id}
              entry={entry}
              onEdit={() => setEquipmentForm({ open: true, entry })}
            />
          ))}
        </LogSection>

        {/* Notes section */}
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

        {/* Documents section */}
        <LogSection
          title="Documents"
          icon={<FileText className="h-4 w-4" />}
          count={filteredAttachments.length}
          showAdd={true}
          onAdd={() => setShowAttachmentForm(true)}
          addLabel="Upload"
          addIcon={<Upload className="h-3 w-3" />}
        >
          {filteredAttachments.map((att) => (
            <AttachmentRow key={att.id} attachment={att} />
          ))}
        </LogSection>
      </div>

      {/* Forms */}
      {laborForm.open && (
        <LaborForm
          path={labor_entries_path}
          users={assignable_labor_users}
          entry={laborForm.entry}
          onClose={() => setLaborForm({ open: false })}
        />
      )}
      {equipmentForm.open && (
        <EquipmentForm
          path={equipment_entries_path}
          equipment_types={equipment_types}
          entry={equipmentForm.entry}
          onClose={() => setEquipmentForm({ open: false })}
        />
      )}
      {showNoteForm && (
        <NoteForm
          path={operational_notes_path}
          onClose={() => setShowNoteForm(false)}
        />
      )}
      {showAttachmentForm && (
        <AttachmentForm
          path={attachments_path}
          onClose={() => setShowAttachmentForm(false)}
        />
      )}
    </div>
  );
}

// --- Section wrapper ---

function LogSection({
  title, icon, count, showAdd, onAdd, addLabel, addIcon, children,
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
          {count > 0 && (
            <span className="text-foreground ml-1">({count})</span>
          )}
        </div>
        {showAdd && (
          <Button variant="ghost" size="sm" className="h-7 text-xs gap-1" onClick={onAdd}>
            {addIcon ?? <Plus className="h-3 w-3" />}
            {addLabel}
          </Button>
        )}
      </div>
      {count === 0 ? (
        <p className="text-xs text-muted-foreground italic">None</p>
      ) : (
        <div className="space-y-1.5">{children}</div>
      )}
    </div>
  );
}

// --- Row components ---

function LaborEntryRow({ entry, onEdit }: { entry: LaborEntry; onEdit: () => void }) {
  return (
    <div className="group bg-muted rounded p-2.5 text-sm">
      <div className="flex items-center justify-between">
        <span className="font-medium">
          {entry.role_label}
          {entry.user_name && <span className="text-muted-foreground font-normal"> &middot; {entry.user_name}</span>}
        </span>
        <div className="flex items-center gap-1.5">
          <span className="text-xs font-medium">{entry.hours}h</span>
          {entry.edit_path && (
            <Button
              variant="ghost"
              size="sm"
              className="h-6 w-6 p-0 opacity-0 group-hover:opacity-100 transition-opacity"
              onClick={onEdit}
            >
              <Pencil className="h-3 w-3" />
            </Button>
          )}
        </div>
      </div>
      {(entry.started_at_label || entry.notes) && (
        <div className="text-xs text-muted-foreground mt-1">
          {entry.started_at_label && entry.ended_at_label && (
            <span>{entry.started_at_label} &ndash; {entry.ended_at_label}</span>
          )}
          {entry.started_at_label && entry.notes && <span> &middot; </span>}
          {entry.notes && <span>{entry.notes}</span>}
        </div>
      )}
    </div>
  );
}

function EquipmentEntryRow({ entry, onEdit }: { entry: EquipmentEntry; onEdit: () => void }) {
  return (
    <div className="group bg-muted rounded p-2.5 text-sm">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-1.5">
          {entry.active ? (
            <ArrowUp className="h-3.5 w-3.5 text-green-600" />
          ) : (
            <ArrowDown className="h-3.5 w-3.5 text-muted-foreground" />
          )}
          <span className="font-medium">{entry.type_name}</span>
          {entry.equipment_identifier && (
            <span className="text-muted-foreground text-xs">#{entry.equipment_identifier}</span>
          )}
        </div>
        <div className="flex items-center gap-1">
          {entry.edit_path && (
            <Button
              variant="ghost"
              size="sm"
              className="h-6 w-6 p-0 opacity-0 group-hover:opacity-100 transition-opacity"
              onClick={onEdit}
            >
              <Pencil className="h-3 w-3" />
            </Button>
          )}
          {entry.active && entry.remove_path && (
            <Button
              variant="ghost"
              size="sm"
              className="h-6 text-xs text-muted-foreground hover:text-destructive"
              onClick={() => router.patch(entry.remove_path!)}
            >
              Remove
            </Button>
          )}
        </div>
      </div>
      <div className="text-xs text-muted-foreground mt-1">
        {entry.active ? "Placed" : "Removed"} {entry.active ? entry.placed_at_label : entry.removed_at_label}
        {entry.location_notes && <span> &middot; {entry.location_notes}</span>}
      </div>
    </div>
  );
}

function NoteRow({ note }: { note: OperationalNote }) {
  return (
    <div className="bg-muted rounded p-2.5 text-sm">
      <p className="text-sm">{note.note_text}</p>
      <p className="text-xs text-muted-foreground mt-1">
        &mdash; {note.created_by_name} &middot; {note.created_at_label}
      </p>
    </div>
  );
}

function AttachmentRow({ attachment }: { attachment: IncidentAttachment }) {
  return (
    <Button
      variant="ghost"
      onClick={() => window.open(attachment.url, "_blank")}
      className="w-full justify-start text-left bg-muted rounded p-2.5 text-sm hover:bg-accent h-auto"
    >
      <div className="flex items-center gap-2">
        <FileText className="h-4 w-4 text-muted-foreground shrink-0" />
        <div className="min-w-0">
          <p className="font-medium truncate">{attachment.filename}</p>
          <p className="text-xs text-muted-foreground">
            {attachment.category_label}
            {attachment.description && <span> &middot; {attachment.description}</span>}
            <span> &middot; {attachment.uploaded_by_name}</span>
          </p>
        </div>
      </div>
    </Button>
  );
}
