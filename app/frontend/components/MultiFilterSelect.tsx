import { useState, useRef, useEffect } from "react";
import { ChevronDown, Check } from "lucide-react";
import { Button } from "@/components/ui/button";

interface MultiFilterSelectProps {
  selected: string[];
  onChange: (values: string[]) => void;
  allLabel: string;
  options: { value: string; label: string }[];
  width?: string;
}

export default function MultiFilterSelect({
  selected,
  onChange,
  allLabel,
  options,
  width,
}: MultiFilterSelectProps) {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    const handleClick = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener("mousedown", handleClick);
    return () => document.removeEventListener("mousedown", handleClick);
  }, [open]);

  const toggle = (value: string) => {
    const next = selected.includes(value)
      ? selected.filter((v) => v !== value)
      : [...selected, value];
    onChange(next);
  };

  const hasSelection = selected.length > 0;
  const triggerText = hasSelection
    ? selected.map((v) => options.find((o) => o.value === v)?.label).filter(Boolean).join(", ")
    : allLabel;

  return (
    <div className="relative" ref={ref}>
      <Button
        variant="outline"
        size="sm"
        onClick={() => setOpen(!open)}
        className={`h-8 px-2.5 text-sm flex items-center gap-1.5 ${
          hasSelection
            ? "bg-accent border-accent text-accent-foreground"
            : "text-muted-foreground"
        }`}
        style={width ? { width } : undefined}
      >
        <span className="truncate">{triggerText}</span>
        <ChevronDown className="h-3.5 w-3.5 flex-shrink-0 opacity-50" />
      </Button>

      {open && (
        <div className="absolute top-full left-0 mt-1 z-50 bg-popover border border-border rounded-md shadow-md min-w-[220px] py-1 max-h-[320px] overflow-y-auto">
          {/* "All" option — resets this filter */}
          <Button
            variant="ghost"
            size="sm"
            onClick={() => { onChange([]); setOpen(false); }}
            className={`w-full flex items-center gap-2.5 px-3 py-2 text-sm justify-start rounded-none h-auto ${
              !hasSelection ? "text-foreground font-medium" : "text-muted-foreground"
            }`}
          >
            <span className={`h-4 w-4 rounded border flex items-center justify-center flex-shrink-0 ${
              !hasSelection ? "bg-primary border-primary text-primary-foreground" : "border-input"
            }`}>
              {!hasSelection && <Check className="h-3 w-3" />}
            </span>
            {allLabel}
          </Button>

          <div className="border-t border-border my-1" />

          {options.map((opt) => {
            const isSelected = selected.includes(opt.value);
            return (
              <Button
                key={opt.value}
                variant="ghost"
                size="sm"
                onClick={() => toggle(opt.value)}
                className="w-full flex items-center gap-2.5 px-3 py-2 text-sm justify-start rounded-none h-auto"
              >
                <span className={`h-4 w-4 rounded border flex items-center justify-center flex-shrink-0 transition-colors ${
                  isSelected ? "bg-primary border-primary text-primary-foreground" : "border-input"
                }`}>
                  {isSelected && <Check className="h-3 w-3" />}
                </span>
                {opt.label}
              </Button>
            );
          })}
        </div>
      )}
    </div>
  );
}
