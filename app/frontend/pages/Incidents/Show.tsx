import { Link, router, usePage } from "@inertiajs/react";
import { useState } from "react";
import { AlertTriangle, ChevronDown, Building2, Clock, User as UserIcon, X, Plus, Mail, Phone, Wrench, Timer } from "lucide-react";
import AppLayout from "@/layout/AppLayout";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { SharedProps } from "@/types";

interface AssignedUser {
  id: number;
  assignment_id: number;
  full_name: string;
  initials: string;
  role_label: string;
  organization_name: string;
  remove_path: string | null;
}

interface AssignableUser {
  id: number;
  full_name: string;
  role_label: string;
}

interface Contact {
  id: number;
  name: string;
  title: string | null;
  email: string | null;
  phone: string | null;
  remove_path: string | null;
}

interface Transition {
  value: string;
  label: string;
}

interface IncidentDetail {
  id: number;
  path: string;
  transition_path: string;
  stats: {
    total_labor_hours: number;
    active_equipment: number;
    total_equipment_placed: number;
  };
  assignments_path: string;
  contacts_path: string;
  description: string;
  cause: string | null;
  requested_next_steps: string | null;
  units_affected: number | null;
  affected_room_numbers: string | null;
  status: string;
  status_label: string;
  project_type: string;
  project_type_label: string;
  damage_type: string;
  damage_label: string;
  emergency: boolean;
  created_at: string;
  created_by: string | null;
  property: {
    id: number;
    name: string;
    address: string | null;
    path: string;
  };
  assigned_users: AssignedUser[];
  contacts: Contact[];
  valid_transitions: Transition[];
}

interface ShowProps {
  incident: IncidentDetail;
  can_transition: boolean;
  can_assign: boolean;
  can_manage_contacts: boolean;
  assignable_users: AssignableUser[];
  back_path: string;
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

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
  });
}

