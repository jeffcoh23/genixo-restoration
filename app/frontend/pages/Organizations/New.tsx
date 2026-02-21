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

      <form onSubmit={handleSubmit} className="max-w-3xl">
        <div className="rounded-lg border border-border bg-card shadow-sm overflow-hidden">
          <div className="px-6 py-4 border-b border-border bg-muted/30">
            <h2 className="text-base font-semibold text-foreground">Company Details</h2>
            <p className="text-sm text-muted-foreground mt-1">
              Add contact and address information for the property management company.
            </p>
          </div>

          <div className="p-6 space-y-5">
            <FormField id="name" label="Name" value={data.name} onChange={(v) => setData("name", v)} error={errors.name} required />

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <FormField id="phone" label="Phone" value={data.phone} onChange={(v) => setData("phone", v)} />
              <FormField id="email" label="Email" type="email" value={data.email} onChange={(v) => setData("email", v)} />
            </div>

            <AddressFields data={data} setData={setData} />
          </div>

          <div className="px-6 py-4 border-t border-border bg-muted/20 flex gap-3 justify-end">
            <Button variant="outline" asChild>
              <Link href={routes.organizations}>Cancel</Link>
            </Button>
            <Button type="submit" disabled={processing}>
              {processing ? "Creating..." : "Create Company"}
            </Button>
          </div>
        </div>
      </form>
    </AppLayout>
  );
}
