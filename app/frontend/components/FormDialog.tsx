import { ReactNode } from "react";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";

type Size = "sm" | "md" | "lg" | "xl";

const sizeClasses: Record<Size, string> = {
  sm: "sm:max-w-sm",
  md: "sm:max-w-md",
  lg: "sm:max-w-2xl",
  xl: "sm:max-w-3xl",
};

interface FormDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  title: string;
  description?: ReactNode;
  size?: Size;
  onSubmit: (e: React.FormEvent) => void;
  submitLabel?: string;
  submitProcessingLabel?: string;
  cancelLabel?: string;
  processing?: boolean;
  submitDisabled?: boolean;
  children: ReactNode;
  footer?: ReactNode;
}

export default function FormDialog({
  open,
  onOpenChange,
  title,
  description,
  size = "md",
  onSubmit,
  submitLabel = "Save",
  submitProcessingLabel = "Saving...",
  cancelLabel = "Cancel",
  processing = false,
  submitDisabled = false,
  children,
  footer,
}: FormDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent
        className={cn(
          "w-[calc(100%-1rem)] sm:w-full p-0 gap-0 overflow-hidden flex flex-col max-h-[90dvh]",
          sizeClasses[size],
        )}
      >
        <DialogHeader className="px-6 pt-5 pb-4 shrink-0 text-left">
          <DialogTitle>{title}</DialogTitle>
          {description && <DialogDescription>{description}</DialogDescription>}
        </DialogHeader>

        <form onSubmit={onSubmit} className="flex flex-col flex-1 min-h-0">
          <div className="flex-1 overflow-y-auto px-6 pb-5 space-y-4">
            {children}
          </div>
          <div className="shrink-0 flex items-center justify-end gap-2 px-6 py-4 border-t border-border bg-muted/30">
            {footer ?? (
              <>
                <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>
                  {cancelLabel}
                </Button>
                <Button type="submit" disabled={processing || submitDisabled}>
                  {processing ? submitProcessingLabel : submitLabel}
                </Button>
              </>
            )}
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}
