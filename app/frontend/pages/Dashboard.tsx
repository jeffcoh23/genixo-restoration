import { Link, usePage } from "@inertiajs/react";
import { ChevronDown, ChevronRight, AlertTriangle } from "lucide-react";
import { useState } from "react";
import AppLayout from "@/layout/AppLayout";
import PageHeader from "@/components/PageHeader";
import { Badge } from "@/components/ui/badge";
import { SharedProps } from "@/types";

interface IncidentCard {
  id: number;
  path: string;
  property_name: string;
  description: string;
  status: string;
  status_label: string;
  project_type_label: string;
  damage_label: string;
  emergency: boolean;
  last_activity_at: string | null;
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
  can_create_incident: boolean;
}

const GROUP_CONFIG = [
  { key: "emergency" as const, label: "Emergency", defaultOpen: true },
  { key: "active" as const, label: "Active", defaultOpen: true },
  { key: "needs_attention" as const, label: "Needs Attention", defaultOpen: true },
  { key: "on_hold" as const, label: "On Hold", defaultOpen: true },
  { key: "recent_completed" as const, label: "Recent Completed", defaultOpen: false },
];

function timeAgo(iso: string | null): string {
  if (!iso) return "";
  const seconds = Math.floor((Date.now() - new Date(iso).getTime()) / 1000);
  if (seconds < 60) return "just now";
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  return `${days}d ago`;
}

function statusColor(status: string): string {
  switch (status) {
    case "new":
    case "acknowledged":
      return "bg-[hsl(199_89%_48%)] text-white";
    case "quote_requested":
      return "bg-[hsl(270_50%_60%)] text-white";
    case "active":
      return "bg-[hsl(142_76%_36%)] text-white";
    case "on_hold":
      return "bg-[hsl(38_92%_50%)] text-white";
    case "completed":
      return "bg-[hsl(142_40%_50%)] text-white";
    default:
      return "bg-[hsl(0_0%_55%)] text-white";
  }
}

export default function Dashboard() {
  const { groups, can_create_incident, routes } =
    usePage<SharedProps & DashboardProps>().props;

  const totalCount = Object.values(groups).reduce((sum, g) => sum + g.length, 0);

  return (
    <AppLayout>
      <PageHeader
        title="Dashboard"
        action={can_create_incident ? { href: routes.new_incident, label: "Create Request" } : undefined}
      />

      {totalCount === 0 ? (
        <div className="rounded-md border border-border bg-card p-8 text-center">
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
      <button
        onClick={() => setOpen(!open)}
        className="flex items-center gap-2 text-sm font-semibold text-muted-foreground uppercase tracking-wide mb-2 hover:text-foreground transition-colors"
      >
        {open ? <ChevronDown className="h-4 w-4" /> : <ChevronRight className="h-4 w-4" />}
        {label} ({incidents.length})
      </button>

      {open && (
        <div className="rounded-md border border-border overflow-hidden divide-y divide-border">
          {incidents.map((incident) => (
            <Link
              key={incident.id}
              href={incident.path}
              className={`block px-4 py-3 hover:bg-muted/50 transition-colors ${
                incident.emergency ? "bg-red-50" : "bg-card"
              }`}
            >
              <div className="flex items-start justify-between gap-3">
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    {incident.emergency && (
                      <AlertTriangle className="h-4 w-4 text-destructive flex-shrink-0" />
                    )}
                    <span className="font-medium text-foreground truncate">
                      {incident.property_name}
                    </span>
                  </div>
                  <p className="text-sm text-muted-foreground truncate">{incident.description}</p>
                  <div className="flex items-center gap-2 mt-1.5 text-xs text-muted-foreground">
                    <span>{incident.damage_label}</span>
                    <span>&middot;</span>
                    <span>{incident.project_type_label}</span>
                    {incident.last_activity_at && (
                      <>
                        <span>&middot;</span>
                        <span>{timeAgo(incident.last_activity_at)}</span>
                      </>
                    )}
                  </div>
                </div>
                <div className="flex items-center gap-2 flex-shrink-0">
                  {incident.emergency && (
                    <Badge className="bg-destructive text-destructive-foreground text-xs">
                      Emergency
                    </Badge>
                  )}
                  <Badge className={`text-xs ${statusColor(incident.status)}`}>
                    {incident.status_label}
                  </Badge>
                </div>
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
