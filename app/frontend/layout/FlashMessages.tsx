import { useEffect, useState } from "react";

interface FlashMessagesProps {
  flash: {
    notice?: string;
    alert?: string;
  };
}

export default function FlashMessages({ flash }: FlashMessagesProps) {
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    if (flash.notice || flash.alert) {
      setVisible(true);
      const timer = setTimeout(() => setVisible(false), 5000);
      return () => clearTimeout(timer);
    }
  }, [flash.notice, flash.alert]);

  if (!visible || (!flash.notice && !flash.alert)) return null;

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
