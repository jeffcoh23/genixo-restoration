import { Badge } from "@/components/ui/badge";
import { statusColor } from "@/lib/statusColor";
import { cn } from "@/lib/utils";

export default function StatusBadge({ status, label, className }: { status: string; label: string; className?: string }) {
  return (
    <Badge className={cn("rounded-full px-2.5 py-0.5 text-xs font-medium", statusColor(status), className)}>
      {label}
    </Badge>
  );
}
