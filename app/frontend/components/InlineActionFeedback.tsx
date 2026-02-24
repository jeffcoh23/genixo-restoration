import { AlertCircle, CheckCircle, X } from "lucide-react";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

interface InlineActionFeedbackProps {
  error?: string | null;
  notice?: string | null;
  onDismiss?: () => void;
  className?: string;
}

export default function InlineActionFeedback({ error, notice, onDismiss, className }: InlineActionFeedbackProps) {
  if (!error && !notice) return null;

  if (error) {
    return (
      <Alert variant="destructive" className={cn("border-l-4 border-l-destructive border-destructive/45 bg-card py-2.5", className)}>
        <div className="flex items-start gap-2.5">
          <AlertCircle className="h-4 w-4 text-destructive shrink-0 mt-0.5" />
          <AlertDescription className="flex-1 text-sm">{error}</AlertDescription>
          {onDismiss && (
            <Button type="button" variant="ghost" size="sm" className="h-6 w-6 p-0 shrink-0" onClick={onDismiss}>
              <X className="h-4 w-4" />
            </Button>
          )}
        </div>
      </Alert>
    );
  }

  return (
    <Alert className={cn("border-l-4 border-l-status-success border-status-success/35 bg-card py-2.5", className)}>
      <div className="flex items-start gap-2.5">
        <CheckCircle className="h-4 w-4 text-status-success shrink-0 mt-0.5" />
        <AlertDescription className="flex-1 text-sm text-foreground">{notice}</AlertDescription>
        {onDismiss && (
          <Button type="button" variant="ghost" size="sm" className="h-6 w-6 p-0 shrink-0" onClick={onDismiss}>
            <X className="h-4 w-4" />
          </Button>
        )}
      </div>
    </Alert>
  );
}
