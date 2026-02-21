import { Link, router, usePage } from "@inertiajs/react";
import { AlertTriangle, Search, X, ChevronLeft, ChevronRight, ArrowUpDown, MessageSquare, Activity, Inbox } from "lucide-react";
import { useState, useCallback } from "react";
import AppLayout from "@/layout/AppLayout";
import PageHeader from "@/components/PageHeader";
import MultiFilterSelect from "@/components/MultiFilterSelect";
import EmptyState from "@/components/EmptyState";
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
      <div className="flex flex-wrap items-center gap-2 mb-3">
        <form onSubmit={handleSearch} className="relative w-52 flex items-center">
          <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-muted-foreground" />
          <Input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search..."
            className="pl-8 pr-16 h-10 sm:h-8 text-sm"
          />
          <div className="absolute right-1 top-1/2 -translate-y-1/2 flex items-center gap-0.5">
            {search && (
              <Button
                type="button"
                variant="ghost"
                size="sm"
                className="h-8 w-8 sm:h-6 sm:w-6 p-0 text-muted-foreground hover:text-foreground"
                onClick={() => { setSearch(""); navigate({ search: null }); }}
              >
                <X className="h-3.5 w-3.5" />
              </Button>
            )}
            <Button
              type="submit"
              variant="ghost"
              size="sm"
              className="h-8 w-8 sm:h-6 sm:w-6 p-0 text-muted-foreground hover:text-foreground"
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

      {/* Active filter chips */}
      <ActiveFilterChips filters={filters} filterOptions={filter_options} navigate={navigate} onClearSearch={() => setSearch("")} />

      {/* Results */}
      {incidents.length === 0 ? (
        <div className="rounded-lg border border-border bg-card shadow-sm">
          <EmptyState
            icon={<Inbox className="h-8 w-8" />}
            title="No incidents match your filters"
            description="Try adjusting your search or filter criteria."
          />
        </div>
      ) : (
        <>
          {/* Mobile card list */}
          <div className="sm:hidden space-y-2">
            {incidents.map((incident) => {
              const showEmergency = incident.emergency && (incident.status === "new" || incident.status === "acknowledged");
              return (
                <Link
                  key={incident.id}
                  href={incident.path}
                  className={`block rounded-lg border border-border bg-card shadow-sm px-4 py-3 hover:bg-muted transition-colors ${
                    showEmergency ? "border-l-4 border-l-destructive" : ""
                  }`}
                >
                  <div className="flex items-start justify-between gap-2">
                    <div className="min-w-0 flex-1">
                      <span className="font-medium text-foreground flex items-center gap-1.5">
                        {showEmergency && <AlertTriangle className="h-3.5 w-3.5 text-destructive shrink-0" />}
                        {incident.property_name}
                      </span>
                      <p className="text-sm text-muted-foreground truncate mt-0.5">{incident.description}</p>
                    </div>
                    <Badge className={`text-xs shrink-0 ${statusColor(incident.status)}`}>
                      {incident.status_label}
                    </Badge>
                  </div>
                  <div className="flex items-center gap-2 mt-2 text-xs text-muted-foreground">
                    <span>{incident.project_type_label}</span>
                    <span>&middot;</span>
                    <span>{incident.damage_label}</span>
                    {incident.last_activity_label && (
                      <>
                        <span>&middot;</span>
                        <span>{incident.last_activity_label}</span>
                      </>
                    )}
                    <div className="ml-auto flex items-center gap-2">
                      {incident.unread_messages > 0 && (
                        <span className="inline-flex items-center gap-0.5 font-medium text-status-info" aria-label={`${incident.unread_messages} unread message${incident.unread_messages !== 1 ? "s" : ""}`}>
                          <MessageSquare className="h-3 w-3" />
                          {incident.unread_messages}
                        </span>
                      )}
                      {incident.unread_activity > 0 && (
                        <span className="inline-flex items-center gap-0.5 font-medium text-status-warning" aria-label={`${incident.unread_activity} new activit${incident.unread_activity !== 1 ? "ies" : "y"}`}>
                          <Activity className="h-3 w-3" />
                          {incident.unread_activity}
                        </span>
                      )}
                    </div>
                  </div>
                </Link>
              );
            })}
          </div>

          {/* Desktop table */}
          <div className="hidden sm:block rounded-lg border border-border bg-card shadow-sm overflow-hidden">
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
                          <span className="inline-flex items-center gap-0.5 text-xs font-medium text-status-info" title={`${incident.unread_messages} unread message${incident.unread_messages !== 1 ? "s" : ""}`} aria-label={`${incident.unread_messages} unread message${incident.unread_messages !== 1 ? "s" : ""}`}>
                            <MessageSquare className="h-3 w-3" />
                            {incident.unread_messages}
                          </span>
                        )}
                        {incident.unread_activity > 0 && (
                          <span className="inline-flex items-center gap-0.5 text-xs font-medium text-status-warning" title={`${incident.unread_activity} new activit${incident.unread_activity !== 1 ? "ies" : "y"}`} aria-label={`${incident.unread_activity} new activit${incident.unread_activity !== 1 ? "ies" : "y"}`}>
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
        </>
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

function ActiveFilterChips({
  filters,
  filterOptions,
  navigate,
  onClearSearch,
}: {
  filters: Filters;
  filterOptions: FilterOptions;
  navigate: (params: Record<string, string | number | null | undefined>) => void;
  onClearSearch: () => void;
}) {
  const chips: { label: string; onClear: () => void }[] = [];

  if (filters.search) {
    chips.push({ label: `Search: "${filters.search}"`, onClear: () => { onClearSearch(); navigate({ search: null }); } });
  }
  if (filters.status) {
    const labels = filters.status.split(",").map((v) => filterOptions.statuses.find((s) => s.value === v)?.label || v);
    chips.push({ label: `Status: ${labels.join(", ")}`, onClear: () => navigate({ status: null }) });
  }
  if (filters.property_id) {
    const labels = String(filters.property_id).split(",").map((v) => filterOptions.properties.find((p) => String(p.id) === v)?.name || v);
    chips.push({ label: `Property: ${labels.join(", ")}`, onClear: () => navigate({ property_id: null }) });
  }
  if (filters.project_type) {
    const labels = filters.project_type.split(",").map((v) => filterOptions.project_types.find((t) => t.value === v)?.label || v);
    chips.push({ label: `Type: ${labels.join(", ")}`, onClear: () => navigate({ project_type: null }) });
  }
  if (filters.emergency) {
    chips.push({ label: filters.emergency === "1" ? "Emergency Only" : "Non-Emergency Only", onClear: () => navigate({ emergency: null }) });
  }

  if (chips.length === 0) return null;

  return (
    <div className="flex flex-wrap items-center gap-1.5 mb-3">
      {chips.map((chip) => (
        <Badge
          key={chip.label}
          variant="secondary"
          className="gap-1 pr-1 text-xs font-normal"
        >
          {chip.label}
          <Button
            variant="ghost"
            size="sm"
            className="h-4 w-4 p-0 text-muted-foreground hover:text-foreground"
            onClick={chip.onClear}
          >
            <X className="h-3 w-3" />
          </Button>
        </Badge>
      ))}
      {chips.length > 1 && (
        <Button
          variant="ghost"
          size="sm"
          className="h-6 text-xs text-muted-foreground hover:text-foreground"
          onClick={() => { onClearSearch(); navigate({ search: null, status: null, property_id: null, project_type: null, emergency: null }); }}
        >
          Clear all
        </Button>
      )}
    </div>
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
