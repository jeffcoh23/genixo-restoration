import { Link, usePage } from "@inertiajs/react";
import AppLayout from "@/layout/AppLayout";
import { Button } from "@/components/ui/button";
import { SharedProps } from "@/types";

interface Organization {
  id: number;
  name: string;
  phone: string | null;
  email: string | null;
  property_count: number;
  user_count: number;
}

export default function OrganizationsIndex() {
  const { organizations, routes } = usePage<SharedProps & { organizations: Organization[] }>().props;

  return (
    <AppLayout>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-semibold text-foreground">Organizations</h1>
        <Button asChild>
          <Link href={routes.new_organization}>New Organization</Link>
        </Button>
      </div>

      {organizations.length === 0 ? (
        <p className="text-muted-foreground">
          No property management companies yet. Use "New Organization" to add one.
        </p>
      ) : (
        <div className="rounded-md border">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b bg-muted/50">
                <th className="px-4 py-3 text-left font-medium">Name</th>
                <th className="px-4 py-3 text-left font-medium">Phone</th>
                <th className="px-4 py-3 text-left font-medium">Email</th>
                <th className="px-4 py-3 text-right font-medium">Properties</th>
                <th className="px-4 py-3 text-right font-medium">Users</th>
              </tr>
            </thead>
            <tbody>
              {organizations.map((org) => (
                <tr key={org.id} className="border-b last:border-0 hover:bg-muted/30">
                  <td className="px-4 py-3">
                    <Link
                      href={`/organizations/${org.id}`}
                      className="font-medium text-primary hover:underline"
                    >
                      {org.name}
                    </Link>
                  </td>
                  <td className="px-4 py-3 text-muted-foreground">{org.phone || "—"}</td>
                  <td className="px-4 py-3 text-muted-foreground">{org.email || "—"}</td>
                  <td className="px-4 py-3 text-right">{org.property_count}</td>
                  <td className="px-4 py-3 text-right">{org.user_count}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </AppLayout>
  );
}
