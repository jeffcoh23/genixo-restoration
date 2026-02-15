import { Link, useForm, usePage } from "@inertiajs/react";
import { FormEvent } from "react";
import AppLayout from "@/layout/AppLayout";
import PageHeader from "@/components/PageHeader";
import FormField from "@/components/FormField";
import AddressFields from "@/components/AddressFields";
import { Button } from "@/components/ui/button";
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
      <PageHeader title="Edit Organization" backLink={{ href: organization.path, label: organization.name }} />

      <form onSubmit={handleSubmit} className="max-w-lg space-y-4">
        <FormField id="name" label="Name" value={data.name} onChange={(v) => setData("name", v)} error={errors.name} required />

        <div className="grid grid-cols-2 gap-4">
          <FormField id="phone" label="Phone" value={data.phone} onChange={(v) => setData("phone", v)} />
          <FormField id="email" label="Email" type="email" value={data.email} onChange={(v) => setData("email", v)} />
        </div>

        <AddressFields data={data} setData={setData} />

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
