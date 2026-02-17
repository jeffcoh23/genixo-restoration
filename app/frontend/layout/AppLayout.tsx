import { usePage } from "@inertiajs/react";
import { useState } from "react";
import { Menu, X } from "lucide-react";
import { SharedProps } from "@/types";
import RoleSidebar from "./RoleSidebar";
import FlashMessages from "./FlashMessages";

export default function AppLayout({ children, wide }: { children: React.ReactNode; wide?: boolean }) {
  const { flash } = usePage<SharedProps>().props;
  const [sidebarOpen, setSidebarOpen] = useState(false);

  return (
    <div className="flex h-screen bg-background">
      {/* Mobile overlay */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 z-40 bg-black/50 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside
        className={`
          fixed inset-y-0 left-0 z-50 w-60 bg-sidebar border-r border-sidebar-border
          transform transition-transform duration-200 ease-in-out
          lg:relative lg:translate-x-0
          ${sidebarOpen ? "translate-x-0" : "-translate-x-full"}
        `}
      >
        <div className="flex items-center justify-between p-4 lg:justify-center">
          <div className="flex items-center gap-2">
            <div className="flex h-8 w-8 items-center justify-center rounded-full bg-primary text-primary-foreground text-sm font-bold">
              G
            </div>
            <span className="text-sm font-semibold text-sidebar-foreground">
              Genixo Restoration
            </span>
          </div>
          <button
            onClick={() => setSidebarOpen(false)}
            className="lg:hidden text-sidebar-foreground"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <RoleSidebar onNavigate={() => setSidebarOpen(false)} />
      </aside>

      {/* Main content */}
      <main className="flex-1 overflow-auto">
        {/* Mobile header */}
        <div className="sticky top-0 z-30 flex items-center gap-3 border-b bg-background px-4 py-3 lg:hidden">
          <button onClick={() => setSidebarOpen(true)}>
            <Menu className="h-5 w-5 text-foreground" />
          </button>
          <span className="text-sm font-semibold text-foreground">
            Genixo Restoration
          </span>
        </div>

        <div className={`mx-auto ${wide ? "max-w-7xl" : "max-w-5xl"} px-4 py-6 sm:px-6`}>
          <FlashMessages flash={flash} />
          {children}
        </div>
      </main>
    </div>
  );
}
