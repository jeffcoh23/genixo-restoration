import { useState, useRef, useEffect, useId } from "react";
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
  const triggerRef = useRef<HTMLButtonElement>(null);
  const optionRefs = useRef<Array<HTMLButtonElement | null>>([]);
  const listboxId = useId();

  useEffect(() => {
    if (!open) return;
    const handleClick = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener("mousedown", handleClick);
    return () => document.removeEventListener("mousedown", handleClick);
  }, [open]);

  useEffect(() => {
    if (!open) return;
    optionRefs.current[0]?.focus();
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

  const focusOption = (index: number) => {
    const count = options.length + 1;
    if (count === 0) return;
    const next = ((index % count) + count) % count;
    optionRefs.current[next]?.focus();
  };

  const handleTriggerKeyDown = (e: React.KeyboardEvent<HTMLButtonElement>) => {
    if (e.key === "ArrowDown" || e.key === "Enter" || e.key === " ") {
      e.preventDefault();
      setOpen(true);
    }
  };

  const handleListKeyDown = (e: React.KeyboardEvent<HTMLDivElement>) => {
    if (e.key === "Escape") {
      e.preventDefault();
      setOpen(false);
      triggerRef.current?.focus();
      return;
    }

    if (!["ArrowDown", "ArrowUp", "Home", "End"].includes(e.key)) return;
    e.preventDefault();

    const activeIndex = optionRefs.current.findIndex((el) => el === document.activeElement);
    if (e.key === "Home") {
      focusOption(0);
      return;
    }
    if (e.key === "End") {
      focusOption(options.length);
      return;
    }
    if (e.key === "ArrowDown") {
      focusOption(activeIndex + 1);
      return;
    }
    focusOption(activeIndex - 1);
  };

  const closeAndRestoreFocus = () => {
    setOpen(false);
    requestAnimationFrame(() => triggerRef.current?.focus());
  };

  return (
    <div className="relative" ref={ref}>
      <Button
        ref={triggerRef}
        variant="outline"
        size="sm"
        onClick={() => setOpen(!open)}
        onKeyDown={handleTriggerKeyDown}
        aria-expanded={open}
        aria-haspopup="listbox"
        aria-controls={listboxId}
        className={`h-11 sm:h-8 px-2.5 text-sm flex items-center gap-1.5 ${
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
          id={listboxId}
          role="listbox"
          aria-multiselectable="true"
          tabIndex={-1}
          onKeyDown={handleListKeyDown}
          className="absolute top-full left-0 mt-1 z-50 bg-popover border border-border rounded-md shadow-md min-w-[220px] py-1 max-h-[320px] overflow-y-auto"
        >
          {/* "All" option — resets this filter */}
          <Button
            ref={(el) => { optionRefs.current[0] = el; }}
            variant="ghost"
            size="sm"
            role="option"
            aria-selected={!hasSelection}
            onClick={() => { onChange([]); closeAndRestoreFocus(); }}
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

          {options.map((opt, index) => {
            const isSelected = selected.includes(opt.value);
            return (
              <Button
                key={opt.value}
                ref={(el) => { optionRefs.current[index + 1] = el; }}
                variant="ghost"
                role="option"
                aria-selected={isSelected}
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
