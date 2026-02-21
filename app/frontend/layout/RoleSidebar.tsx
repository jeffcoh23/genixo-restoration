import { Link, usePage } from "@inertiajs/react";
import { router } from "@inertiajs/react";
import {
  AlertTriangle,
  Building2,
  Building,
  Users,
  Phone,
  Wrench,
  Package,
  Settings,
  LogOut,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { SharedProps, NavItem } from "@/types";

const iconMap: Record<string, React.ReactNode> = {
  AlertTriangle: <AlertTriangle className="h-4 w-4" />,
  Building2: <Building2 className="h-4 w-4" />,
  Building: <Building className="h-4 w-4" />,
  Users: <Users className="h-4 w-4" />,
  Phone: <Phone className="h-4 w-4" />,
  Wrench: <Wrench className="h-4 w-4" />,
  Package: <Package className="h-4 w-4" />,
  Settings: <Settings className="h-4 w-4" />,
};

export default function RoleSidebar({ onNavigate }: { onNavigate: () => void }) {
  const { auth, routes, nav_items, has_unread_incidents } = usePage<SharedProps>().props;
  const user = auth.user;
  if (!user) return null;

  const currentPath = window.location.pathname;

  function handleLogout(e: React.MouseEvent) {
    e.preventDefault();
    router.delete(routes.logout);
  }

  return (
    <div className="flex flex-col h-[calc(100%-64px)]">
      <nav className="flex-1 px-3 py-2 space-y-1">
        {nav_items.map((item: NavItem) => {
          const isActive = currentPath === item.href ||
            currentPath.startsWith(item.href + "/");

          return (
            <Link
              key={item.href}
              href={item.href}
              onClick={onNavigate}
              className={`
                flex items-center gap-3 rounded px-3 py-2 text-sm
                transition-colors
                ${isActive
                  ? "bg-sidebar-accent text-sidebar-accent-foreground font-medium"
                  : "text-sidebar-foreground hover:bg-sidebar-accent/50"
                }
              `}
            >
              {iconMap[item.icon]}
              {item.label}
              {item.label === "Incidents" && has_unread_incidents && (
                <span className="ml-auto h-2 w-2 rounded-full bg-primary" />
              )}
            </Link>
          );
        })}
      </nav>

      {/* User info + logout */}
      <div className="border-t border-sidebar-border px-4 py-3">
        <div className="text-sm font-medium text-sidebar-foreground">
          {user.full_name}
        </div>
        <div className="text-xs text-sidebar-muted-foreground">
          {user.organization_name}
        </div>
        <div className="text-xs text-sidebar-muted-foreground">
          {user.role_label}
        </div>
        <Button
          variant="ghost"
          size="sm"
          onClick={handleLogout}
          className="mt-2 h-auto p-0 flex items-center gap-2 text-xs text-sidebar-muted-foreground hover:text-sidebar-foreground"
        >
          <LogOut className="h-3 w-3" />
          Log out
        </Button>
      </div>
    </div>
  );
}
