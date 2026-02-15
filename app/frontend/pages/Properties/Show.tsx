import { Link, usePage } from "@inertiajs/react";
import AppLayout from "@/layout/AppLayout";
import { Button } from "@/components/ui/button";
import { SharedProps } from "@/types";

interface AssignedUser {
  id: number;
  full_name: string;
  email: string;
  user_type: string;
  path: string;
}

interface PropertyIncident {
  id: number;
  description: string;
  damage_type: string;
  status: string;
  path: string;
}

interface PropertyDetail {
  id: number;
  name: string;
  path: string;
  edit_path: string;
  street_address: string | null;
  city: string | null;
  state: string | null;
  zip: string | null;
  unit_count: number | null;
  pm_org: { id: number; name: string; path: string };
  mitigation_org: { id: number; name: string };
  assigned_users: AssignedUser[];
  incidents: PropertyIncident[];
}

const roleLabel: Record<string, string> = {
  property_manager: "Property Manager",
  area_manager: "Area Manager",
  pm_manager: "PM Manager",
  manager: "Manager",
  office_sales: "Office/Sales",
  technician: "Technician",
};

const statusLabel: Record<string, string> = {
  new: "New",
  dispatched: "Dispatched",
  in_progress: "In Progress",
  on_hold: "On Hold",
  completed: "Completed",
  completed_billed: "Billed",
  paid: "Paid",
  closed: "Closed",
};

const damageLabel: Record<string, string> = {
  flood: "Flood",
  fire: "Fire",
  smoke: "Smoke",
  mold: "Mold",
  odor: "Odor",
  other: "Other",
};

export default function PropertyShow() {
  const { property, can_edit, routes } = usePage<SharedProps & {
    property: PropertyDetail;
    can_edit: boolean;
  }>().props;

  const address = [property.street_address, property.city, property.state, property.zip]
    .filter(Boolean)
    .join(", ");

  return (
    <AppLayout>
      <div className="mb-6">
        <Link href={routes.properties} className="text-sm text-muted-foreground hover:text-foreground">
          &larr; Properties
        </Link>
      </div>

      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-semibold text-foreground">{property.name}</h1>
          {address && <p className="text-muted-foreground mt-1">{address}</p>}
          {property.unit_count && (
            <p className="text-sm text-muted-foreground mt-1">
              {property.unit_count} {property.unit_count === 1 ? "unit" : "units"}
            </p>
          )}
        </div>
        {can_edit && (
          <Button variant="outline" asChild>
            <Link href={property.edit_path}>Edit</Link>
          </Button>
        )}
      </div>

      <div className="flex gap-6 text-sm text-muted-foreground mb-8">
        <div>
          <span className="font-medium text-foreground">PM Organization:</span>{" "}
          <Link href={property.pm_org.path} className="text-primary hover:underline">
            {property.pm_org.name}
          </Link>
        </div>
        <div>
          <span className="font-medium text-foreground">Mitigation:</span>{" "}
          {property.mitigation_org.name}
        </div>
      </div>

      {/* Assigned Users */}
      <section className="mb-8">
        <h2 className="text-lg font-semibold text-foreground mb-3">Assigned Users</h2>
        {property.assigned_users.length === 0 ? (
          <p className="text-sm text-muted-foreground">No users assigned to this property.</p>
        ) : (
          <div className="rounded-md border divide-y">
            {property.assigned_users.map((user) => (
              <div key={user.id} className="px-4 py-3 flex items-center justify-between hover:bg-muted/30">
                <div>
                  <Link href={user.path} className="font-medium text-primary hover:underline">
                    {user.full_name}
                  </Link>
                  <span className="text-sm text-muted-foreground ml-2">{user.email}</span>
                </div>
                <span className="text-sm text-muted-foreground">
                  {roleLabel[user.user_type] || user.user_type}
                </span>
              </div>
            ))}
          </div>
        )}
      </section>

      {/* Incidents */}
      <section>
        <h2 className="text-lg font-semibold text-foreground mb-3">Incidents</h2>
        {property.incidents.length === 0 ? (
          <p className="text-sm text-muted-foreground">No incidents for this property.</p>
        ) : (
          <div className="rounded-md border divide-y">
            {property.incidents.map((incident) => (
              <div key={incident.id} className="px-4 py-3 flex items-center justify-between hover:bg-muted/30">
                <div>
                  <Link href={incident.path} className="font-medium text-primary hover:underline">
                    {damageLabel[incident.damage_type] || incident.damage_type} — {incident.description.slice(0, 60)}
                    {incident.description.length > 60 && "..."}
                  </Link>
                </div>
                <span className="text-xs px-2 py-1 rounded-full bg-muted text-muted-foreground">
                  {statusLabel[incident.status] || incident.status}
                </span>
              </div>
            ))}
          </div>
        )}
      </section>
    </AppLayout>
  );
}
