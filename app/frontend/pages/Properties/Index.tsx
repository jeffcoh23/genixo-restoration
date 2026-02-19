import { useState } from "react";
import { Link, usePage } from "@inertiajs/react";
import { ArrowDown, ArrowUp, ArrowUpDown } from "lucide-react";
import AppLayout from "@/layout/AppLayout";
import PageHeader from "@/components/PageHeader";
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

type SortKey = "name" | "address" | "pm_org_name" | "active_incident_count" | "total_incident_count";
type SortDir = "asc" | "desc";

function sortProperties(properties: Property[], key: SortKey, dir: SortDir): Property[] {
  return [...properties].sort((a, b) => {
    const aVal = a[key];
    const bVal = b[key];
    if (typeof aVal === "number" && typeof bVal === "number") {
      return dir === "asc" ? aVal - bVal : bVal - aVal;
    }
    const aStr = String(aVal ?? "").toLowerCase();
    const bStr = String(bVal ?? "").toLowerCase();
    return dir === "asc" ? aStr.localeCompare(bStr) : bStr.localeCompare(aStr);
  });
}

const COLUMNS: { key: SortKey; header: string; align?: "right" }[] = [
  { key: "name", header: "Name" },
  { key: "address", header: "Address" },
  { key: "pm_org_name", header: "PM Organization" },
  { key: "active_incident_count", header: "Active", align: "right" },
  { key: "total_incident_count", header: "Total", align: "right" },
];

export default function PropertiesIndex() {
  const { properties, can_create, routes } = usePage<SharedProps & {
    properties: Property[];
    can_create: boolean;
  }>().props;

  const [sortKey, setSortKey] = useState<SortKey>("name");
  const [sortDir, setSortDir] = useState<SortDir>("asc");

  const handleSort = (key: SortKey) => {
    if (sortKey === key) {
      setSortDir(sortDir === "asc" ? "desc" : "asc");
    } else {
      setSortKey(key);
      setSortDir("asc");
    }
  };

  const sorted = sortProperties(properties, sortKey, sortDir);

  return (
    <AppLayout wide>
      <PageHeader
        title="Properties"
        action={can_create ? { href: routes.new_property, label: "New Property" } : undefined}
      />
      {sorted.length === 0 ? (
        <p className="text-muted-foreground">
          {can_create ? 'No properties yet. Use "New Property" to add one.' : "No properties yet."}
        </p>
      ) : (
        <div className="rounded border">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b bg-muted">
                {COLUMNS.map((col) => (
                  <th
                    key={col.key}
                    className={`px-4 py-3 font-medium ${col.align === "right" ? "text-right" : "text-left"}`}
                  >
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => handleSort(col.key)}
                      className={`h-auto p-0 font-medium hover:text-foreground ${col.align === "right" ? "ml-auto" : ""}`}
                    >
                      {col.header}
                      {sortKey === col.key ? (
                        sortDir === "asc" ? (
                          <ArrowUp className="ml-1 h-3 w-3" />
                        ) : (
                          <ArrowDown className="ml-1 h-3 w-3" />
                        )
                      ) : (
                        <ArrowUpDown className="ml-1 h-3 w-3 text-muted-foreground" />
                      )}
                    </Button>
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {sorted.map((p) => (
                <tr key={p.id} className="border-b last:border-0 hover:bg-muted">
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
