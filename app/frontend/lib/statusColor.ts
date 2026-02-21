export function statusColor(status: string): string {
  switch (status) {
    case "new":
    case "acknowledged":
      return "bg-status-info text-status-info-foreground";
    case "proposal_requested":
    case "proposal_submitted":
    case "proposal_signed":
      return "bg-status-quote text-status-quote-foreground";
    case "active":
    case "job_started":
      return "bg-status-success text-status-success-foreground";
    case "on_hold":
      return "bg-status-warning text-status-warning-foreground";
    case "completed":
      return "bg-status-completed text-status-completed-foreground";
    default:
      return "bg-status-neutral text-status-neutral-foreground";
  }
}
