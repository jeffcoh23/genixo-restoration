export function statusColor(status: string): string {
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
