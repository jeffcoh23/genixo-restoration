import { Link, router, usePage } from "@inertiajs/react";
import { AlertTriangle, Search, X, ChevronLeft, ChevronRight, ArrowUpDown, MessageSquare, Activity } from "lucide-react";
import { useState, useCallback } from "react";
import AppLayout from "@/layout/AppLayout";
import PageHeader from "@/components/PageHeader";
import MultiFilterSelect from "@/components/MultiFilterSelect";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { SharedProps } from "@/types";
import { statusColor } from "@/lib/statusColor";

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
  last_activity_label: string | null;
  created_at: string;
  unread_messages: number;
  unread_activity: number;
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
  property_id: string | null;
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

export default function IncidentsIndex() {
  const { incidents, pagination, filters, sort, filter_options, can_create, routes } =
    usePage<SharedProps & IncidentsIndexProps>().props;

  const [search, setSearch] = useState(filters.search || "");

  const navigate = useCallback(
    (params: Record<string, string | number | null | undefined>) => {
      const current: Record<string, string> = {};
      if (filters.search) current.search = filters.search;
      if (filters.status) current.status = filters.status;
      if (filters.property_id) current.property_id = filters.property_id;
      if (filters.project_type) current.project_type = filters.project_type;
      if (filters.emergency) current.emergency = filters.emergency;
      if (sort.column !== "created_at") current.sort = sort.column;
      if (sort.direction !== "desc") current.direction = sort.direction;

      const merged = { ...current, ...params };
      Object.keys(merged).forEach((k) => {
        if (!merged[k] || merged[k] === "") delete merged[k];
      });
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
    <AppLayout wide>
      <PageHeader
        title="Incidents"
        action={can_create ? { href: routes.new_incident, label: "Create Request" } : undefined}
      />

      {/* Filters */}
      <div className="flex flex-wrap items-center gap-2 mb-4">
        <form onSubmit={handleSearch} className="relative w-52 flex items-center">
          <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-muted-foreground" />
          <Input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search..."
            className="pl-8 pr-16 h-8 text-sm"
          />
          <div className="absolute right-1 top-1/2 -translate-y-1/2 flex items-center gap-0.5">
            {search && (
              <Button
                type="button"
                variant="ghost"
                size="sm"
                className="h-6 w-6 p-0 text-muted-foreground hover:text-foreground"
                onClick={() => { setSearch(""); navigate({ search: null }); }}
              >
                <X className="h-3.5 w-3.5" />
              </Button>
            )}
            <Button
              type="submit"
              variant="ghost"
              size="sm"
              className="h-6 w-6 p-0 text-muted-foreground hover:text-foreground"
            >
              <Search className="h-3.5 w-3.5" />
            </Button>
          </div>
        </form>

        <MultiFilterSelect
          selected={filters.status ? filters.status.split(",") : []}
          onChange={(values) => navigate({ status: values.length ? values.join(",") : null })}
          allLabel="All Statuses"
          options={filter_options.statuses.map((s) => ({ value: s.value, label: s.label }))}
          width="140px"
        />

        <MultiFilterSelect
          selected={filters.property_id ? String(filters.property_id).split(",") : []}
          onChange={(values) => navigate({ property_id: values.length ? values.join(",") : null })}
          allLabel="All Properties"
          options={filter_options.properties.map((p) => ({ value: String(p.id), label: p.name }))}
          width="150px"
        />

        <MultiFilterSelect
          selected={filters.project_type ? filters.project_type.split(",") : []}
          onChange={(values) => navigate({ project_type: values.length ? values.join(",") : null })}
          allLabel="All Types"
          options={filter_options.project_types.map((t) => ({ value: t.value, label: t.label }))}
          width="120px"
        />

        <MultiFilterSelect
          selected={filters.emergency ? [filters.emergency] : []}
          onChange={(values) => navigate({ emergency: values.length ? values[values.length - 1] : null })}
          allLabel="All Emergencies"
          options={[
            { value: "1", label: "Emergency" },
            { value: "0", label: "Non-Emergency" },
          ]}
          width="155px"
        />
      </div>

      {/* Table */}
      {incidents.length === 0 ? (
        <div className="rounded-lg border border-border bg-card shadow-sm p-8 text-center">
          <p className="text-muted-foreground">No incidents match your filters.</p>
        </div>
      ) : (
        <div className="rounded-lg border border-border bg-card shadow-sm overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b bg-muted">
                <SortHeader label="Property" column="property" sort={sort} onSort={handleSort} />
                <th className="px-4 py-3 font-medium text-left">Description</th>
                <SortHeader label="Status" column="status" sort={sort} onSort={handleSort} />
                <th className="px-4 py-3 font-medium text-left">Type</th>
                <SortHeader label="Activity" column="last_activity_at" sort={sort} onSort={handleSort} align="right" />
              </tr>
            </thead>
            <tbody>
              {incidents.map((incident) => {
                const showEmergency = incident.emergency && (incident.status === "new" || incident.status === "acknowledged");
                return (
                <tr
                  key={incident.id}
                  className={`border-b last:border-0 hover:bg-muted transition-colors ${
                    showEmergency ? "bg-status-emergency/10" : ""
                  }`}
                >
                  <td className="px-4 py-3">
                    <Link href={incident.path} className="font-medium text-primary hover:underline flex items-center gap-1.5">
                      {showEmergency && (
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
                  <td className="px-4 py-3 text-right">
                    <div className="flex items-center justify-end gap-2">
                      {incident.unread_messages > 0 && (
                        <span className="inline-flex items-center gap-0.5 text-xs font-medium text-status-info">
                          <MessageSquare className="h-3 w-3" />
                          {incident.unread_messages}
                        </span>
                      )}
                      {incident.unread_activity > 0 && (
                        <span className="inline-flex items-center gap-0.5 text-xs font-medium text-status-warning">
                          <Activity className="h-3 w-3" />
                          {incident.unread_activity}
                        </span>
                      )}
                      <span className="text-muted-foreground">{incident.last_activity_label}</span>
                    </div>
                  </td>
                </tr>
                );
              })}
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
      <Button
        variant="ghost"
        size="sm"
        onClick={() => onSort(column)}
        className={`inline-flex items-center gap-1 hover:text-foreground h-auto p-0 ${
          active ? "text-foreground" : "text-muted-foreground"
        }`}
      >
        {label}
        <ArrowUpDown className="h-3.5 w-3.5" />
      </Button>
    </th>
  );
}
