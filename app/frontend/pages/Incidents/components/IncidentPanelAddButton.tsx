import { Plus } from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

interface IncidentPanelAddButtonProps {
  label: string;
  onClick: () => void;
  className?: string;
}

export default function IncidentPanelAddButton({ label, onClick, className }: IncidentPanelAddButtonProps) {
  return (
    <Button
      variant="outline"
      size="sm"
      className={cn("h-10 sm:h-8 text-sm sm:text-xs gap-1.5 whitespace-nowrap", className)}
      onClick={onClick}
    >
      <Plus className="h-3 w-3" />
      {label}
    </Button>
  );
}
