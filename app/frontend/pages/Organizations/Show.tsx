import { Link, usePage } from "@inertiajs/react";
import AppLayout from "@/layout/AppLayout";
import PageHeader from "@/components/PageHeader";
import DetailList, { DetailRow } from "@/components/DetailList";
import { Button } from "@/components/ui/button";
import { SharedProps } from "@/types";

interface OrgProperty {
  id: number;
  name: string;
  path: string;
  active_incident_summary: string;
}

interface OrgUser {
  id: number;
  full_name: string;
  email: string;
  role_label: string;
  path: string;
}

interface OrganizationDetail {
  id: number;
  name: string;
  path: string;
  edit_path: string;
  address: string;
  contact: string;
  properties: OrgProperty[];
  users: OrgUser[];
}

export default function OrganizationShow() {
  const { organization, routes } = usePage<SharedProps & { organization: OrganizationDetail }>().props;

  return (
    <AppLayout>
      <PageHeader
        title={organization.name}
        backLink={{ href: routes.organizations, label: "Property Management" }}
      />

      <div className="flex items-center justify-between mb-6">
        <div>
          {organization.contact && <p className="text-muted-foreground">{organization.contact}</p>}
          {organization.address && <p className="text-sm text-muted-foreground mt-1">{organization.address}</p>}
        </div>
        <Button variant="outline" asChild>
          <Link href={organization.edit_path}>Edit</Link>
        </Button>
      </div>

      {/* Properties */}
      <section className="mb-8">
        <h2 className="text-lg font-semibold text-foreground mb-3">Properties</h2>
        <DetailList isEmpty={organization.properties.length === 0} emptyMessage="No properties for this organization.">
          {organization.properties.map((p) => (
            <DetailRow key={p.id}>
              <Link href={p.path} className="font-medium text-primary hover:underline">{p.name}</Link>
              <span className="text-sm text-muted-foreground">{p.active_incident_summary}</span>
            </DetailRow>
          ))}
        </DetailList>
      </section>

      {/* Users */}
      <section>
        <h2 className="text-lg font-semibold text-foreground mb-3">Users</h2>
        <DetailList isEmpty={organization.users.length === 0} emptyMessage="No users in this organization.">
          {organization.users.map((u) => (
            <DetailRow key={u.id}>
              <div>
                <Link href={u.path} className="font-medium text-primary hover:underline">{u.full_name}</Link>
                <span className="text-sm text-muted-foreground ml-2">{u.email}</span>
              </div>
              <span className="text-sm text-muted-foreground">{u.role_label}</span>
            </DetailRow>
          ))}
        </DetailList>
      </section>
    </AppLayout>
  );
}
