import { Link, useForm, usePage } from "@inertiajs/react";
import { FormEvent } from "react";
import AppLayout from "@/layout/AppLayout";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { SharedProps } from "@/types";

interface OrganizationProps {
  id: number;
  name: string;
  path: string;
  phone: string | null;
  email: string | null;
  street_address: string | null;
  city: string | null;
  state: string | null;
  zip: string | null;
}

export default function EditOrganization() {
  const { organization } = usePage<SharedProps & { organization: OrganizationProps }>().props;
  const { data, setData, patch, processing, errors } = useForm({
    name: organization.name,
    phone: organization.phone || "",
    email: organization.email || "",
    street_address: organization.street_address || "",
    city: organization.city || "",
    state: organization.state || "",
    zip: organization.zip || "",
  });

  function handleSubmit(e: FormEvent) {
    e.preventDefault();
    patch(organization.path);
  }

  return (
    <AppLayout>
      <div className="mb-6">
        <Link href={organization.path} className="text-sm text-muted-foreground hover:text-foreground">
          &larr; {organization.name}
        </Link>
      </div>

      <h1 className="text-2xl font-semibold text-foreground mb-6">Edit Organization</h1>

      <form onSubmit={handleSubmit} className="max-w-lg space-y-4">
        <div className="space-y-2">
          <Label htmlFor="name">Name *</Label>
          <Input id="name" value={data.name} onChange={(e) => setData("name", e.target.value)} />
          {errors.name && <p className="text-sm text-destructive">{errors.name}</p>}
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div className="space-y-2">
            <Label htmlFor="phone">Phone</Label>
            <Input id="phone" value={data.phone} onChange={(e) => setData("phone", e.target.value)} />
          </div>
          <div className="space-y-2">
            <Label htmlFor="email">Email</Label>
            <Input id="email" type="email" value={data.email} onChange={(e) => setData("email", e.target.value)} />
          </div>
        </div>

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

        <div className="flex gap-3 pt-2">
          <Button variant="outline" asChild>
            <Link href={organization.path}>Cancel</Link>
          </Button>
          <Button type="submit" disabled={processing}>
            {processing ? "Saving..." : "Save Changes"}
          </Button>
        </div>
      </form>
    </AppLayout>
  );
}
