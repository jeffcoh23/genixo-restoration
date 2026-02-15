import { Link, usePage, router } from "@inertiajs/react";
import AppLayout from "@/layout/AppLayout";
import { Button } from "@/components/ui/button";
import { SharedProps } from "@/types";

interface AssignedProperty {
  id: number;
  name: string;
  path: string;
}

interface AssignedIncident {
  id: number;
  description: string;
  damage_type: string;
  status: string;
  property_name: string;
  path: string;
}

interface UserDetail {
  id: number;
  path: string;
  full_name: string;
  first_name: string;
  last_name: string;
  email: string;
  phone: string | null;
  user_type: string;
  organization_name: string;
  organization_type: string;
  timezone: string;
  active: boolean;
  deactivate_path: string;
  reactivate_path: string;
  assigned_properties?: AssignedProperty[];
  assigned_incidents: AssignedIncident[];
}

const roleLabel: Record<string, string> = {
  manager: "Manager",
  technician: "Technician",
  office_sales: "Office/Sales",
  property_manager: "Property Manager",
  area_manager: "Area Manager",
  pm_manager: "PM Manager",
};

const statusLabel: Record<string, string> = {
  new: "New",
  dispatched: "Dispatched",
  in_progress: "In Progress",
  on_hold: "On Hold",
};

const damageLabel: Record<string, string> = {
  flood: "Flood",
  fire: "Fire",
  smoke: "Smoke",
  mold: "Mold",
  odor: "Odor",
  other: "Other",
};

export default function UserShow() {
  const { user, can_deactivate, routes } = usePage<SharedProps & {
    user: UserDetail;
    can_deactivate: boolean;
  }>().props;

  function handleDeactivate() {
    if (!confirm(`Deactivate ${user.full_name}? They will no longer be able to log in.`)) return;
    router.patch(user.deactivate_path);
  }

  function handleReactivate() {
    router.patch(user.reactivate_path);
  }

  const isPmUser = user.organization_type === "property_management";

  return (
    <AppLayout>
      <div className="mb-6">
        <Link href={routes.users} className="text-sm text-muted-foreground hover:text-foreground">
          &larr; Users
        </Link>
      </div>

      <div className="flex items-center justify-between mb-6">
        <div>
          <div className="flex items-center gap-3">
            <h1 className="text-2xl font-semibold text-foreground">{user.full_name}</h1>
            {!user.active && (
              <span className="text-xs px-2 py-1 rounded-full bg-destructive/10 text-destructive font-medium">
                Deactivated
              </span>
            )}
          </div>
          <p className="text-muted-foreground mt-1">
            {roleLabel[user.user_type] || user.user_type} at {user.organization_name}
          </p>
          <div className="flex gap-4 text-sm text-muted-foreground mt-1">
            <span>{user.email}</span>
            {user.phone && <span>{user.phone}</span>}
            <span>{user.timezone}</span>
          </div>
        </div>
        <div className="flex gap-2">
          {can_deactivate && user.active && (
            <Button variant="outline" onClick={handleDeactivate}>
              Deactivate
            </Button>
          )}
          {!user.active && (
            <Button variant="outline" onClick={handleReactivate}>
              Reactivate
            </Button>
          )}
        </div>
      </div>

      {/* Property Assignments (PM users only) */}
      <section className="mb-8">
        <h2 className="text-lg font-semibold text-foreground mb-3">Property Assignments</h2>
        {!isPmUser ? (
          <p className="text-sm text-muted-foreground">Not applicable — mitigation user.</p>
        ) : user.assigned_properties && user.assigned_properties.length > 0 ? (
          <div className="rounded-md border divide-y">
            {user.assigned_properties.map((p) => (
              <div key={p.id} className="px-4 py-3 hover:bg-muted/30">
                <Link href={p.path} className="font-medium text-primary hover:underline">
                  {p.name}
                </Link>
              </div>
            ))}
          </div>
        ) : (
          <p className="text-sm text-muted-foreground">No properties assigned.</p>
        )}
      </section>

      {/* Active Incidents */}
      <section>
        <h2 className="text-lg font-semibold text-foreground mb-3">Active Incidents</h2>
        {user.assigned_incidents.length === 0 ? (
          <p className="text-sm text-muted-foreground">No active incidents assigned.</p>
        ) : (
          <div className="rounded-md border divide-y">
            {user.assigned_incidents.map((i) => (
              <div key={i.id} className="px-4 py-3 flex items-center justify-between hover:bg-muted/30">
                <div>
                  <Link href={i.path} className="font-medium text-primary hover:underline">
                    {damageLabel[i.damage_type] || i.damage_type} — {i.description.slice(0, 50)}
                    {i.description.length > 50 && "..."}
                  </Link>
                  <span className="text-sm text-muted-foreground ml-2">{i.property_name}</span>
                </div>
                <span className="text-xs px-2 py-1 rounded-full bg-muted text-muted-foreground">
                  {statusLabel[i.status] || i.status}
                </span>
              </div>
            ))}
          </div>
        )}
      </section>
    </AppLayout>
  );
}
