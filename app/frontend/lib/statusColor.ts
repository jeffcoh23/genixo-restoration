export function statusColor(status: string): string {
  switch (status) {
    case "new":
    case "acknowledged":
      return "bg-status-info text-black";
    case "proposal_requested":
    case "proposal_submitted":
    case "proposal_signed":
      return "bg-status-quote text-white";
    case "active":
      return "bg-status-success text-white";
    case "job_started":
      return "bg-status-success text-white";
    case "on_hold":
      return "bg-status-warning text-black";
    case "completed":
      return "bg-status-completed text-white";
    case "emergency":
      return "bg-status-emergency text-white";
    default:
      return "bg-status-neutral text-black";
  }
}
