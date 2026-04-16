import { useState } from "react";
import { FileDown } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";

const SECTIONS = [
  { id: "labor", label: "Labor" },
  { id: "equipment", label: "Equipment" },
  { id: "moisture", label: "Moisture Readings" },
  { id: "psychrometric", label: "Psychrometric Readings" },
] as const;

type SectionId = typeof SECTIONS[number]["id"];

interface ReportPanelProps {
  reportPath: string;
}

export default function ReportPanel({ reportPath }: ReportPanelProps) {
  const [selected, setSelected] = useState<Set<SectionId>>(new Set());

  const toggle = (id: SectionId) => {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const handleGenerate = () => {
    if (selected.size === 0) return;
    const params = new URLSearchParams();
    selected.forEach((id) => params.append("sections[]", id));
    window.open(`${reportPath}?${params.toString()}`, "_blank");
  };

  return (
    <div className="rounded-lg border border-border bg-muted/20 px-3 py-2.5">
      <h3 className="text-xs font-semibold uppercase tracking-wide text-muted-foreground mb-2">Generate Report</h3>
      <div className="space-y-1.5 mb-3">
        {SECTIONS.map((section) => (
          <label key={section.id} className="flex items-center gap-2 cursor-pointer">
            <Checkbox
              checked={selected.has(section.id)}
              onCheckedChange={() => toggle(section.id)}
            />
            <span className="text-sm text-foreground">{section.label}</span>
          </label>
        ))}
      </div>
      <Button
        size="sm"
        variant="outline"
        className="w-full gap-1.5 text-xs"
        disabled={selected.size === 0}
        onClick={handleGenerate}
      >
        <FileDown className="h-3.5 w-3.5" />
        Download PDF
      </Button>
    </div>
  );
}
