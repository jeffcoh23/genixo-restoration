import { useEffect, useState } from "react";
import { Alert, AlertDescription } from "@/components/ui/alert";

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

  return (
    <div className="mb-4 space-y-2">
      {flash.notice && (
        <Alert>
          <AlertDescription>{flash.notice}</AlertDescription>
        </Alert>
      )}
      {flash.alert && (
        <Alert variant="destructive">
          <AlertDescription>{flash.alert}</AlertDescription>
        </Alert>
      )}
    </div>
  );
}
