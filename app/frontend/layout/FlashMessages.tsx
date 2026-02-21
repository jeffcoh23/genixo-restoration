import { useEffect, useState } from "react";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
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
    <div className="fixed top-4 left-1/2 -translate-x-1/2 z-[60] w-full max-w-md px-4 space-y-2">
      {flash.notice && (
        <Alert className="border-l-4 border-l-status-success border-status-success/35 bg-card shadow-xl">
          <div className="flex items-start gap-3">
            <CheckCircle className="h-5 w-5 text-status-success shrink-0 mt-0.5" />
            <AlertDescription className="flex-1 text-sm text-foreground">{flash.notice}</AlertDescription>
            <Button variant="ghost" size="sm" className="h-6 w-6 p-0 shrink-0 text-muted-foreground hover:text-foreground" onClick={dismiss}>
              <X className="h-4 w-4" />
            </Button>
          </div>
        </Alert>
      )}
      {flash.alert && (
        <Alert variant="destructive" className="border-l-4 border-l-destructive border-destructive/45 bg-card shadow-xl">
          <div className="flex items-start gap-3">
            <AlertCircle className="h-5 w-5 text-destructive shrink-0 mt-0.5" />
            <AlertDescription className="flex-1 text-sm">{flash.alert}</AlertDescription>
            <Button variant="ghost" size="sm" className="h-6 w-6 p-0 shrink-0 text-muted-foreground hover:text-foreground" onClick={dismiss}>
              <X className="h-4 w-4" />
            </Button>
          </div>
        </Alert>
      )}
    </div>
  );
}
