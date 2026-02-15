import { Link, usePage } from "@inertiajs/react";
import AppLayout from "@/layout/AppLayout";
import { Button } from "@/components/ui/button";
import { SharedProps } from "@/types";

interface OrgProperty {
  id: number;
  name: string;
  active_incident_count: number;
}

interface OrgUser {
  id: number;
  full_name: string;
  email: string;
  user_type: string;
  active: boolean;
}

interface OrganizationDetail {
  id: number;
  name: string;
  phone: string | null;
  email: string | null;
  street_address: string | null;
  city: string | null;
  state: string | null;
  zip: string | null;
  properties: OrgProperty[];
  users: OrgUser[];
}

const roleLabel: Record<string, string> = {
  property_manager: "Property Manager",
  area_manager: "Area Manager",
  pm_manager: "PM Manager",
};

export default function OrganizationShow() {
  const { organization, routes } = usePage<SharedProps & { organization: OrganizationDetail }>().props;
  const org = organization;

  const address = [org.street_address, org.city, org.state, org.zip]
    .filter(Boolean)
    .join(", ");

  return (
    <AppLayout>
      <div className="mb-6">
        <Link href={routes.organizations} className="text-sm text-muted-foreground hover:text-foreground">
          &larr; Organizations
        </Link>
      </div>

      <div className="flex items-start justify-between mb-1">
        <h1 className="text-2xl font-semibold text-foreground">{org.name}</h1>
        <Button variant="outline" size="sm" asChild>
          <Link href={`/organizations/${org.id}/edit`}>Edit</Link>
        </Button>
      </div>

      <div className="text-sm text-muted-foreground space-x-2 mb-6">
        {org.phone && <span>{org.phone}</span>}
        {org.phone && org.email && <span>&middot;</span>}
        {org.email && <span>{org.email}</span>}
      </div>
      {address && (
        <p className="text-sm text-muted-foreground mb-6">{address}</p>
      )}

      <hr className="my-6" />

      <h2 className="text-sm font-semibold uppercase tracking-wide text-muted-foreground mb-3">
        Properties
      </h2>
      {org.properties.length === 0 ? (
        <p className="text-sm text-muted-foreground mb-6">No properties yet.</p>
      ) : (
        <div className="space-y-2 mb-6">
          {org.properties.map((prop) => (
            <Link
              key={prop.id}
              href={`/properties/${prop.id}`}
              className="block text-sm hover:bg-muted/30 rounded-md px-3 py-2 -mx-3"
            >
              <span className="font-medium text-foreground">{prop.name}</span>
              <span className="text-muted-foreground ml-2">
                &middot; {prop.active_incident_count} active incident{prop.active_incident_count !== 1 ? "s" : ""}
              </span>
            </Link>
          ))}
        </div>
      )}

      <hr className="my-6" />

      <h2 className="text-sm font-semibold uppercase tracking-wide text-muted-foreground mb-3">
        Users
      </h2>
      {org.users.length === 0 ? (
        <p className="text-sm text-muted-foreground">No users yet.</p>
      ) : (
        <div className="space-y-2">
          {org.users.map((user) => (
            <Link
              key={user.id}
              href={`/users/${user.id}`}
              className="block text-sm hover:bg-muted/30 rounded-md px-3 py-2 -mx-3"
            >
              <span className="font-medium text-foreground">{user.full_name}</span>
              <span className="text-muted-foreground ml-2">
                &middot; {user.email} &middot; {roleLabel[user.user_type] || user.user_type}
              </span>
            </Link>
          ))}
        </div>
      )}
    </AppLayout>
  );
}
