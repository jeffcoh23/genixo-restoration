import { router, usePage } from "@inertiajs/react";
import { useEffect, useRef, useState } from "react";
import { Menu, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { SharedProps } from "@/types";
import RoleSidebar from "./RoleSidebar";
import FlashMessages from "./FlashMessages";
import ErrorBoundary from "@/components/ErrorBoundary";

export default function AppLayout({ children, wide }: { children: React.ReactNode; wide?: boolean }) {
  const { flash } = usePage<SharedProps>().props;
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [progress, setProgress] = useState<number | null>(null);
  const timerRef = useRef<ReturnType<typeof setTimeout>>(undefined);

  useEffect(() => {
    const removeStart = router.on("start", (event) => {
      // Skip progress bar for non-navigation requests (e.g. DFR generation with preserveScroll)
      if ((event.detail.visit as { preserveScroll?: boolean }).preserveScroll) return;
      setProgress(0);
      // Animate to 80% over 300ms
      requestAnimationFrame(() => setProgress(80));
    });

    const removeFinish = router.on("finish", () => {
      setProgress(100);
      timerRef.current = setTimeout(() => setProgress(null), 200);
    });

    return () => {
      removeStart();
      removeFinish();
      if (timerRef.current) clearTimeout(timerRef.current);
    };
  }, []);

  return (
    <div className="flex h-screen bg-background" data-app-shell-frame>
      {/* Navigation progress bar */}
      {progress !== null && (
        <div className="fixed top-0 left-0 right-0 z-[100] h-0.5">
          <div
            className="h-full bg-primary transition-all ease-out"
            style={{
              width: `${progress}%`,
              transitionDuration: progress === 100 ? "150ms" : "300ms",
              opacity: progress === 100 ? 0 : 1,
            }}
          />
        </div>
      )}
      {/* Mobile overlay */}
      {sidebarOpen && (
        <div
          data-app-shell-overlay
          className="fixed inset-0 z-40 bg-black opacity-40 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside
        data-app-shell-sidebar
        className={`
          fixed inset-y-0 left-0 z-50 w-60 bg-sidebar border-r border-sidebar-border
          transform transition-transform duration-200 ease-in-out
          lg:relative lg:translate-x-0
          ${sidebarOpen ? "translate-x-0" : "-translate-x-full"}
        `}
      >
        <div className="flex items-center justify-between p-4">
          <img src="/brand/genixio-horizontal-white-caps.png" alt="Genixo Restoration" className="h-7" />
          <Button
            variant="ghost"
            size="sm"
            onClick={() => setSidebarOpen(false)}
            className="lg:hidden text-sidebar-foreground h-auto p-0"
          >
            <X className="h-5 w-5" />
          </Button>
        </div>

        <RoleSidebar onNavigate={() => setSidebarOpen(false)} />
      </aside>

      {/* Main content */}
      <main className="flex-1 overflow-auto" data-app-shell-main>
        {/* Mobile header */}
        <div
          data-app-shell-mobile-header
          className="sticky top-0 z-30 flex items-center gap-3 border-b bg-background px-4 py-3 lg:hidden"
        >
          <Button variant="ghost" size="sm" className="h-auto p-0" onClick={() => setSidebarOpen(true)}>
            <Menu className="h-5 w-5 text-foreground" />
          </Button>
          <img src="/brand/genixio-horizontal-white-caps.png" alt="Genixo Restoration" className="h-6" />
        </div>

        <div className={`mx-auto ${wide ? "max-w-7xl" : "max-w-5xl"} px-4 py-6 sm:px-6`}>
          <FlashMessages flash={flash} />
          <ErrorBoundary>
            {children}
          </ErrorBoundary>
        </div>
      </main>
    </div>
  );
}
