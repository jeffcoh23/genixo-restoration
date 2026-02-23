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
  { key: "labor", label: "Labor" },
  { key: "equipment", label: "Equipment" },
  { key: "photos", label: "Photos" },
  { key: "documents", label: "Documents" },
  { key: "messages", label: "Messages" },
  { key: "manage", label: "Manage" },
];

export default function RightPanelShell({ activeTab, onTabChange, unreadMessages = 0, unreadActivity = 0, children }: RightPanelShellProps) {
  return (
    <div className="flex flex-col h-full">
      <div className="border-b border-border overflow-x-auto">
        <div className="flex min-w-max">
        {tabs.map((tab) => {
          const badge = tab.key === "messages" ? unreadMessages
            : tab.key === "daily_log" ? unreadActivity
            : 0;

          return (
            <Button
              key={tab.key}
              variant="ghost"
              onClick={() => onTabChange(tab.key)}
              data-testid={`incident-tab-${tab.key}`}
              className={`px-3 sm:px-4 py-3 sm:py-2 h-auto rounded-none text-sm font-medium border-b-2 transition-colors whitespace-nowrap ${
                activeTab === tab.key
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
      </div>

      <div className="flex-1 overflow-hidden">
        {children}
      </div>
    </div>
  );
}
