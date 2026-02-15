import { Link, usePage } from "@inertiajs/react";
import AppLayout from "@/layout/AppLayout";
import { Button } from "@/components/ui/button";
import { SharedProps } from "@/types";

interface OrgProperty {
  id: number;
  name: string;
  path: string;
  active_incident_count: number;
}

interface OrgUser {
  id: number;
  full_name: string;
  email: string;
  user_type: string;
  path: string;
}

interface OrganizationDetail {
  id: number;
  name: string;
  path: string;
  edit_path: string;
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

  const address = [organization.street_address, organization.city, organization.state, organization.zip]
    .filter(Boolean)
    .join(", ");

  const contact = [organization.phone, organization.email].filter(Boolean).join(" · ");

  return (
    <AppLayout>
      <div className="mb-6">
        <Link href={routes.organizations} className="text-sm text-muted-foreground hover:text-foreground">
          &larr; Organizations
        </Link>
      </div>

      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-semibold text-foreground">{organization.name}</h1>
          {contact && <p className="text-muted-foreground mt-1">{contact}</p>}
          {address && <p className="text-sm text-muted-foreground mt-1">{address}</p>}
        </div>
        <Button variant="outline" asChild>
          <Link href={organization.edit_path}>Edit</Link>
        </Button>
      </div>

      {/* Properties */}
      <section className="mb-8">
        <h2 className="text-lg font-semibold text-foreground mb-3">Properties</h2>
        {organization.properties.length === 0 ? (
          <p className="text-sm text-muted-foreground">No properties for this organization.</p>
        ) : (
          <div className="rounded-md border divide-y">
            {organization.properties.map((p) => (
              <div key={p.id} className="px-4 py-3 flex items-center justify-between hover:bg-muted/30">
                <Link href={p.path} className="font-medium text-primary hover:underline">
                  {p.name}
                </Link>
                <span className="text-sm text-muted-foreground">
                  {p.active_incident_count} active {p.active_incident_count === 1 ? "incident" : "incidents"}
                </span>
              </div>
            ))}
          </div>
        )}
      </section>

      {/* Users */}
      <section>
        <h2 className="text-lg font-semibold text-foreground mb-3">Users</h2>
        {organization.users.length === 0 ? (
          <p className="text-sm text-muted-foreground">No users in this organization.</p>
        ) : (
          <div className="rounded-md border divide-y">
            {organization.users.map((u) => (
              <div key={u.id} className="px-4 py-3 flex items-center justify-between hover:bg-muted/30">
                <div>
                  <Link href={u.path} className="font-medium text-primary hover:underline">
                    {u.full_name}
                  </Link>
                  <span className="text-sm text-muted-foreground ml-2">{u.email}</span>
                </div>
                <span className="text-sm text-muted-foreground">
                  {roleLabel[u.user_type] || u.user_type}
                </span>
              </div>
            ))}
          </div>
        )}
      </section>
    </AppLayout>
  );
}
