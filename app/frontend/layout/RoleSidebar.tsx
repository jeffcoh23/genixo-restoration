import { Link, usePage } from "@inertiajs/react";
import { router } from "@inertiajs/react";
import {
  LayoutDashboard,
  AlertTriangle,
  Building2,
  Building,
  Users,
  Phone,
  Wrench,
  Settings,
  LogOut,
} from "lucide-react";
import { SharedProps } from "@/types";

interface NavItem {
  label: string;
  href: string;
  icon: React.ReactNode;
  roles: string[];
}

export default function RoleSidebar({ onNavigate }: { onNavigate: () => void }) {
  const { auth, routes } = usePage<SharedProps>().props;
  const user = auth.user;
  if (!user) return null;

  const navItems: NavItem[] = [
    {
      label: "Dashboard",
      href: routes.dashboard,
      icon: <LayoutDashboard className="h-4 w-4" />,
      roles: ["manager", "technician", "office_sales", "property_manager", "area_manager", "pm_manager"],
    },
    {
      label: "Incidents",
      href: routes.incidents,
      icon: <AlertTriangle className="h-4 w-4" />,
      roles: ["manager", "technician", "office_sales", "property_manager", "area_manager", "pm_manager"],
    },
    {
      label: "Properties",
      href: routes.properties,
      icon: <Building2 className="h-4 w-4" />,
      roles: ["manager", "office_sales", "property_manager", "area_manager", "pm_manager"],
    },
    {
      label: "Organizations",
      href: routes.organizations,
      icon: <Building className="h-4 w-4" />,
      roles: ["manager", "office_sales"],
    },
    {
      label: "Users",
      href: routes.users,
      icon: <Users className="h-4 w-4" />,
      roles: ["manager", "office_sales"],
    },
    {
      label: "On-Call",
      href: routes.on_call,
      icon: <Phone className="h-4 w-4" />,
      roles: ["manager"],
    },
    {
      label: "Equipment Types",
      href: routes.equipment_types,
      icon: <Wrench className="h-4 w-4" />,
      roles: ["manager"],
    },
    {
      label: "Settings",
      href: routes.settings,
      icon: <Settings className="h-4 w-4" />,
      roles: ["manager", "technician", "office_sales", "property_manager", "area_manager", "pm_manager"],
    },
  ];

  const visibleItems = navItems.filter((item) => item.roles.includes(user.user_type));
  const currentPath = window.location.pathname;

  function handleLogout(e: React.MouseEvent) {
    e.preventDefault();
    router.delete(routes.logout);
  }

  const roleLabel: Record<string, string> = {
    manager: "Manager",
    technician: "Technician",
    office_sales: "Office/Sales",
    property_manager: "Property Manager",
    area_manager: "Area Manager",
    pm_manager: "PM Manager",
  };

  return (
    <div className="flex flex-col h-[calc(100%-64px)]">
      <nav className="flex-1 px-3 py-2 space-y-1">
        {visibleItems.map((item) => {
          const isActive = currentPath === item.href ||
            (item.href !== routes.dashboard && currentPath.startsWith(item.href));

          return (
            <Link
              key={item.href}
              href={item.href}
              onClick={onNavigate}
              className={`
                flex items-center gap-3 rounded-md px-3 py-2 text-sm
                transition-colors
                ${isActive
                  ? "bg-sidebar-accent text-sidebar-accent-foreground font-medium"
                  : "text-sidebar-foreground hover:bg-sidebar-accent/50"
                }
              `}
            >
              {item.icon}
              {item.label}
            </Link>
          );
        })}
      </nav>

      {/* User info + logout */}
      <div className="border-t border-sidebar-border px-4 py-3">
        <div className="text-sm font-medium text-sidebar-foreground">
          {user.full_name}
        </div>
        <div className="text-xs text-muted-foreground">
          {user.organization_name}
        </div>
        <div className="text-xs text-muted-foreground">
          {roleLabel[user.user_type] || user.user_type}
        </div>
        <button
          onClick={handleLogout}
          className="mt-2 flex items-center gap-2 text-xs text-muted-foreground hover:text-foreground transition-colors"
        >
          <LogOut className="h-3 w-3" />
          Log out
        </button>
      </div>
    </div>
  );
}
