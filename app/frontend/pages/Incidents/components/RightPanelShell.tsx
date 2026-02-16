import { Button } from "@/components/ui/button";

interface RightPanelShellProps {
  activeTab: string;
  onTabChange: (tab: string) => void;
  children: React.ReactNode;
}

const tabs = [
  { key: "daily_log", label: "Daily Log" },
  { key: "activity", label: "Activity" },
  { key: "messages", label: "Messages" },
  { key: "documents", label: "Documents" },
];

export default function RightPanelShell({ activeTab, onTabChange, children }: RightPanelShellProps) {
  return (
    <div className="flex flex-col h-full">
      <div className="flex border-b border-border">
        {tabs.map((tab) => (
          <Button
            key={tab.key}
            variant="ghost"
            onClick={() => onTabChange(tab.key)}
            className={`px-4 py-2 h-auto rounded-none text-sm font-medium border-b-2 transition-colors ${
              activeTab === tab.key
                ? "border-primary text-foreground"
                : "border-transparent text-muted-foreground hover:text-foreground"
            }`}
          >
            {tab.label}
          </Button>
        ))}
      </div>

      <div className="flex-1 overflow-hidden">
        {children}
      </div>
    </div>
  );
}
