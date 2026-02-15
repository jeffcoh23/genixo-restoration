import { Link, usePage } from "@inertiajs/react";
import AppLayout from "@/layout/AppLayout";
import { Button } from "@/components/ui/button";
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

export default function PropertiesIndex() {
  const { properties, can_create, routes } = usePage<SharedProps & {
    properties: Property[];
    can_create: boolean;
  }>().props;

  return (
    <AppLayout>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-semibold text-foreground">Properties</h1>
        {can_create && (
          <Button asChild>
            <Link href={routes.new_property}>New Property</Link>
          </Button>
        )}
      </div>

      {properties.length === 0 ? (
        <p className="text-muted-foreground">
          No properties yet.{can_create && ' Use "New Property" to add one.'}
        </p>
      ) : (
        <div className="rounded-md border">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b bg-muted/50">
                <th className="px-4 py-3 text-left font-medium">Name</th>
                <th className="px-4 py-3 text-left font-medium">Address</th>
                <th className="px-4 py-3 text-left font-medium">PM Organization</th>
                <th className="px-4 py-3 text-right font-medium">Active</th>
                <th className="px-4 py-3 text-right font-medium">Total</th>
              </tr>
            </thead>
            <tbody>
              {properties.map((p) => (
                <tr key={p.id} className="border-b last:border-0 hover:bg-muted/30">
                  <td className="px-4 py-3">
                    <Link href={p.path} className="font-medium text-primary hover:underline">
                      {p.name}
                    </Link>
                  </td>
                  <td className="px-4 py-3 text-muted-foreground">{p.address || "—"}</td>
                  <td className="px-4 py-3 text-muted-foreground">{p.pm_org_name}</td>
                  <td className="px-4 py-3 text-right">{p.active_incident_count}</td>
                  <td className="px-4 py-3 text-right">{p.total_incident_count}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </AppLayout>
  );
}
