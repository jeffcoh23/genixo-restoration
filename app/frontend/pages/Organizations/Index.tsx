import { usePage } from "@inertiajs/react";
import AppLayout from "@/layout/AppLayout";
import PageHeader from "@/components/PageHeader";
import DataTable, { Column, LinkCell, MutedCell } from "@/components/DataTable";
import { SharedProps } from "@/types";

interface Organization {
  id: number;
  name: string;
  path: string;
  phone: string | null;
  email: string | null;
  property_count: number;
  user_count: number;
}

const columns: Column<Organization>[] = [
  { header: "Name", render: (org) => <LinkCell href={org.path}>{org.name}</LinkCell> },
  { header: "Phone", render: (org) => <MutedCell>{org.phone || "—"}</MutedCell> },
  { header: "Email", render: (org) => <MutedCell>{org.email || "—"}</MutedCell> },
  { header: "Properties", align: "right", render: (org) => org.property_count },
  { header: "Users", align: "right", render: (org) => org.user_count },
];

export default function OrganizationsIndex() {
  const { organizations, routes } = usePage<SharedProps & { organizations: Organization[] }>().props;

  return (
    <AppLayout wide>
      <PageHeader title="Property Management" action={{ href: routes.new_organization, label: "New Company" }} />
      <DataTable
        columns={columns}
        rows={organizations}
        keyFn={(org) => org.id}
        emptyMessage='No property management companies yet. Use "New Company" to add one.'
      />
    </AppLayout>
  );
}
