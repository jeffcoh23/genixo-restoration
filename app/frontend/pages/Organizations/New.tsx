import { Link, useForm, usePage } from "@inertiajs/react";
import { FormEvent } from "react";
import AppLayout from "@/layout/AppLayout";
import PageHeader from "@/components/PageHeader";
import FormField from "@/components/FormField";
import AddressFields from "@/components/AddressFields";
import { Button } from "@/components/ui/button";
import { SharedProps } from "@/types";

export default function NewOrganization() {
  const { routes } = usePage<SharedProps>().props;
  const { data, setData, post, processing, errors } = useForm({
    name: "",
    phone: "",
    email: "",
    street_address: "",
    city: "",
    state: "",
    zip: "",
  });

  function handleSubmit(e: FormEvent) {
    e.preventDefault();
    post(routes.organizations);
  }

  return (
    <AppLayout>
      <PageHeader title="New Company" backLink={{ href: routes.organizations, label: "Property Management" }} />

      <form onSubmit={handleSubmit} className="max-w-lg space-y-4">
        <FormField id="name" label="Name" value={data.name} onChange={(v) => setData("name", v)} error={errors.name} required />

        <div className="grid grid-cols-2 gap-4">
          <FormField id="phone" label="Phone" value={data.phone} onChange={(v) => setData("phone", v)} />
          <FormField id="email" label="Email" type="email" value={data.email} onChange={(v) => setData("email", v)} />
        </div>

        <AddressFields data={data} setData={setData} />

        <div className="flex gap-3 pt-2">
          <Button variant="outline" asChild>
            <Link href={routes.organizations}>Cancel</Link>
          </Button>
          <Button type="submit" disabled={processing}>
            {processing ? "Creating..." : "Create Company"}
          </Button>
        </div>
      </form>
    </AppLayout>
  );
}
