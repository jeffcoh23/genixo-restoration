import { Link, router, usePage } from "@inertiajs/react";
import { AlertTriangle, Search, X, ChevronLeft, ChevronRight, ArrowUpDown, MessageSquare, Activity } from "lucide-react";
import { useState, useCallback, useMemo } from "react";
import AppLayout from "@/layout/AppLayout";
import PageHeader from "@/components/PageHeader";
import MultiFilterSelect from "@/components/MultiFilterSelect";
import StatusBadge from "@/components/StatusBadge";
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

const emergencyOptions = [
  { value: "1", label: "Emergency" },
  { value: "0", label: "Non-Emergency" },
];

function removeCsvValue(csv: string | null, value: string): string | null {
  if (!csv) return null;
  const values = csv.split(",").filter((v) => v !== value);
  return values.length > 0 ? values.join(",") : null;
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

  const activeFilterCount = [filters.search, filters.status, filters.property_id, filters.project_type, filters.emergency]
    .filter((value) => !!value).length;

  const filterChips = useMemo(() => {
    const chips: Array<{ key: string; label: string; onRemove: () => void }> = [];

    if (filters.search) {
      chips.push({
        key: `search-${filters.search}`,
        label: `Search: ${filters.search}`,
        onRemove: () => { setSearch(""); navigate({ search: null }); },
      });
    }

    if (filters.status) {
      filters.status.split(",").forEach((value) => {
        const label = filter_options.statuses.find((s) => s.value === value)?.label || value;
        chips.push({
          key: `status-${value}`,
          label: `Status: ${label}`,
          onRemove: () => navigate({ status: removeCsvValue(filters.status, value) }),
        });
      });
    }

    if (filters.property_id) {
      filters.property_id.split(",").forEach((value) => {
        const label = filter_options.properties.find((p) => String(p.id) === value)?.name || value;
        chips.push({
          key: `property-${value}`,
          label: `Property: ${label}`,
          onRemove: () => navigate({ property_id: removeCsvValue(filters.property_id, value) }),
        });
      });
    }

    if (filters.project_type) {
      filters.project_type.split(",").forEach((value) => {
        const label = filter_options.project_types.find((p) => p.value === value)?.label || value;
        chips.push({
          key: `project-${value}`,
          label: `Type: ${label}`,
          onRemove: () => navigate({ project_type: removeCsvValue(filters.project_type, value) }),
        });
      });
    }

    if (filters.emergency) {
      const label = emergencyOptions.find((e) => e.value === filters.emergency)?.label || filters.emergency;
      chips.push({
        key: `emergency-${filters.emergency}`,
        label,
        onRemove: () => navigate({ emergency: null }),
      });
    }

    return chips;
  }, [filters, filter_options, navigate]);

  return (
    <AppLayout wide>
      <PageHeader
        title="Incidents"
        action={can_create ? { href: routes.new_incident, label: "Create Request" } : undefined}
      />

      <div className="mb-4 rounded-lg border border-border bg-card p-3 shadow-sm">
        <div className="flex flex-col xl:flex-row xl:items-center gap-2">
          <form onSubmit={handleSearch} className="relative w-full sm:w-64 flex items-center">
            <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-muted-foreground" />
            <Input
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search incidents..."
              className="pl-8 pr-16 h-11 sm:h-8 text-sm"
            />
            <div className="absolute right-1 top-1/2 -translate-y-1/2 flex items-center gap-0.5">
              {search && (
                <Button
                  type="button"
                  variant="ghost"
                  size="sm"
                  className="h-8 w-8 sm:h-6 sm:w-6 p-0 text-muted-foreground hover:text-foreground"
                  onClick={() => { setSearch(""); navigate({ search: null }); }}
                  aria-label="Clear search"
                >
                  <X className="h-3.5 w-3.5" />
                </Button>
              )}
              <Button
                type="submit"
                variant="ghost"
                size="sm"
                className="h-8 w-8 sm:h-6 sm:w-6 p-0 text-muted-foreground hover:text-foreground"
                aria-label="Run search"
              >
                <Search className="h-3.5 w-3.5" />
              </Button>
            </div>
          </form>

          <div className="flex flex-wrap items-center gap-2">
            <MultiFilterSelect
              selected={filters.status ? filters.status.split(",") : []}
              onChange={(values) => navigate({ status: values.length ? values.join(",") : null })}
              allLabel="All Statuses"
              options={filter_options.statuses.map((s) => ({ value: s.value, label: s.label }))}
              width="150px"
            />

            <MultiFilterSelect
              selected={filters.property_id ? String(filters.property_id).split(",") : []}
              onChange={(values) => navigate({ property_id: values.length ? values.join(",") : null })}
              allLabel="All Properties"
              options={filter_options.properties.map((p) => ({ value: String(p.id), label: p.name }))}
              width="170px"
            />

            <MultiFilterSelect
              selected={filters.project_type ? filters.project_type.split(",") : []}
              onChange={(values) => navigate({ project_type: values.length ? values.join(",") : null })}
              allLabel="All Types"
              options={filter_options.project_types.map((t) => ({ value: t.value, label: t.label }))}
              width="140px"
            />

            <MultiFilterSelect
              selected={filters.emergency ? [filters.emergency] : []}
              onChange={(values) => navigate({ emergency: values.length ? values[values.length - 1] : null })}
              allLabel="All Emergencies"
              options={emergencyOptions}
              width="170px"
            />

            {activeFilterCount > 0 && (
              <Button
                variant="ghost"
                size="sm"
                className="h-11 sm:h-8 text-sm sm:text-xs"
                onClick={() => { setSearch(""); navigate({ search: null, status: null, property_id: null, project_type: null, emergency: null }); }}
              >
                Clear all
              </Button>
            )}
          </div>
        </div>

        {filterChips.length > 0 && (
          <div className="mt-3 flex flex-wrap gap-2">
            {filterChips.map((chip) => (
              <Button
                key={chip.key}
                variant="secondary"
                size="sm"
                className="h-8 text-xs gap-1"
                onClick={chip.onRemove}
              >
                {chip.label}
                <X className="h-3 w-3" />
              </Button>
            ))}
          </div>
        )}
      </div>

      {incidents.length === 0 ? (
        <div className="rounded-lg border border-border bg-card shadow-sm p-8 text-center">
          <p className="text-muted-foreground">No incidents match your filters.</p>
        </div>
      ) : (
        <>
          <div className="md:hidden space-y-3">
            {incidents.map((incident) => {
              const showEmergency = incident.emergency && (incident.status === "new" || incident.status === "acknowledged");
              return (
                <div key={incident.id} className={`rounded-lg border border-border bg-card p-4 shadow-sm ${showEmergency ? "ring-1 ring-status-emergency/40" : ""}`}>
                  <div className="flex items-start justify-between gap-2">
                    <Link href={incident.path} className="font-semibold text-foreground hover:text-primary transition-colors">
                      {incident.property_name}
                    </Link>
                    <StatusBadge status={incident.status} label={incident.status_label} />
                  </div>
                  <p className="mt-2 text-sm text-muted-foreground line-clamp-2">{incident.description}</p>
                  <div className="mt-3 flex flex-wrap items-center gap-2 text-xs">
                    {showEmergency && (
                      <span className="inline-flex items-center gap-1 rounded-full bg-status-emergency/15 px-2 py-0.5 font-semibold text-status-emergency">
                        <AlertTriangle className="h-3 w-3" />
                        Emergency
                      </span>
                    )}
                    {incident.unread_messages > 0 && (
                      <span className="inline-flex items-center gap-1 rounded-full bg-accent px-2 py-0.5 font-medium text-foreground">
                        <MessageSquare className="h-3 w-3" />
                        Msgs {incident.unread_messages}
                      </span>
                    )}
                    {incident.unread_activity > 0 && (
                      <span className="inline-flex items-center gap-1 rounded-full bg-status-warning/20 px-2 py-0.5 font-medium text-foreground">
                        <Activity className="h-3 w-3" />
                        Activity {incident.unread_activity}
                      </span>
                    )}
                  </div>
                  <div className="mt-3 flex items-center justify-between text-xs text-muted-foreground">
                    <span>{incident.project_type_label}</span>
                    <span>{incident.last_activity_label || "No activity yet"}</span>
                  </div>
                </div>
              );
            })}
          </div>

          <div className="hidden md:block rounded-lg border border-border bg-card shadow-sm overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-sm min-w-[960px]">
                <thead>
                  <tr className="border-b bg-muted/70">
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
                        className={`border-b last:border-0 hover:bg-muted/35 transition-colors ${
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
                        <td className="px-4 py-3 text-muted-foreground max-w-[320px] truncate">
                          {incident.description}
                        </td>
                        <td className="px-4 py-3">
                          <StatusBadge status={incident.status} label={incident.status_label} />
                        </td>
                        <td className="px-4 py-3 text-muted-foreground">
                          {incident.project_type_label}
                        </td>
                        <td className="px-4 py-3 text-right">
                          <div className="flex items-center justify-end gap-2">
                            {incident.unread_messages > 0 && (
                              <span className="inline-flex items-center gap-1 rounded-full bg-accent px-2 py-0.5 text-xs font-medium text-foreground">
                                <MessageSquare className="h-3 w-3" />
                                Msgs {incident.unread_messages}
                              </span>
                            )}
                            {incident.unread_activity > 0 && (
                              <span className="inline-flex items-center gap-1 rounded-full bg-status-warning/20 px-2 py-0.5 text-xs font-medium text-foreground">
                                <Activity className="h-3 w-3" />
                                Activity {incident.unread_activity}
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
          </div>
        </>
      )}

      {pagination.total_pages > 1 && (
        <div className="flex items-center justify-between mt-4 text-sm text-muted-foreground">
          <span>
            Page {pagination.page} of {pagination.total_pages} ({pagination.total} incidents)
          </span>
          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="sm"
              className="h-10 sm:h-8"
              disabled={pagination.page <= 1}
              onClick={() => navigate({ page: pagination.page - 1 })}
            >
              <ChevronLeft className="h-4 w-4" />
            </Button>
            <Button
              variant="outline"
              size="sm"
              className="h-10 sm:h-8"
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