export default function IncidentShow() {
  const { incident, can_transition, can_assign, can_manage_contacts, assignable_users, back_path } =
    usePage<SharedProps & ShowProps>().props;

  const [statusOpen, setStatusOpen] = useState(false);
  const [transitioning, setTransitioning] = useState(false);
  const [assignOpen, setAssignOpen] = useState(false);
  const [contactFormOpen, setContactFormOpen] = useState(false);
  const [contactName, setContactName] = useState("");
  const [contactTitle, setContactTitle] = useState("");
  const [contactEmail, setContactEmail] = useState("");
  const [contactPhone, setContactPhone] = useState("");

  const handleAssign = (userId: number) => {
    setAssignOpen(false);
    router.post(incident.assignments_path, { user_id: userId }, { preserveScroll: true });
  };

  const handleRemove = (removePath: string) => {
    router.delete(removePath, { preserveScroll: true });
  };

  const handleAddContact = (e: React.FormEvent) => {
    e.preventDefault();
    router.post(incident.contacts_path, {
      contact: { name: contactName, title: contactTitle, email: contactEmail, phone: contactPhone }
    }, {
      preserveScroll: true,
      onSuccess: () => {
        setContactFormOpen(false);
        setContactName("");
        setContactTitle("");
        setContactEmail("");
        setContactPhone("");
      },
    });
  };

  const handleRemoveContact = (removePath: string) => {
    router.delete(removePath, { preserveScroll: true });
  };

  const handleTransition = (newStatus: string) => {
    setTransitioning(true);
    setStatusOpen(false);
    router.patch(incident.transition_path, { status: newStatus }, {
      onFinish: () => setTransitioning(false),
    });
  };

  // Group assigned users by org
  const orgGroups = incident.assigned_users.reduce<Record<string, AssignedUser[]>>((acc, u) => {
    const key = u.organization_name;
    if (!acc[key]) acc[key] = [];
    acc[key].push(u);
    return acc;
  }, {});

  return (
    <AppLayout>
      {/* Back link */}
      <div className="mb-4">
        <Link href={back_path} className="text-sm text-muted-foreground hover:text-foreground">
          &larr; Incidents
        </Link>
      </div>

      {/* Sticky header */}
      <div className="sticky top-0 z-10 bg-background pb-4 border-b border-border mb-6">
        {/* Property */}
        <div className="flex items-center gap-2 text-sm text-muted-foreground mb-1">
          <Link href={incident.property.path} className="hover:text-foreground hover:underline">
            {incident.property.name}
          </Link>
          {incident.property.address && (
            <>
              <span>&middot;</span>
              <span>{incident.property.address}</span>
            </>
          )}
        </div>

        {/* Status + badges row */}
        <div className="flex flex-wrap items-center gap-3 mb-2">
          {/* Status with dropdown */}
          <div className="relative">
            {can_transition && incident.valid_transitions.length > 0 ? (
              <button
                onClick={() => setStatusOpen(!statusOpen)}
                disabled={transitioning}
                className={`inline-flex items-center gap-1.5 rounded-md px-3 py-1.5 text-sm font-medium ${statusColor(incident.status)} hover:opacity-90 transition-opacity`}
              >
                {incident.status_label}
                <ChevronDown className="h-3.5 w-3.5" />
              </button>
            ) : (
              <Badge className={`text-sm px-3 py-1.5 ${statusColor(incident.status)}`}>
                {incident.status_label}
              </Badge>
            )}

            {statusOpen && (
              <>
                <div className="fixed inset-0 z-10" onClick={() => setStatusOpen(false)} />
                <div className="absolute left-0 top-full mt-1 z-20 bg-popover border border-border rounded-md shadow-md py-1 min-w-[180px]">
                  {incident.valid_transitions.map((t) => (
                    <button
                      key={t.value}
                      onClick={() => handleTransition(t.value)}
                      className="w-full px-3 py-2 text-left text-sm hover:bg-muted transition-colors"
                    >
                      {t.label}
                    </button>
                  ))}
                </div>
              </>
            )}
          </div>

          {incident.emergency && (
            <Badge className="bg-destructive text-destructive-foreground text-sm">
              <AlertTriangle className="h-3.5 w-3.5 mr-1" />
              Emergency
            </Badge>
          )}

          <span className="text-sm text-muted-foreground">
            {incident.damage_label} &middot; {incident.project_type_label}
          </span>
        </div>

        {/* Meta row */}
        <div className="flex flex-wrap items-center gap-4 text-sm text-muted-foreground">
          {incident.created_by && (
            <span className="flex items-center gap-1">
              <UserIcon className="h-3.5 w-3.5" />
              {incident.created_by}
            </span>
          )}
          <span className="flex items-center gap-1">
            <Clock className="h-3.5 w-3.5" />
            {formatDate(incident.created_at)}
          </span>

          {/* Assigned users avatars */}
          {incident.assigned_users.length > 0 && (
            <div className="flex items-center gap-1">
              <div className="flex -space-x-1.5">
                {incident.assigned_users.slice(0, 4).map((u) => (
                  <div
                    key={u.id}
                    title={u.full_name}
                    className="h-6 w-6 rounded-full bg-muted border-2 border-background flex items-center justify-center text-[10px] font-medium text-muted-foreground"
                  >
                    {u.initials}
                  </div>
                ))}
              </div>
              {incident.assigned_users.length > 4 && (
                <span className="text-xs text-muted-foreground ml-1">
                  +{incident.assigned_users.length - 4}
                </span>
              )}
              <span className="text-xs ml-1">{incident.assigned_users.length} assigned</span>
            </div>
          )}
        </div>
      </div>

      {/* Split panel layout */}
      <div className="flex flex-col lg:flex-row gap-6 min-h-[calc(100vh-280px)]">
        {/* Left panel — incident details */}
        <div className="flex-1 lg:w-[65%] lg:max-w-[65%] space-y-6 lg:overflow-y-auto lg:pr-4">
          {/* Description */}
          <DetailSection title="Description">
            <p className="text-foreground whitespace-pre-wrap">{incident.description}</p>
          </DetailSection>

          {/* Cause */}
          {incident.cause && (
            <DetailSection title="Cause">
              <p className="text-foreground whitespace-pre-wrap">{incident.cause}</p>
            </DetailSection>
          )}

          {/* Next Steps */}
          {incident.requested_next_steps && (
            <DetailSection title="Requested Next Steps">
              <p className="text-foreground whitespace-pre-wrap">{incident.requested_next_steps}</p>
            </DetailSection>
          )}

          {/* Units / Rooms */}
          {(incident.units_affected || incident.affected_room_numbers) && (
            <div className="flex flex-wrap gap-6">
              {incident.units_affected && (
                <DetailSection title="Units Affected">
                  <p className="text-foreground">{incident.units_affected}</p>
                </DetailSection>
              )}
              {incident.affected_room_numbers && (
                <DetailSection title="Affected Rooms">
                  <p className="text-foreground">{incident.affected_room_numbers}</p>
                </DetailSection>
              )}
            </div>
          )}

          {/* Assigned Team */}
          <DetailSection title="Assigned Team">
            {Object.keys(orgGroups).length === 0 ? (
              <p className="text-muted-foreground text-sm">No users assigned yet.</p>
            ) : (
              <div className="space-y-4">
                {Object.entries(orgGroups).map(([orgName, users]) => (
                  <div key={orgName}>
                    <div className="flex items-center gap-2 mb-2">
                      <Building2 className="h-4 w-4 text-muted-foreground" />
                      <span className="font-medium text-sm">{orgName}</span>
                    </div>
                    <div className="space-y-1 ml-6">
                      {users.map((u) => (
                        <div key={u.id} className="flex items-center gap-2 text-sm group">
                          <div className="h-6 w-6 rounded-full bg-muted flex items-center justify-center text-[10px] font-medium text-muted-foreground">
                            {u.initials}
                          </div>
                          <span className="text-foreground">{u.full_name}</span>
                          <span className="text-muted-foreground">&middot; {u.role_label}</span>
                          {u.remove_path && (
                            <button
                              onClick={() => handleRemove(u.remove_path!)}
                              className="ml-auto opacity-0 group-hover:opacity-100 text-muted-foreground hover:text-destructive transition-opacity"
                              title={`Remove ${u.full_name}`}
                            >
                              <X className="h-3.5 w-3.5" />
                            </button>
                          )}
                        </div>
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            )}

            {/* Assign button */}
            {can_assign && assignable_users.length > 0 && (
              <div className="relative mt-3">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setAssignOpen(!assignOpen)}
                >
                  <Plus className="h-3.5 w-3.5 mr-1" />
                  Assign User
                </Button>

                {assignOpen && (
                  <>
                    <div className="fixed inset-0 z-10" onClick={() => setAssignOpen(false)} />
                    <div className="absolute left-0 top-full mt-1 z-20 bg-popover border border-border rounded-md shadow-md py-1 min-w-[240px] max-h-[200px] overflow-y-auto">
                      {assignable_users.map((u) => (
                        <button
                          key={u.id}
                          onClick={() => handleAssign(u.id)}
                          className="w-full px-3 py-2 text-left text-sm hover:bg-muted transition-colors flex items-center justify-between"
                        >
                          <span>{u.full_name}</span>
                          <span className="text-muted-foreground text-xs">{u.role_label}</span>
                        </button>
                      ))}
                    </div>
                  </>
                )}
              </div>
            )}
          </DetailSection>

          {/* Contacts */}
          <DetailSection title="Contacts">
            {incident.contacts.length === 0 && !can_manage_contacts ? (
              <p className="text-muted-foreground text-sm">No contacts added.</p>
            ) : (
              <>
                {incident.contacts.length > 0 && (
                  <div className="space-y-3">
                    {incident.contacts.map((c) => (
                      <div key={c.id} className="flex items-start justify-between group">
                        <div>
                          <div className="text-sm font-medium text-foreground">
                            {c.name}
                            {c.title && <span className="text-muted-foreground font-normal"> &middot; {c.title}</span>}
                          </div>
                          <div className="flex items-center gap-3 text-xs text-muted-foreground mt-0.5">
                            {c.email && (
                              <span className="flex items-center gap-1">
                                <Mail className="h-3 w-3" />
                                {c.email}
                              </span>
                            )}
                            {c.phone && (
                              <span className="flex items-center gap-1">
                                <Phone className="h-3 w-3" />
                                {c.phone}
                              </span>
                            )}
                          </div>
                        </div>
                        {c.remove_path && (
                          <button
                            onClick={() => handleRemoveContact(c.remove_path!)}
                            className="opacity-0 group-hover:opacity-100 text-muted-foreground hover:text-destructive transition-opacity mt-0.5"
                            title={`Remove ${c.name}`}
                          >
                            <X className="h-3.5 w-3.5" />
                          </button>
                        )}
                      </div>
                    ))}
                  </div>
                )}

                {can_manage_contacts && (
                  <div className="mt-3">
                    {contactFormOpen ? (
                      <form onSubmit={handleAddContact} className="space-y-2 rounded-md border border-border p-3">
                        <input
                          type="text"
                          placeholder="Name *"
                          value={contactName}
                          onChange={(e) => setContactName(e.target.value)}
                          required
                          className="w-full rounded-md border border-input bg-background px-3 py-1.5 text-sm focus:outline-none focus:ring-1 focus:ring-ring"
                        />
                        <input
                          type="text"
                          placeholder="Title"
                          value={contactTitle}
                          onChange={(e) => setContactTitle(e.target.value)}
                          className="w-full rounded-md border border-input bg-background px-3 py-1.5 text-sm focus:outline-none focus:ring-1 focus:ring-ring"
                        />
                        <div className="flex gap-2">
                          <input
                            type="email"
                            placeholder="Email"
                            value={contactEmail}
                            onChange={(e) => setContactEmail(e.target.value)}
                            className="flex-1 rounded-md border border-input bg-background px-3 py-1.5 text-sm focus:outline-none focus:ring-1 focus:ring-ring"
                          />
                          <input
                            type="tel"
                            placeholder="Phone"
                            value={contactPhone}
                            onChange={(e) => setContactPhone(e.target.value)}
                            className="flex-1 rounded-md border border-input bg-background px-3 py-1.5 text-sm focus:outline-none focus:ring-1 focus:ring-ring"
                          />
                        </div>
                        <div className="flex gap-2">
                          <Button type="submit" size="sm">Add Contact</Button>
                          <Button type="button" variant="ghost" size="sm" onClick={() => setContactFormOpen(false)}>Cancel</Button>
                        </div>
                      </form>
                    ) : (
                      <Button variant="outline" size="sm" onClick={() => setContactFormOpen(true)}>
                        <Plus className="h-3.5 w-3.5 mr-1" />
                        Add Contact
                      </Button>
                    )}
                  </div>
                )}
              </>
            )}
          </DetailSection>

          {/* Quick Stats */}
          {(incident.stats.total_labor_hours > 0 || incident.stats.total_equipment_placed > 0) && (
            <div className="flex flex-wrap gap-4">
              <div className="flex items-center gap-2 rounded-md border border-border px-4 py-3">
                <Timer className="h-5 w-5 text-muted-foreground" />
                <div>
                  <div className="text-lg font-semibold text-foreground">{incident.stats.total_labor_hours}</div>
                  <div className="text-xs text-muted-foreground">hours logged</div>
                </div>
              </div>
              <div className="flex items-center gap-2 rounded-md border border-border px-4 py-3">
                <Wrench className="h-5 w-5 text-muted-foreground" />
                <div>
                  <div className="text-lg font-semibold text-foreground">{incident.stats.active_equipment}</div>
                  <div className="text-xs text-muted-foreground">active equipment</div>
                </div>
              </div>
              {incident.stats.total_equipment_placed > incident.stats.active_equipment && (
                <div className="flex items-center gap-2 rounded-md border border-border px-4 py-3">
                  <Wrench className="h-5 w-5 text-muted-foreground opacity-50" />
                  <div>
                    <div className="text-lg font-semibold text-foreground">{incident.stats.total_equipment_placed}</div>
                    <div className="text-xs text-muted-foreground">total placed</div>
                  </div>
                </div>
              )}
            </div>
          )}
        </div>

        {/* Right panel — tabs placeholder */}
        <div className="lg:w-[35%] lg:min-w-[35%] lg:border-l lg:border-border lg:pl-6">
          <RightPanelShell />
        </div>
      </div>
    </AppLayout>
  );
}

function DetailSection({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div>
      <h3 className="text-xs font-semibold uppercase tracking-wide text-muted-foreground mb-2">
        {title}
      </h3>
      {children}
    </div>
  );
}

function RightPanelShell() {
  const [activeTab, setActiveTab] = useState<"messages" | "daily_log" | "documents">("messages");

  const tabs = [
    { key: "messages" as const, label: "Messages" },
    { key: "daily_log" as const, label: "Daily Log" },
    { key: "documents" as const, label: "Documents" },
  ];

  return (
    <div className="flex flex-col h-full">
      {/* Tab bar */}
      <div className="flex border-b border-border mb-4">
        {tabs.map((tab) => (
          <button
            key={tab.key}
            onClick={() => setActiveTab(tab.key)}
            className={`px-4 py-2 text-sm font-medium border-b-2 transition-colors ${
              activeTab === tab.key
                ? "border-primary text-foreground"
                : "border-transparent text-muted-foreground hover:text-foreground"
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Tab content placeholder */}
      <div className="flex-1 flex items-center justify-center text-muted-foreground text-sm py-12">
        {activeTab === "messages" && "Messages coming in Phase 4."}
        {activeTab === "daily_log" && "Daily log coming in Phase 4."}
        {activeTab === "documents" && "Documents coming in Phase 4."}
      </div>
    </div>
  );
}
