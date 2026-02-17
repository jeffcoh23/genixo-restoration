import { Link, router, usePage } from "@inertiajs/react";
import { useState } from "react";
import { AlertTriangle, ChevronDown, Pencil } from "lucide-react";
import AppLayout from "@/layout/AppLayout";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { SharedProps } from "@/types";
import RightPanelShell from "./components/RightPanelShell";
import MessagePanel from "./components/MessagePanel";
import DailyLogPanel from "./components/DailyLogPanel";
import EquipmentPanel from "./components/EquipmentPanel";
import LaborPanel from "./components/LaborPanel";
import DocumentPanel from "./components/DocumentPanel";
import OverviewPanel from "./components/OverviewPanel";
import IncidentEditForm from "./components/IncidentEditForm";
import type { ShowProps } from "./types";

function statusColor(status: string): string {
  switch (status) {
    case "new":
    case "acknowledged":
      return "bg-blue-500 text-white";
    case "quote_requested":
      return "bg-purple-500 text-white";
    case "active":
      return "bg-green-600 text-white";
    case "on_hold":
      return "bg-amber-500 text-white";
    case "completed":
      return "bg-green-500 text-white";
    default:
      return "bg-gray-500 text-white";
  }
}

export default function IncidentShow() {
  const {
    incident,
    daily_activities = [],
    daily_log_dates = [],
    daily_log_table_groups = [],
    messages = [],
    equipment_log = [],
    labor_entries = [],
    labor_log = { dates: [], date_labels: [], employees: [] },
    attachments = [],
    can_transition,
    can_edit = false,
    can_assign = false,
    can_manage_contacts = false,
    can_manage_activities = false,
    can_manage_labor = false,
    can_manage_equipment = false,
    assignable_users = [],
    assignable_labor_users = [],
    equipment_types = [],
    attachable_equipment_entries = [],
    project_types = [],
    damage_types = [],
    back_path,
  } = usePage<SharedProps & ShowProps>().props;

  const [statusOpen, setStatusOpen] = useState(false);
  const [transitioning, setTransitioning] = useState(false);
  const [activeTab, setActiveTab] = useState("daily_log");
  const [editFormOpen, setEditFormOpen] = useState(false);

  const handleTransition = (newStatus: string) => {
    setTransitioning(true);
    setStatusOpen(false);
    router.patch(incident.transition_path, { status: newStatus }, {
      onFinish: () => setTransitioning(false),
    });
  };

  return (
    <AppLayout wide>
      {/* Back link */}
      <div className="mb-4">
        <Link href={back_path} className="text-sm text-muted-foreground hover:text-foreground">
          &larr; Incidents
        </Link>
      </div>

      {/* Sticky header */}
      <div className="sticky top-0 z-10 bg-background pb-4 border-b border-border mb-6">
        {/* Property name */}
        <Link href={incident.property.path} className="text-sm text-muted-foreground hover:text-foreground hover:underline">
          {incident.property.name}
        </Link>

        {/* Address + location of damage */}
        <div className="text-sm text-muted-foreground mt-0.5">
          {incident.property.address && <span>{incident.property.address}</span>}
          {incident.property.address && incident.location_of_damage && <span> &middot; </span>}
          {incident.location_of_damage && <span>{incident.location_of_damage}</span>}
        </div>

        {/* Status + type row */}
        <div className="flex flex-wrap items-center gap-3 mt-2">
          <div className="relative">
            {can_transition && incident.valid_transitions.length > 0 ? (
              <Button
                variant="ghost"
                size="sm"
                onClick={() => setStatusOpen(!statusOpen)}
                disabled={transitioning}
                className={`inline-flex items-center gap-1.5 rounded px-3 py-1.5 text-sm font-medium ${statusColor(incident.status)} hover:opacity-90 transition-opacity`}
              >
                {incident.status_label}
                <ChevronDown className="h-3.5 w-3.5" />
              </Button>
            ) : (
              <Badge className={`text-sm px-3 py-1.5 ${statusColor(incident.status)}`}>
                {incident.status_label}
              </Badge>
            )}

            {statusOpen && (
              <>
                <div className="fixed inset-0 z-30" onClick={() => setStatusOpen(false)} />
                <div className="absolute left-0 top-full mt-1 z-40 bg-popover border border-border rounded shadow-md py-1 min-w-[180px]">
                  {incident.valid_transitions.map((t) => (
                    <Button
                      key={t.value}
                      variant="ghost"
                      onClick={() => handleTransition(t.value)}
                      className="w-full justify-start px-3 py-2 text-sm hover:bg-muted rounded-none h-auto"
                    >
                      {t.label}
                    </Button>
                  ))}
                </div>
              </>
            )}
          </div>

          {incident.emergency && (
            <Badge className="bg-destructive text-destructive-foreground text-sm">
              <AlertTriangle className="h-3.5 w-3.5 mr-1" />
              Emergency
            </Badge>
          )}

          <span className="text-sm text-muted-foreground">
            {incident.damage_label} &middot; {incident.project_type_label}
          </span>

          {can_edit && incident.edit_path && (
            <Button
              variant="ghost"
              size="sm"
              className="h-7 text-xs gap-1 text-muted-foreground"
              onClick={() => setEditFormOpen(true)}
            >
              <Pencil className="h-3 w-3" />
              Edit
            </Button>
          )}
        </div>
      </div>

      {/* Incident details */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-3 mb-6">
        <div>
          <h3 className="text-xs font-semibold uppercase tracking-wide text-muted-foreground mb-1">Description</h3>
          <p className="text-sm text-foreground whitespace-pre-wrap">{incident.description}</p>
        </div>

        {incident.cause && (
          <div>
            <h3 className="text-xs font-semibold uppercase tracking-wide text-muted-foreground mb-1">Cause</h3>
            <p className="text-sm text-foreground whitespace-pre-wrap">{incident.cause}</p>
          </div>
        )}

        {incident.requested_next_steps && (
          <div>
            <h3 className="text-xs font-semibold uppercase tracking-wide text-muted-foreground mb-1">Requested Next Steps</h3>
            <p className="text-sm text-foreground whitespace-pre-wrap">{incident.requested_next_steps}</p>
          </div>
        )}

        {(incident.units_affected || incident.affected_room_numbers) && (
          <div className="flex items-center gap-2 text-sm text-muted-foreground">
            {incident.units_affected && <span>{incident.units_affected} units affected</span>}
            {incident.units_affected && incident.affected_room_numbers && <span>&middot;</span>}
            {incident.affected_room_numbers && <span>Rooms: {incident.affected_room_numbers}</span>}
          </div>
        )}

      </div>

      {/* Tabbed content — full width */}
      <div className="h-[calc(100vh-400px)] overflow-hidden">
        <RightPanelShell activeTab={activeTab} onTabChange={setActiveTab}>
          {activeTab === "daily_log" && (
            <DailyLogPanel
              daily_activities={daily_activities}
              daily_log_dates={daily_log_dates}
              daily_log_table_groups={daily_log_table_groups}
              can_manage_activities={can_manage_activities}
              activity_entries_path={incident.activity_entries_path}
              equipment_types={equipment_types}
              attachable_equipment_entries={attachable_equipment_entries}
            />
          )}
          {activeTab === "equipment" && (
            <EquipmentPanel
              equipment_log={equipment_log}
              can_manage_equipment={can_manage_equipment}
              equipment_entries_path={incident.equipment_entries_path}
              equipment_types={equipment_types}
            />
          )}
          {activeTab === "labor" && (
            <LaborPanel
              labor_log={labor_log}
              labor_entries={labor_entries}
              can_manage_labor={can_manage_labor}
              labor_entries_path={incident.labor_entries_path}
              assignable_labor_users={assignable_labor_users}
            />
          )}
          {activeTab === "messages" && (
            <MessagePanel
              messages={messages}
              messages_path={incident.messages_path}
            />
          )}
          {activeTab === "documents" && (
            <DocumentPanel
              attachments={attachments}
              attachments_path={incident.attachments_path}
            />
          )}
          {activeTab === "manage" && (
            <OverviewPanel
              incident={incident}
              can_assign={can_assign}
              can_manage_contacts={can_manage_contacts}
              assignable_users={assignable_users}
            />
          )}
        </RightPanelShell>
      </div>

      {editFormOpen && incident.edit_path && (
        <IncidentEditForm
          incident={incident}
          project_types={project_types}
          damage_types={damage_types}
          onClose={() => setEditFormOpen(false)}
        />
      )}
    </AppLayout>
  );
}
