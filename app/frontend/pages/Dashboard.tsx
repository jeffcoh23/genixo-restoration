import { Link, usePage } from "@inertiajs/react";
import { ChevronDown, ChevronRight } from "lucide-react";
import { useState } from "react";
import AppLayout from "@/layout/AppLayout";
import PageHeader from "@/components/PageHeader";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { SharedProps } from "@/types";

interface IncidentCard {
  id: number;
  path: string;
  property_name: string;
  organization_name: string;
  description: string;
  status: string;
  status_label: string;
  project_type_label: string;
  damage_label: string;
  emergency: boolean;
  last_activity_label: string | null;
}

interface Groups {
  emergency: IncidentCard[];
  active: IncidentCard[];
  needs_attention: IncidentCard[];
  on_hold: IncidentCard[];
  recent_completed: IncidentCard[];
}

interface DashboardProps {
  groups: Groups;
  total_count: number;
  can_create_incident: boolean;
}

const GROUP_CONFIG = [
  { key: "emergency" as const, label: "Emergency", defaultOpen: true },
  { key: "active" as const, label: "Active", defaultOpen: true },
  { key: "needs_attention" as const, label: "Needs Attention", defaultOpen: true },
  { key: "on_hold" as const, label: "On Hold", defaultOpen: true },
  { key: "recent_completed" as const, label: "Recent Completed", defaultOpen: false },
];

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

export default function Dashboard() {
  const { groups, total_count, can_create_incident, routes } =
    usePage<SharedProps & DashboardProps>().props;

  return (
    <AppLayout>
      <PageHeader
        title="Dashboard"
        action={can_create_incident ? { href: routes.new_incident, label: "Create Request" } : undefined}
      />

      {total_count === 0 ? (
        <div className="rounded border border-border bg-card p-8 text-center">
          <p className="text-muted-foreground">No incidents to show.</p>
          {can_create_incident && (
            <p className="mt-2 text-sm text-muted-foreground">
              <Link href={routes.new_incident} className="text-primary hover:underline">Create your first incident</Link> to get started.
            </p>
          )}
        </div>
      ) : (
        <div className="space-y-4">
          {GROUP_CONFIG.map(({ key, label, defaultOpen }) => (
            <IncidentGroup
              key={key}
              label={label}
              incidents={groups[key]}
              defaultOpen={defaultOpen}
            />
          ))}
        </div>
      )}
    </AppLayout>
  );
}

function IncidentGroup({
  label,
  incidents,
  defaultOpen,
}: {
  label: string;
  incidents: IncidentCard[];
  defaultOpen: boolean;
}) {
  const [open, setOpen] = useState(defaultOpen && incidents.length > 0);

  if (incidents.length === 0) return null;

  return (
    <div>
      <Button
        variant="ghost"
        size="sm"
        onClick={() => setOpen(!open)}
        className="flex items-center gap-2 text-sm font-semibold text-muted-foreground uppercase tracking-wide mb-2 hover:text-foreground h-auto p-0"
      >
        {open ? <ChevronDown className="h-4 w-4" /> : <ChevronRight className="h-4 w-4" />}
        {label} ({incidents.length})
      </Button>

      {open && (
        <div className="rounded border border-border overflow-hidden divide-y divide-border">
          {incidents.map((incident) => (
            <Link
              key={incident.id}
              href={incident.path}
              className="block px-4 py-3 hover:bg-muted transition-colors bg-card"
            >
              <div className="flex items-start justify-between gap-3">
                <div className="min-w-0 flex-1">
                  <span className="font-medium text-foreground truncate block">
                    {incident.property_name}
                  </span>
                  <span className="text-xs text-muted-foreground">{incident.organization_name}</span>
                  <p className="text-sm text-muted-foreground truncate mt-0.5">{incident.description}</p>
                  <div className="flex items-center gap-2 mt-1.5 text-xs text-muted-foreground">
                    <span>{incident.damage_label}</span>
                    <span>&middot;</span>
                    <span>{incident.project_type_label}</span>
                    {incident.last_activity_label && (
                      <>
                        <span>&middot;</span>
                        <span>{incident.last_activity_label}</span>
                      </>
                    )}
                  </div>
                </div>
                <Badge className={`text-xs flex-shrink-0 ${statusColor(incident.status)}`}>
                  {incident.status_label}
                </Badge>
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
