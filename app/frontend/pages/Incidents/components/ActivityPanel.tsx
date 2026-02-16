import {
  Activity,
  ArrowUpDown,
  CircleDot,
  Clock,
  FileText,
  MessageCircle,
  UserPlus,
  UserX,
  Users,
  Wrench,
} from "lucide-react";
import type { ActivityEntry } from "../types";

interface ActivityPanelProps {
  entries: ActivityEntry[];
}

export default function ActivityPanel({ entries }: ActivityPanelProps) {
  if (entries.length === 0) {
    return (
      <div className="flex-1 flex items-center justify-center text-muted-foreground text-sm py-12">
        No activity recorded yet.
      </div>
    );
  }

  return (
    <div className="h-full overflow-y-auto px-3 py-4 pb-8">
      <div className="space-y-1.5">
        {entries.map((entry) => (
          <div key={entry.id}>
            {entry.show_date_separator && <DateSeparator label={entry.date_label} />}
            <ActivityRow entry={entry} />
          </div>
        ))}
      </div>
    </div>
  );
}

function DateSeparator({ label }: { label: string }) {
  return (
    <div className="flex items-center gap-3 py-2.5">
      <div className="flex-1 border-t border-border" />
      <span className="text-xs font-medium text-muted-foreground uppercase tracking-wider select-none">
        {label}
      </span>
      <div className="flex-1 border-t border-border" />
    </div>
  );
}

function ActivityRow({ entry }: { entry: ActivityEntry }) {
  return (
    <div className="rounded border border-border bg-card shadow-sm p-2.5">
      <div className="flex items-start gap-2">
        <div className="shrink-0 mt-0.5">
          <CategoryIcon category={entry.category} />
        </div>
        <div className="min-w-0 flex-1">
          <div className="flex items-center justify-between gap-2">
            <p className="text-sm font-medium text-foreground truncate">{entry.title}</p>
            <span className="text-xs text-muted-foreground shrink-0">{entry.timestamp_label}</span>
          </div>
          <p className="text-xs text-muted-foreground mt-0.5">
            {entry.actor_name}
            {entry.actor_role_label && <span> · {entry.actor_role_label}</span>}
            {entry.actor_org_name && <span> · {entry.actor_org_name}</span>}
          </p>
          {entry.detail && (
            <p className="text-sm text-foreground whitespace-pre-wrap mt-1.5">{entry.detail}</p>
          )}
        </div>
      </div>
    </div>
  );
}

function CategoryIcon({ category }: { category: ActivityEntry["category"] }) {
  const iconClass = "h-4 w-4 text-muted-foreground";

  switch (category) {
    case "message":
      return <MessageCircle className={iconClass} />;
    case "status":
      return <ArrowUpDown className={iconClass} />;
    case "assignment":
      return <Users className={iconClass} />;
    case "labor":
      return <Clock className={iconClass} />;
    case "equipment":
      return <Wrench className={iconClass} />;
    case "document":
      return <FileText className={iconClass} />;
    case "note":
      return <Activity className={iconClass} />;
    case "contact":
      return <UserPlus className={iconClass} />;
    case "system":
      return <CircleDot className={iconClass} />;
    default:
      return <UserX className={iconClass} />;
  }
}
