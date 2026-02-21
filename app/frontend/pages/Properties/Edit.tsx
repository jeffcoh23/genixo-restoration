import { Link, useForm, usePage } from "@inertiajs/react";
import { FormEvent } from "react";
import AppLayout from "@/layout/AppLayout";
import PageHeader from "@/components/PageHeader";
import FormField from "@/components/FormField";
import AddressFields from "@/components/AddressFields";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { SharedProps } from "@/types";

interface PmOrg {
  id: number;
  name: string;
}

interface PropertyDetail {
  id: number;
  name: string;
  path: string;
  street_address: string | null;
  city: string | null;
  state: string | null;
  zip: string | null;
  unit_count: number | null;
  property_management_org_id: number;
}

export default function EditProperty() {
  const { property, pm_organizations, can_change_org } = usePage<SharedProps & {
    property: PropertyDetail;
    pm_organizations: PmOrg[];
    can_change_org: boolean;
  }>().props;

  const { data, setData, patch, processing, errors } = useForm({
    name: property.name,
    property_management_org_id: String(property.property_management_org_id),
    street_address: property.street_address || "",
    city: property.city || "",
    state: property.state || "",
    zip: property.zip || "",
    unit_count: property.unit_count != null ? String(property.unit_count) : "",
  });

  function handleSubmit(e: FormEvent) {
    e.preventDefault();
    patch(property.path);
  }

  return (
    <AppLayout>
      <PageHeader title="Edit Property" backLink={{ href: property.path, label: property.name }} />

      <form onSubmit={handleSubmit} className="max-w-lg space-y-4">
        <FormField id="name" label="Name" value={data.name} onChange={(v) => setData("name", v)} error={errors.name} required />

        {can_change_org && (
          <div className="space-y-2">
            <label htmlFor="pm_org" className="text-sm font-medium">PM Organization *</label>
            <Select value={data.property_management_org_id} onValueChange={(v) => setData("property_management_org_id", v)}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {pm_organizations.map((org) => (
                  <SelectItem key={org.id} value={String(org.id)}>{org.name}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        )}

        <AddressFields data={data} setData={setData} />
        <FormField id="unit_count" label="Unit Count" type="number" value={data.unit_count} onChange={(v) => setData("unit_count", v)} />

        <div className="flex gap-3 pt-2">
          <Button variant="outline" asChild>
            <Link href={property.path}>Cancel</Link>
          </Button>
          <Button type="submit" disabled={processing}>
            {processing ? "Saving..." : "Save Changes"}
          </Button>
        </div>
      </form>
    </AppLayout>
  );
}
