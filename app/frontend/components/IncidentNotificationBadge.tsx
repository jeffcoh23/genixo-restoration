import { Activity, MessageSquare } from "lucide-react";
import { cn } from "@/lib/utils";

type IncidentNotificationBadgeKind = "messages" | "activity";

interface IncidentNotificationBadgeProps {
  kind: IncidentNotificationBadgeKind;
  count: number;
  className?: string;
}

export default function IncidentNotificationBadge({ kind, count, className }: IncidentNotificationBadgeProps) {
  if (count <= 0) return null;

  const isMessages = kind === "messages";

  return (
    <span
      className={cn(
        "inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-medium",
        isMessages
          ? "bg-accent text-accent-foreground"
          : "border border-status-warning/25 bg-status-warning/15 text-foreground",
        className
      )}
    >
      {isMessages ? <MessageSquare className="h-3 w-3" /> : <Activity className="h-3 w-3" />}
      {isMessages ? `Msgs ${count}` : `Activity ${count}`}
    </span>
  );
}
