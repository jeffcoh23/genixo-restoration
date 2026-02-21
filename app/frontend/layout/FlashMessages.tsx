import { useEffect, useState } from "react";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { CheckCircle, AlertCircle, X } from "lucide-react";

interface FlashMessagesProps {
  flash: {
    notice?: string;
    alert?: string;
  };
}

export default function FlashMessages({ flash }: FlashMessagesProps) {
  const [hiddenKey, setHiddenKey] = useState("");
  const flashKey = `${flash.notice || ""}|${flash.alert || ""}`;
  const hasFlash = !!(flash.notice || flash.alert);
  const visible = hasFlash && flashKey !== hiddenKey;

  useEffect(() => {
    if (!visible) return;
    const timer = setTimeout(() => setHiddenKey(flashKey), 5000);
    return () => clearTimeout(timer);
  }, [flashKey, visible]);

  if (!visible) return null;

  const dismiss = () => setHiddenKey(flashKey);

  return (
    <div className="fixed top-4 left-1/2 -translate-x-1/2 z-[60] w-full max-w-md px-4">
      {flash.notice && (
        <Alert className="border-l-4 border-l-status-success bg-status-success/10 shadow-lg">
          <div className="flex items-start gap-3">
            <CheckCircle className="h-5 w-5 text-status-success shrink-0 mt-0.5" />
            <AlertDescription className="flex-1 text-sm text-foreground">{flash.notice}</AlertDescription>
            <button onClick={dismiss} className="shrink-0 text-muted-foreground hover:text-foreground transition-colors">
              <X className="h-4 w-4" />
            </button>
          </div>
        </Alert>
      )}
      {flash.alert && (
        <Alert variant="destructive" className="border-l-4 border-l-destructive bg-destructive/10 shadow-lg">
          <div className="flex items-start gap-3">
            <AlertCircle className="h-5 w-5 text-destructive shrink-0 mt-0.5" />
            <AlertDescription className="flex-1 text-sm">{flash.alert}</AlertDescription>
            <button onClick={dismiss} className="shrink-0 text-muted-foreground hover:text-foreground transition-colors">
              <X className="h-4 w-4" />
            </button>
          </div>
        </Alert>
      )}
    </div>
  );
}
