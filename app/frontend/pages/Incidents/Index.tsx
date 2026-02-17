import { Link, router, usePage } from "@inertiajs/react";
import { AlertTriangle, Search, ChevronLeft, ChevronRight, ArrowUpDown } from "lucide-react";
import { useState, useCallback } from "react";
import AppLayout from "@/layout/AppLayout";
import PageHeader from "@/components/PageHeader";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { SharedProps } from "@/types";

interface Incident {
  id: number;
  path: string;
  property_name: string;
  description: string;
  status: string;
  status_label: string;
  project_type: string;
  project_type_label: string;
  damage_label: string;
  emergency: boolean;
  last_activity_at: string | null;
  created_at: string;
}

interface Pagination {
  page: number;
  per_page: number;
  total: number;
  total_pages: number;
}

interface Filters {
  search: string | null;
  status: string | null;
  property_id: number | null;
  project_type: string | null;
  emergency: string | null;
}

interface Sort {
  column: string;
  direction: string;
}

interface FilterOption {
  value: string;
  label: string;
}

interface PropertyOption {
  id: number;
  name: string;
}

interface FilterOptions {
  statuses: FilterOption[];
  project_types: FilterOption[];
  properties: PropertyOption[];
}

interface IncidentsIndexProps {
  incidents: Incident[];
  pagination: Pagination;
  filters: Filters;
  sort: Sort;
  filter_options: FilterOptions;
  can_create: boolean;
}

function statusColor(status: string): string {
  switch (status) {
    case "new":
    case "acknowledged":
      return "bg-[hsl(199_89%_48%)] text-white";
    case "quote_requested":
      return "bg-[hsl(270_50%_60%)] text-white";
    case "active":
      return "bg-[hsl(142_76%_36%)] text-white";
    case "on_hold":
      return "bg-[hsl(38_92%_50%)] text-white";
    case "completed":
      return "bg-[hsl(142_40%_50%)] text-white";
    default:
      return "bg-[hsl(0_0%_55%)] text-white";
  }
}

function timeAgo(iso: string | null): string {
  if (!iso) return "";
  const seconds = Math.floor((Date.now() - new Date(iso).getTime()) / 1000);
  if (seconds < 60) return "just now";
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes}m`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h`;
  const days = Math.floor(hours / 24);
  return `${days}d`;
}

