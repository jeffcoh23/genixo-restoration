import { Button } from "@/components/ui/button";

interface RightPanelShellProps {
  activeTab: string;
  onTabChange: (tab: string) => void;
  unreadMessages?: number;
  unreadActivity?: number;
  children: React.ReactNode;
}

const tabs = [
  { key: "daily_log", label: "Daily Log" },
  { key: "equipment", label: "Equipment" },
  { key: "labor", label: "Labor" },
  { key: "messages", label: "Messages" },
  { key: "documents", label: "Documents" },
  { key: "manage", label: "Manage" },
];

export default function RightPanelShell({ activeTab, onTabChange, unreadMessages = 0, unreadActivity = 0, children }: RightPanelShellProps) {
  return (
    <div className="flex flex-col h-full">
      <div className="flex overflow-x-auto border-b border-border shrink-0" role="tablist">
        {tabs.map((tab) => {
          const badge = tab.key === "messages" ? unreadMessages
            : tab.key === "daily_log" ? unreadActivity
            : 0;
          const isActive = activeTab === tab.key;

          return (
            <Button
              key={tab.key}
              variant="ghost"
              role="tab"
              aria-selected={isActive}
              onClick={() => onTabChange(tab.key)}
              className={`px-4 py-2.5 sm:py-2 h-auto rounded-none text-sm font-medium border-b-2 transition-colors whitespace-nowrap ${
                isActive
                  ? "border-primary text-foreground"
                  : "border-transparent text-muted-foreground hover:text-foreground"
              }`}
            >
              {tab.label}
              {badge > 0 && (
                <span className="ml-1.5 inline-flex items-center justify-center rounded-full bg-primary text-primary-foreground text-xs font-semibold min-w-[18px] h-[18px] px-1">
                  {badge}
                </span>
              )}
            </Button>
          );
        })}
      </div>

      <div className="flex-1 overflow-hidden">
        {children}
      </div>
    </div>
  );
}
