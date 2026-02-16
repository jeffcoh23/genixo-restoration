import { Link, router, usePage } from "@inertiajs/react";
import { useState } from "react";
import { AlertTriangle, ChevronDown, Clock, User as UserIcon } from "lucide-react";
import AppLayout from "@/layout/AppLayout";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { SharedProps } from "@/types";
import OverviewPanel from "./components/OverviewPanel";
import RightPanelShell from "./components/RightPanelShell";
import MessagePanel from "./components/MessagePanel";
import DailyLogPanel from "./components/DailyLogPanel";
import DocumentPanel from "./components/DocumentPanel";
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
    incident, messages, labor_entries, equipment_entries, operational_notes, attachments,
    can_transition, can_assign, can_manage_contacts, can_manage_labor, can_manage_equipment,
    can_create_notes, assignable_users, assignable_labor_users, equipment_types, back_path,
  } = usePage<SharedProps & ShowProps>().props;

  const [statusOpen, setStatusOpen] = useState(false);
  const [transitioning, setTransitioning] = useState(false);
  const [activeTab, setActiveTab] = useState("messages");

  const handleTransition = (newStatus: string) => {
    setTransitioning(true);
    setStatusOpen(false);
    router.patch(incident.transition_path, { status: newStatus }, {
      onFinish: () => setTransitioning(false),
    });
  };

  return (
    <AppLayout>
      {/* Back link */}
      <div className="mb-4">
        <Link href={back_path} className="text-sm text-muted-foreground hover:text-foreground">
          &larr; Incidents
        </Link>
      </div>

      {/* Sticky header */}
      <div className="sticky top-0 z-10 bg-background pb-4 border-b border-border mb-6">
        {/* Property */}
        <div className="flex items-center gap-2 text-sm text-muted-foreground mb-1">
          <Link href={incident.property.path} className="hover:text-foreground hover:underline">
            {incident.property.name}
          </Link>
          {incident.property.address && (
            <>
              <span>&middot;</span>
              <span>{incident.property.address}</span>
            </>
          )}
        </div>

        {/* Status + badges row */}
        <div className="flex flex-wrap items-center gap-3 mb-2">
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
                <div className="fixed inset-0 z-10" onClick={() => setStatusOpen(false)} />
                <div className="absolute left-0 top-full mt-1 z-20 bg-popover border border-border rounded shadow-md py-1 min-w-[180px]">
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
        </div>

        {/* Meta row */}
        <div className="flex flex-wrap items-center gap-4 text-sm text-muted-foreground">
          {incident.created_by && (
            <span className="flex items-center gap-1">
              <UserIcon className="h-3.5 w-3.5" />
              {incident.created_by}
            </span>
          )}
          <span className="flex items-center gap-1">
            <Clock className="h-3.5 w-3.5" />
            {incident.created_at_label}
          </span>

          {incident.assigned_summary.count > 0 && (
            <div className="flex items-center gap-1">
              <div className="flex -space-x-1.5">
                {incident.assigned_summary.avatars.map((u) => (
                  <div
                    key={u.id}
                    title={u.full_name}
                    className="h-6 w-6 rounded-full bg-muted border-2 border-background flex items-center justify-center text-xs font-medium text-muted-foreground"
                  >
                    {u.initials}
                  </div>
                ))}
              </div>
              {incident.assigned_summary.overflow > 0 && (
                <span className="text-xs text-muted-foreground ml-1">
                  +{incident.assigned_summary.overflow}
                </span>
              )}
              <span className="text-xs ml-1">{incident.assigned_summary.count} assigned</span>
            </div>
          )}
        </div>
      </div>

      {/* Split panel layout */}
      <div className="flex flex-col lg:flex-row gap-6 min-h-[calc(100vh-280px)]">
        <OverviewPanel
          incident={incident}
          can_assign={can_assign}
          can_manage_contacts={can_manage_contacts}
          assignable_users={assignable_users}
        />

        <div className="lg:w-[35%] lg:min-w-[35%] lg:border-l lg:border-border lg:pl-6">
          <RightPanelShell activeTab={activeTab} onTabChange={setActiveTab}>
            {activeTab === "messages" && (
              <MessagePanel
                messages={messages}
                messages_path={incident.messages_path}
              />
            )}
            {activeTab === "daily_log" && (
              <DailyLogPanel
                labor_entries={labor_entries}
                equipment_entries={equipment_entries}
                operational_notes={operational_notes}
                attachments={attachments}
                can_manage_labor={can_manage_labor}
                can_manage_equipment={can_manage_equipment}
                can_create_notes={can_create_notes}
                labor_entries_path={incident.labor_entries_path}
                equipment_entries_path={incident.equipment_entries_path}
                operational_notes_path={incident.operational_notes_path}
                attachments_path={incident.attachments_path}
                assignable_labor_users={assignable_labor_users}
                equipment_types={equipment_types}
              />
            )}
            {activeTab === "documents" && (
              <DocumentPanel
                attachments={attachments}
                attachments_path={incident.attachments_path}
              />
            )}
          </RightPanelShell>
        </div>
      </div>
    </AppLayout>
  );
}
