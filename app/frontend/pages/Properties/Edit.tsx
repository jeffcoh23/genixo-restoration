import { Link, useForm, usePage } from "@inertiajs/react";
import { FormEvent } from "react";
import AppLayout from "@/layout/AppLayout";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
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
      <div className="mb-6">
        <Link href={property.path} className="text-sm text-muted-foreground hover:text-foreground">
          &larr; {property.name}
        </Link>
      </div>

      <h1 className="text-2xl font-semibold text-foreground mb-6">Edit Property</h1>

      <form onSubmit={handleSubmit} className="max-w-lg space-y-4">
        <div className="space-y-2">
          <Label htmlFor="name">Name *</Label>
          <Input id="name" value={data.name} onChange={(e) => setData("name", e.target.value)} />
          {errors.name && <p className="text-sm text-destructive">{errors.name}</p>}
        </div>

        {can_change_org && (
          <div className="space-y-2">
            <Label htmlFor="pm_org">PM Organization *</Label>
            <select
              id="pm_org"
              value={data.property_management_org_id}
              onChange={(e) => setData("property_management_org_id", e.target.value)}
              className="flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-xs transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
            >
              {pm_organizations.map((org) => (
                <option key={org.id} value={org.id}>{org.name}</option>
              ))}
            </select>
          </div>
        )}

        <div className="space-y-2">
          <Label htmlFor="street_address">Street Address</Label>
          <Input id="street_address" value={data.street_address} onChange={(e) => setData("street_address", e.target.value)} />
        </div>

        <div className="grid grid-cols-3 gap-4">
          <div className="space-y-2">
            <Label htmlFor="city">City</Label>
            <Input id="city" value={data.city} onChange={(e) => setData("city", e.target.value)} />
          </div>
          <div className="space-y-2">
            <Label htmlFor="state">State</Label>
            <Input id="state" value={data.state} onChange={(e) => setData("state", e.target.value)} />
          </div>
          <div className="space-y-2">
            <Label htmlFor="zip">Zip</Label>
            <Input id="zip" value={data.zip} onChange={(e) => setData("zip", e.target.value)} />
          </div>
        </div>

        <div className="space-y-2">
          <Label htmlFor="unit_count">Unit Count</Label>
          <Input id="unit_count" type="number" value={data.unit_count} onChange={(e) => setData("unit_count", e.target.value)} />
        </div>

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
