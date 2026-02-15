import { usePage } from "@inertiajs/react";
import AppLayout from "@/layout/AppLayout";
import PageHeader from "@/components/PageHeader";
import DataTable, { Column, LinkCell, MutedCell } from "@/components/DataTable";
import { SharedProps } from "@/types";

interface Property {
  id: number;
  name: string;
  path: string;
  address: string;
  pm_org_name: string;
  active_incident_count: number;
  total_incident_count: number;
}

const columns: Column<Property>[] = [
  { header: "Name", render: (p) => <LinkCell href={p.path}>{p.name}</LinkCell> },
  { header: "Address", render: (p) => <MutedCell>{p.address || "—"}</MutedCell> },
  { header: "PM Organization", render: (p) => <MutedCell>{p.pm_org_name}</MutedCell> },
  { header: "Active", align: "right", render: (p) => p.active_incident_count },
  { header: "Total", align: "right", render: (p) => p.total_incident_count },
];

export default function PropertiesIndex() {
  const { properties, can_create, routes } = usePage<SharedProps & {
    properties: Property[];
    can_create: boolean;
  }>().props;

  return (
    <AppLayout>
      <PageHeader
        title="Properties"
        action={can_create ? { href: routes.new_property, label: "New Property" } : undefined}
      />
      <DataTable
        columns={columns}
        rows={properties}
        keyFn={(p) => p.id}
        emptyMessage={can_create ? 'No properties yet. Use "New Property" to add one.' : "No properties yet."}
      />
    </AppLayout>
  );
}
