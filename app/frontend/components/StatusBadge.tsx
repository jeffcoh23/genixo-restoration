import { Badge } from "@/components/ui/badge";
import { statusColor } from "@/lib/statusColor";

export default function StatusBadge({ status, label }: { status: string; label: string }) {
  return <Badge className={`text-xs ${statusColor(status)}`}>{label}</Badge>;
}
