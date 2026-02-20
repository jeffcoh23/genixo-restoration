import { Link, router, usePage } from "@inertiajs/react";
import { useState, useCallback } from "react";
import { ChevronDown, ChevronRight, Mail, Pencil, Phone } from "lucide-react";
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
      return "bg-status-info text-white";
    case "proposal_requested":
    case "proposal_submitted":
    case "proposal_signed":
      return "bg-status-quote text-white";
    case "active":
      return "bg-status-success text-white";
    case "on_hold":
      return "bg-status-warning text-white";
    case "completed":
      return "bg-status-completed text-white";
    default:
      return "bg-status-neutral text-white";
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
    assignable_mitigation_users = [],
    assignable_pm_users = [],
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
  const [markedTabs, setMarkedTabs] = useState<Set<string>>(new Set());

  const displayUnreadMessages = markedTabs.has("messages") ? 0 : incident.unread_messages;
  const displayUnreadActivity = markedTabs.has("activity") ? 0 : incident.unread_activity;

  const handleTabChange = useCallback((tab: string) => {
    setActiveTab(tab);

    const tabToType: Record<string, string> = { messages: "messages", daily_log: "activity" };
    const readType = tabToType[tab];
    if (!readType || markedTabs.has(readType)) return;

    const hasUnread = readType === "messages" ? incident.unread_messages > 0 : incident.unread_activity > 0;
    if (!hasUnread) return;

    setMarkedTabs((prev) => new Set([...prev, readType]));

    router.patch(incident.mark_read_path, { tab: readType }, {
      async: true,
      preserveState: true,
      preserveScroll: true,
    });
  }, [incident.mark_read_path, incident.unread_messages, incident.unread_activity, markedTabs]);

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

      {/* Incident summary card */}
      <div className="bg-card rounded-lg border border-border shadow-sm mb-6">
        {/* Row 1: Identity + controls */}
        <div className="flex items-center justify-between gap-4 px-5 pt-4 pb-2">
          <div className="min-w-0 flex items-center gap-1 text-sm">
            <span className="text-muted-foreground">{incident.property.organization_name}</span>
            <ChevronRight className="h-3.5 w-3.5 text-muted-foreground shrink-0" />
            <Link href={incident.property.path} className="font-medium text-foreground hover:underline truncate">
              {incident.property.name}
            </Link>
          </div>

          <div className="flex items-center gap-2 shrink-0">
            <div className="relative">
              {can_transition && incident.valid_transitions.length > 0 ? (
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => setStatusOpen(!statusOpen)}
                  disabled={transitioning}
                  className={`inline-flex items-center gap-1.5 rounded-md px-3 py-1.5 text-sm font-medium ${statusColor(incident.status)} hover:opacity-90 transition-opacity`}
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
                  <div className="absolute right-0 top-full mt-1 z-40 bg-popover border border-border rounded-lg shadow-md py-1 min-w-[180px]">
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

        {/* Row 2: Metadata strip */}
        <div className="flex flex-wrap items-start gap-x-6 gap-y-2 px-5 pb-4">
          {(incident.property.address_line1 || incident.property.address_line2) && (
            <div>
              <div className="text-xs text-muted-foreground uppercase tracking-wide font-semibold">Location</div>
              <div className="text-sm text-foreground">
                {incident.property.address_line1 && <div>{incident.property.address_line1}</div>}
                {incident.property.address_line2 && <div>{incident.property.address_line2}</div>}
                {incident.location_of_damage && <div className="text-muted-foreground">{incident.location_of_damage}</div>}
              </div>
            </div>
          )}
          {incident.job_id && (
            <div>
              <div className="text-xs text-muted-foreground uppercase tracking-wide font-semibold">Job #</div>
              <div className="text-sm text-foreground">{incident.job_id}</div>
            </div>
          )}
          <div>
            <div className="text-xs text-muted-foreground uppercase tracking-wide font-semibold">Damage</div>
            <div className="text-sm text-foreground">{incident.damage_label}</div>
          </div>
          <div>
            <div className="text-xs text-muted-foreground uppercase tracking-wide font-semibold">Project Type</div>
            <div className="text-sm text-foreground">{incident.project_type_label}</div>
          </div>
          {incident.created_by && (
            <div>
              <div className="text-xs text-muted-foreground uppercase tracking-wide font-semibold">Reported By</div>
              <div className="flex items-center gap-1.5 text-sm">
                <span className="text-foreground">{incident.created_by.name}</span>
                <span className="text-muted-foreground">&middot; {incident.created_at_label}</span>
                <a href={`mailto:${incident.created_by.email}`} className="text-muted-foreground hover:text-foreground transition-colors" title={incident.created_by.email}>
                  <Mail className="h-3 w-3" />
                </a>
                {incident.created_by.phone && (
                  <a href={`tel:${incident.created_by.phone}`} className="text-muted-foreground hover:text-foreground transition-colors" title={incident.created_by.phone}>
                    <Phone className="h-3 w-3" />
                  </a>
                )}
              </div>
            </div>
          )}
        </div>

        {/* Description / Cause / Next Steps */}
        <div className="border-t border-border px-5 py-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-3">
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
          </div>
        </div>
      </div>

      {/* Tabbed content card */}
      <div className="bg-card rounded-lg border border-border shadow-sm h-[calc(100vh-400px)] overflow-hidden">
        <RightPanelShell activeTab={activeTab} onTabChange={handleTabChange} unreadMessages={displayUnreadMessages} unreadActivity={displayUnreadActivity}>
          {activeTab === "daily_log" && (
            <DailyLogPanel
              daily_activities={daily_activities}
              daily_log_dates={daily_log_dates}
              daily_log_table_groups={daily_log_table_groups}
              labor_entries={labor_entries}
              can_manage_activities={can_manage_activities}
              activity_entries_path={incident.activity_entries_path}
              equipment_types={equipment_types}
              attachable_equipment_entries={attachable_equipment_entries}
              dfr_path={incident.dfr_path}
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
              assignable_mitigation_users={assignable_mitigation_users}
              assignable_pm_users={assignable_pm_users}
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
