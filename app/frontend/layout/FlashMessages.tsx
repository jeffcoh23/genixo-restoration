import { useEffect, useState } from "react";

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
        <div className="rounded-md bg-primary/10 px-4 py-3 text-sm text-primary">
          {flash.notice}
        </div>
      )}
      {flash.alert && (
        <div className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive">
          {flash.alert}
        </div>
      )}
    </div>
  );
}
