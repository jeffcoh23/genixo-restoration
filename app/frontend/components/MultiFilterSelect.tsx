import { useState, useRef, useEffect, useCallback } from "react";
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
  const [focusIndex, setFocusIndex] = useState(-1);
  const ref = useRef<HTMLDivElement>(null);
  const listRef = useRef<HTMLDivElement>(null);

  // Close on outside click
  useEffect(() => {
    if (!open) return;
    const handleClick = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener("mousedown", handleClick);
    return () => document.removeEventListener("mousedown", handleClick);
  }, [open]);

  const totalItems = options.length + 1; // +1 for "All" option

  const toggle = useCallback((value: string) => {
    const next = selected.includes(value)
      ? selected.filter((v) => v !== value)
      : [...selected, value];
    onChange(next);
  }, [selected, onChange]);

  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (!open) {
      if (e.key === "Enter" || e.key === " " || e.key === "ArrowDown") {
        e.preventDefault();
        setOpen(true);
        setFocusIndex(0);
      }
      return;
    }

    switch (e.key) {
      case "Escape":
        e.preventDefault();
        setOpen(false);
        break;
      case "ArrowDown":
        e.preventDefault();
        setFocusIndex((prev) => (prev + 1) % totalItems);
        break;
      case "ArrowUp":
        e.preventDefault();
        setFocusIndex((prev) => (prev - 1 + totalItems) % totalItems);
        break;
      case "Enter":
      case " ":
        e.preventDefault();
        if (focusIndex === 0) {
          onChange([]);
          setOpen(false);
        } else if (focusIndex > 0) {
          const opt = options[focusIndex - 1];
          toggle(opt.value);
        }
        break;
    }
  }, [open, focusIndex, totalItems, options, onChange, toggle]);

  // Scroll focused item into view
  useEffect(() => {
    if (!open || focusIndex < 0 || !listRef.current) return;
    const items = listRef.current.querySelectorAll("[data-filter-item]");
    items[focusIndex]?.scrollIntoView({ block: "nearest" });
  }, [focusIndex, open]);

  const hasSelection = selected.length > 0;
  const triggerText = hasSelection
    ? selected.map((v) => options.find((o) => o.value === v)?.label).filter(Boolean).join(", ")
    : allLabel;

  return (
    <div className="relative" ref={ref} onKeyDown={handleKeyDown}>
      <Button
        variant="outline"
        size="sm"
        onClick={() => { setOpen(!open); setFocusIndex(-1); }}
        aria-expanded={open}
        aria-haspopup="listbox"
        className={`h-10 sm:h-8 px-2.5 text-sm sm:text-xs flex items-center gap-1.5 ${
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
        <div
          ref={listRef}
          role="listbox"
          aria-multiselectable="true"
          className="absolute top-full left-0 mt-1 z-50 bg-popover border border-border rounded-md shadow-md min-w-[220px] py-1 max-h-[320px] overflow-y-auto"
        >
          {/* "All" option — resets this filter */}
          <Button
            variant="ghost"
            data-filter-item
            role="option"
            aria-selected={!hasSelection}
            onClick={() => { onChange([]); setOpen(false); }}
            className={`w-full flex items-center gap-2.5 px-3 py-2.5 sm:py-2 text-sm justify-start rounded-none h-auto ${
              focusIndex === 0 ? "bg-accent" : ""
            } ${!hasSelection ? "text-foreground font-medium" : "text-muted-foreground"}`}
          >
            <span className={`h-4 w-4 rounded border flex items-center justify-center flex-shrink-0 ${
              !hasSelection ? "bg-primary border-primary text-primary-foreground" : "border-input"
            }`}>
              {!hasSelection && <Check className="h-3 w-3" />}
            </span>
            {allLabel}
          </Button>

          <div className="border-t border-border my-1" />

          {options.map((opt, i) => {
            const isSelected = selected.includes(opt.value);
            return (
              <Button
                key={opt.value}
                variant="ghost"
                data-filter-item
                role="option"
                aria-selected={isSelected}
                onClick={() => toggle(opt.value)}
                className={`w-full flex items-center gap-2.5 px-3 py-2.5 sm:py-2 text-sm justify-start rounded-none h-auto ${
                  focusIndex === i + 1 ? "bg-accent" : ""
                }`}
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
