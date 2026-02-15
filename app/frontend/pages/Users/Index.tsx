import { Link, usePage } from "@inertiajs/react";
import { useState } from "react";
import AppLayout from "@/layout/AppLayout";
import { SharedProps } from "@/types";

interface UserRow {
  id: number;
  path: string;
  full_name: string;
  email: string;
  phone: string | null;
  user_type: string;
  organization_name: string;
  active: boolean;
}

const roleLabel: Record<string, string> = {
  manager: "Manager",
  technician: "Technician",
  office_sales: "Office/Sales",
  property_manager: "Property Manager",
  area_manager: "Area Manager",
  pm_manager: "PM Manager",
};

export default function UsersIndex() {
  const { active_users, deactivated_users } = usePage<SharedProps & {
    active_users: UserRow[];
    deactivated_users: UserRow[];
  }>().props;

  const [showDeactivated, setShowDeactivated] = useState(false);

  return (
    <AppLayout>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-semibold text-foreground">Users</h1>
      </div>

      {/* Active Users */}
      {active_users.length === 0 ? (
        <p className="text-muted-foreground">No team members yet.</p>
      ) : (
        <div className="rounded-md border">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b bg-muted/50">
                <th className="px-4 py-3 text-left font-medium">Name</th>
                <th className="px-4 py-3 text-left font-medium">Email</th>
                <th className="px-4 py-3 text-left font-medium">Role</th>
                <th className="px-4 py-3 text-left font-medium">Organization</th>
                <th className="px-4 py-3 text-left font-medium">Phone</th>
              </tr>
            </thead>
            <tbody>
              {active_users.map((u) => (
                <tr key={u.id} className="border-b last:border-0 hover:bg-muted/30">
                  <td className="px-4 py-3">
                    <Link href={u.path} className="font-medium text-primary hover:underline">
                      {u.full_name}
                    </Link>
                  </td>
                  <td className="px-4 py-3 text-muted-foreground">{u.email}</td>
                  <td className="px-4 py-3 text-muted-foreground">{roleLabel[u.user_type] || u.user_type}</td>
                  <td className="px-4 py-3 text-muted-foreground">{u.organization_name}</td>
                  <td className="px-4 py-3 text-muted-foreground">{u.phone || "—"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Deactivated Users */}
      {deactivated_users.length > 0 && (
        <div className="mt-6">
          <button
            onClick={() => setShowDeactivated(!showDeactivated)}
            className="text-sm text-muted-foreground hover:text-foreground flex items-center gap-1"
          >
            <span className="text-xs">{showDeactivated ? "▼" : "▶"}</span>
            Deactivated Users ({deactivated_users.length})
          </button>

          {showDeactivated && (
            <div className="rounded-md border mt-2">
              <table className="w-full text-sm">
                <tbody>
                  {deactivated_users.map((u) => (
                    <tr key={u.id} className="border-b last:border-0 hover:bg-muted/30">
                      <td className="px-4 py-3">
                        <Link href={u.path} className="font-medium text-primary hover:underline">
                          {u.full_name}
                        </Link>
                      </td>
                      <td className="px-4 py-3 text-muted-foreground">{u.email}</td>
                      <td className="px-4 py-3 text-muted-foreground">{roleLabel[u.user_type] || u.user_type}</td>
                      <td className="px-4 py-3 text-muted-foreground">{u.organization_name}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}
    </AppLayout>
  );
}
