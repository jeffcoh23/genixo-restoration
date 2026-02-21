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

      <form onSubmit={handleSubmit} className="max-w-3xl">
        <div className="rounded-lg border border-border bg-card shadow-sm overflow-hidden">
          <div className="px-6 py-4 border-b border-border bg-muted/30">
            <h2 className="text-base font-semibold text-foreground">Property Details</h2>
            <p className="text-sm text-muted-foreground mt-1">
              Add the core location and management information for this property.
            </p>
          </div>

          <div className="p-6 space-y-5">
            <FormField id="name" label="Name" value={data.name} onChange={(v) => setData("name", v)} error={errors.name} required />

            <div className="space-y-2">
              <label htmlFor="pm_org" className="text-sm font-medium">PM Organization *</label>
              <Select value={data.property_management_org_id} onValueChange={(value) => setData("property_management_org_id", value)}>
                <SelectTrigger id="pm_org" className="h-11 sm:h-10">
                  <SelectValue placeholder="Select an organization..." />
                </SelectTrigger>
                <SelectContent>
                  {pm_organizations.map((org) => (
                    <SelectItem key={org.id} value={String(org.id)}>
                      {org.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              {errors.property_management_org_id && (
                <p className="text-sm text-destructive">{errors.property_management_org_id}</p>
              )}
            </div>

            <AddressFields data={data} setData={setData} />
            <FormField id="unit_count" label="Unit Count" type="number" value={data.unit_count} onChange={(v) => setData("unit_count", v)} />
          </div>

          <div className="px-6 py-4 border-t border-border bg-muted/20 flex gap-3 justify-end">
            <Button variant="outline" asChild>
              <Link href={routes.properties}>Cancel</Link>
            </Button>
            <Button type="submit" disabled={processing}>
              {processing ? "Creating..." : "Create Property"}
            </Button>
          </div>
        </div>
      </form>
    </AppLayout>
  );
}
