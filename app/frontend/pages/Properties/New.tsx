import { Link, useForm, usePage } from "@inertiajs/react";
import { FormEvent } from "react";
import AppLayout from "@/layout/AppLayout";
import PageHeader from "@/components/PageHeader";
import FormField from "@/components/FormField";
import AddressFields from "@/components/AddressFields";
import { Button } from "@/components/ui/button";
import { SharedProps } from "@/types";

interface PmOrg {
  id: number;
  name: string;
}

export default function NewProperty() {
  const { pm_organizations, routes } = usePage<SharedProps & { pm_organizations: PmOrg[] }>().props;

  const { data, setData, post, processing, errors } = useForm({
    name: "",
    property_management_org_id: pm_organizations.length === 1 ? String(pm_organizations[0].id) : "",
    street_address: "",
    city: "",
    state: "",
    zip: "",
    unit_count: "",
  });

  function handleSubmit(e: FormEvent) {
    e.preventDefault();
    post(routes.properties);
  }

  return (
    <AppLayout>
      <PageHeader title="New Property" backLink={{ href: routes.properties, label: "Properties" }} />

      <form onSubmit={handleSubmit} className="max-w-lg space-y-4">
        <FormField id="name" label="Name" value={data.name} onChange={(v) => setData("name", v)} error={errors.name} required />

        <div className="space-y-2">
          <label htmlFor="pm_org" className="text-sm font-medium">PM Organization *</label>
          <select
            id="pm_org"
            value={data.property_management_org_id}
            onChange={(e) => setData("property_management_org_id", e.target.value)}
            className="flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-xs"
          >
            <option value="">Select an organization...</option>
            {pm_organizations.map((org) => (
              <option key={org.id} value={org.id}>{org.name}</option>
            ))}
          </select>
          {errors.property_management_org_id && (
            <p className="text-sm text-destructive">{errors.property_management_org_id}</p>
          )}
        </div>

        <AddressFields data={data} setData={setData} />
        <FormField id="unit_count" label="Unit Count" type="number" value={data.unit_count} onChange={(v) => setData("unit_count", v)} />

        <div className="flex gap-3 pt-2">
          <Button variant="outline" asChild>
            <Link href={routes.properties}>Cancel</Link>
          </Button>
          <Button type="submit" disabled={processing}>
            {processing ? "Creating..." : "Create Property"}
          </Button>
        </div>
      </form>
    </AppLayout>
  );
}
