import { useState, useRef, useEffect } from "react";
import { ChevronDown, Check } from "lucide-react";

interface MultiFilterSelectProps {
  selected: string[];
  onChange: (values: string[]) => void;
  allLabel: string;
  options: { value: string; label: string }[];
}

export default function MultiFilterSelect({
  selected,
  onChange,
  allLabel,
  options,
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
      <button
        type="button"
        onClick={() => setOpen(!open)}
        className={`h-8 rounded-md border px-2.5 text-sm flex items-center gap-1.5 max-w-[200px] focus:outline-none focus:ring-1 focus:ring-ring transition-colors ${
          hasSelection
            ? "bg-accent border-accent text-accent-foreground"
            : "bg-background border-input text-muted-foreground"
        }`}
      >
        <span className="truncate">{triggerText}</span>
        <ChevronDown className="h-3.5 w-3.5 flex-shrink-0 opacity-50" />
      </button>

      {open && (
        <div className="absolute top-full left-0 mt-1 z-50 bg-popover border border-border rounded-md shadow-md min-w-[220px] py-1 max-h-[320px] overflow-y-auto">
          {/* "All" option — resets this filter */}
          <button
            type="button"
            onClick={() => { onChange([]); setOpen(false); }}
            className={`w-full flex items-center gap-2.5 px-3 py-2 text-sm hover:bg-muted/50 text-left transition-colors ${
              !hasSelection ? "text-foreground font-medium" : "text-muted-foreground"
            }`}
          >
            <span className={`h-4 w-4 rounded border flex items-center justify-center flex-shrink-0 ${
              !hasSelection ? "bg-primary border-primary text-primary-foreground" : "border-input"
            }`}>
              {!hasSelection && <Check className="h-3 w-3" />}
            </span>
            {allLabel}
          </button>

          <div className="border-t border-border my-1" />

          {options.map((opt) => {
            const isSelected = selected.includes(opt.value);
            return (
              <button
                key={opt.value}
                type="button"
                onClick={() => toggle(opt.value)}
                className="w-full flex items-center gap-2.5 px-3 py-2 text-sm hover:bg-muted/50 text-left transition-colors"
              >
                <span className={`h-4 w-4 rounded border flex items-center justify-center flex-shrink-0 transition-colors ${
                  isSelected ? "bg-primary border-primary text-primary-foreground" : "border-input"
                }`}>
                  {isSelected && <Check className="h-3 w-3" />}
                </span>
                {opt.label}
              </button>
            );
          })}
        </div>
      )}
    </div>
  );
}