export default function IncidentsIndex() {
  const { incidents, pagination, filters, sort, filter_options, can_create, routes } =
    usePage<SharedProps & IncidentsIndexProps>().props;

  const [search, setSearch] = useState(filters.search || "");

  const navigate = useCallback(
    (params: Record<string, string | number | null | undefined>) => {
      const current: Record<string, string> = {};
      if (filters.search) current.search = filters.search;
      if (filters.status) current.status = filters.status;
      if (filters.property_id) current.property_id = String(filters.property_id);
      if (filters.project_type) current.project_type = filters.project_type;
      if (filters.emergency) current.emergency = filters.emergency;
      if (sort.column !== "created_at") current.sort = sort.column;
      if (sort.direction !== "desc") current.direction = sort.direction;

      const merged = { ...current, ...params };
      // Remove null/empty values
      Object.keys(merged).forEach((k) => {
        if (!merged[k] || merged[k] === "") delete merged[k];
      });
      // Reset to page 1 on filter change unless explicitly navigating pages
      if (!params.page) delete merged.page;

      router.get(routes.incidents, merged, { preserveState: true, preserveScroll: true });
    },
    [filters, sort, routes]
  );

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    navigate({ search: search || null });
  };

  const handleSort = (column: string) => {
    const newDir = sort.column === column && sort.direction === "desc" ? "asc" : "desc";
    navigate({ sort: column, direction: newDir });
  };

  return (
    <AppLayout>
      <PageHeader
        title="Incidents"
        action={can_create ? { href: routes.new_incident, label: "Create Request" } : undefined}
      />

      {/* Filters */}
      <div className="flex flex-wrap items-center gap-3 mb-4">
        <form onSubmit={handleSearch} className="relative flex-1 min-w-[200px] max-w-sm">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search..."
            className="pl-9"
          />
        </form>

        <FilterSelect
          value={filters.status || ""}
          onChange={(v) => navigate({ status: v || null })}
          placeholder="Status"
          options={filter_options.statuses.map((s) => ({ value: s.value, label: s.label }))}
        />

        <FilterSelect
          value={filters.property_id ? String(filters.property_id) : ""}
          onChange={(v) => navigate({ property_id: v || null })}
          placeholder="Property"
          options={filter_options.properties.map((p) => ({ value: String(p.id), label: p.name }))}
        />

        <FilterSelect
          value={filters.project_type || ""}
          onChange={(v) => navigate({ project_type: v || null })}
          placeholder="Type"
          options={filter_options.project_types.map((t) => ({ value: t.value, label: t.label }))}
        />

        <FilterSelect
          value={filters.emergency || ""}
          onChange={(v) => navigate({ emergency: v || null })}
          placeholder="Emergency"
          options={[{ value: "1", label: "Emergency Only" }]}
        />
      </div>

      {/* Table */}
      {incidents.length === 0 ? (
        <div className="rounded-md border border-border bg-card p-8 text-center">
          <p className="text-muted-foreground">No incidents match your filters.</p>
        </div>
      ) : (
        <div className="rounded-md border border-border overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b bg-muted/50">
                <SortHeader label="Property" column="property" sort={sort} onSort={handleSort} />
                <th className="px-4 py-3 font-medium text-left">Description</th>
                <SortHeader label="Status" column="status" sort={sort} onSort={handleSort} />
                <th className="px-4 py-3 font-medium text-left">Type</th>
                <SortHeader label="Activity" column="last_activity_at" sort={sort} onSort={handleSort} align="right" />
              </tr>
            </thead>
            <tbody>
              {incidents.map((incident) => (
                <tr
                  key={incident.id}
                  className={`border-b last:border-0 hover:bg-muted/30 transition-colors ${
                    incident.emergency ? "bg-red-50" : ""
                  }`}
                >
                  <td className="px-4 py-3">
                    <Link href={incident.path} className="font-medium text-primary hover:underline flex items-center gap-1.5">
                      {incident.emergency && (
                        <AlertTriangle className="h-3.5 w-3.5 text-destructive flex-shrink-0" />
                      )}
                      {incident.property_name}
                    </Link>
                  </td>
                  <td className="px-4 py-3 text-muted-foreground max-w-[300px] truncate">
                    {incident.description}
                  </td>
                  <td className="px-4 py-3">
                    <Badge className={`text-xs ${statusColor(incident.status)}`}>
                      {incident.status_label}
                    </Badge>
                  </td>
                  <td className="px-4 py-3 text-muted-foreground">
                    {incident.project_type_label}
                  </td>
                  <td className="px-4 py-3 text-right text-muted-foreground">
                    {timeAgo(incident.last_activity_at)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Pagination */}
      {pagination.total_pages > 1 && (
        <div className="flex items-center justify-between mt-4 text-sm text-muted-foreground">
          <span>
            Page {pagination.page} of {pagination.total_pages} ({pagination.total} incidents)
          </span>
          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="sm"
              disabled={pagination.page <= 1}
              onClick={() => navigate({ page: pagination.page - 1 })}
            >
              <ChevronLeft className="h-4 w-4" />
            </Button>
            <Button
              variant="outline"
              size="sm"
              disabled={pagination.page >= pagination.total_pages}
              onClick={() => navigate({ page: pagination.page + 1 })}
            >
              <ChevronRight className="h-4 w-4" />
            </Button>
          </div>
        </div>
      )}
    </AppLayout>
  );
}

function FilterSelect({
  value,
  onChange,
  placeholder,
  options,
}: {
  value: string;
  onChange: (value: string) => void;
  placeholder: string;
  options: { value: string; label: string }[];
}) {
  return (
    <select
      value={value}
      onChange={(e) => onChange(e.target.value)}
      className="h-9 rounded-md border border-input bg-background px-3 text-sm text-foreground focus:outline-none focus:ring-1 focus:ring-ring"
    >
      <option value="">{placeholder}</option>
      {options.map((opt) => (
        <option key={opt.value} value={opt.value}>
          {opt.label}
        </option>
      ))}
    </select>
  );
}

function SortHeader({
  label,
  column,
  sort,
  onSort,
  align,
}: {
  label: string;
  column: string;
  sort: Sort;
  onSort: (column: string) => void;
  align?: "left" | "right";
}) {
  const active = sort.column === column;
  return (
    <th className={`px-4 py-3 font-medium ${align === "right" ? "text-right" : "text-left"}`}>
      <button
        onClick={() => onSort(column)}
        className={`inline-flex items-center gap-1 hover:text-foreground transition-colors ${
          active ? "text-foreground" : "text-muted-foreground"
        }`}
      >
        {label}
        <ArrowUpDown className="h-3.5 w-3.5" />
      </button>
    </th>
  );
}
