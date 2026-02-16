import { useState } from "react";
import { router } from "@inertiajs/react";
import { Building2, ChevronDown, Mail, Phone, Plus, Wrench, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import type { IncidentDetail, AssignableUser } from "../types";

interface OverviewPanelProps {
  incident: IncidentDetail;
  can_assign: boolean;
  can_manage_contacts: boolean;
  assignable_users: AssignableUser[];
}

export default function OverviewPanel({ incident, can_assign, can_manage_contacts, assignable_users }: OverviewPanelProps) {
  const [assignOpen, setAssignOpen] = useState(false);
  const [contactFormOpen, setContactFormOpen] = useState(false);
  const [contactName, setContactName] = useState("");
  const [contactTitle, setContactTitle] = useState("");
  const [contactEmail, setContactEmail] = useState("");
  const [contactPhone, setContactPhone] = useState("");
  const [equipmentOpen, setEquipmentOpen] = useState(true);
  const [teamOpen, setTeamOpen] = useState(true);
  const [contactsOpen, setContactsOpen] = useState(false);

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

  return (
    <div className="space-y-4 pb-6">
      <DetailSection title="Description">
        <p className="text-sm text-foreground whitespace-pre-wrap">{incident.description}</p>
      </DetailSection>

      {incident.cause && (
        <DetailSection title="Cause">
          <p className="text-sm text-foreground whitespace-pre-wrap">{incident.cause}</p>
        </DetailSection>
      )}

      {incident.requested_next_steps && (
        <DetailSection title="Requested Next Steps">
          <p className="text-sm text-foreground whitespace-pre-wrap">{incident.requested_next_steps}</p>
        </DetailSection>
      )}

      {(incident.units_affected || incident.affected_room_numbers) && (
        <div className="flex items-center gap-2 text-sm text-muted-foreground">
          {incident.units_affected && <span>{incident.units_affected} units affected</span>}
          {incident.units_affected && incident.affected_room_numbers && <span>&middot;</span>}
          {incident.affected_room_numbers && <span>Rooms: {incident.affected_room_numbers}</span>}
        </div>
      )}

      <div className="border-t border-border/60" />

      {/* Deployed Equipment — collapsible, default open */}
      <div>
        <button
          onClick={() => setEquipmentOpen(!equipmentOpen)}
          className="flex items-center gap-1.5 w-full text-left -mx-1.5 px-1.5 py-1 rounded hover:bg-muted/50 transition-colors"
        >
          <ChevronDown className={`h-3.5 w-3.5 text-muted-foreground transition-transform ${equipmentOpen ? "" : "-rotate-90"}`} />
          <h3 className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">
            Deployed Equipment
          </h3>
          <span className="text-[11px] text-muted-foreground tabular-nums ml-auto">{incident.deployed_equipment.length}</span>
        </button>

        {equipmentOpen && (
          <div className="mt-2 ml-5">
            {incident.deployed_equipment.length === 0 ? (
              <p className="text-muted-foreground text-xs">No equipment currently deployed.</p>
            ) : (
              <div className="space-y-1.5">
                {incident.deployed_equipment.map((item) => (
                  <div key={item.id} className="bg-muted/60 rounded border border-border p-2">
                    <div className="flex items-center gap-1.5">
                      <Wrench className="h-3.5 w-3.5 text-muted-foreground" />
                      <span className="text-xs font-medium text-foreground">{item.type_name}</span>
                      <span className="text-[11px] text-muted-foreground">x{item.quantity}</span>
                    </div>
                    {item.last_event_label && item.last_event_at_label && (
                      <p className="text-[11px] text-muted-foreground mt-0.5">
                        Last action: {item.last_event_label} · {item.last_event_at_label}
                      </p>
                    )}
                    {item.note && <p className="text-[11px] text-muted-foreground">{item.note}</p>}
                    {item.actor_name && <p className="text-[11px] text-muted-foreground">{item.actor_name}</p>}
                  </div>
                ))}
              </div>
            )}
          </div>
        )}
      </div>

      {/* Assigned Team — collapsible, default open */}
      <div>
        <button
          onClick={() => setTeamOpen(!teamOpen)}
          className="flex items-center gap-1.5 w-full text-left -mx-1.5 px-1.5 py-1 rounded hover:bg-muted/50 transition-colors"
        >
          <ChevronDown className={`h-3.5 w-3.5 text-muted-foreground transition-transform ${teamOpen ? "" : "-rotate-90"}`} />
          <h3 className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">
            Assigned Team
          </h3>
          <span className="text-[11px] text-muted-foreground tabular-nums ml-auto">{incident.assigned_summary.count}</span>
        </button>

        {teamOpen && (
          <div className="mt-2 ml-5">
            {incident.assigned_team.length === 0 ? (
              <p className="text-muted-foreground text-xs">No users assigned yet.</p>
            ) : (
              <div className="space-y-3">
                {incident.assigned_team.map((group) => (
                  <div key={group.organization_name}>
                    <div className="flex items-center gap-1.5 mb-1">
                      <Building2 className="h-3.5 w-3.5 text-muted-foreground" />
                      <span className="font-medium text-xs">{group.organization_name}</span>
                    </div>
                    <div className="space-y-0.5 ml-5">
                      {group.users.map((u) => (
                        <div key={u.id} className="flex items-center gap-1.5 text-xs -mx-1 px-1 py-0.5 rounded hover:bg-muted/40 transition-colors">
                          <div className="h-5 w-5 rounded-full bg-muted flex items-center justify-center text-[9px] font-medium text-muted-foreground shrink-0">
                            {u.initials}
                          </div>
                          <span className="text-foreground">{u.full_name}</span>
                          <span className="text-muted-foreground">&middot; {u.role_label}</span>
                          {u.remove_path && (
                            <button
                              onClick={() => handleRemove(u.remove_path!)}
                              className="ml-auto text-muted-foreground hover:text-destructive transition-colors"
                              title={`Remove ${u.full_name}`}
                            >
                              <X className="h-3 w-3" />
                            </button>
                          )}
                        </div>
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            )}

            {can_assign && assignable_users.length > 0 && (
              <div className="relative mt-2">
                <Button variant="outline" size="sm" className="h-7 text-xs" onClick={() => setAssignOpen(!assignOpen)}>
                  <Plus className="h-3 w-3 mr-1" />
                  Assign
                </Button>

                {assignOpen && (
                  <>
                    <div className="fixed inset-0 z-10" onClick={() => setAssignOpen(false)} />
                    <div className="absolute left-0 top-full mt-1 z-20 bg-popover border border-border rounded-md shadow-md py-1 min-w-[220px] max-h-[200px] overflow-y-auto">
                      {assignable_users.map((u) => (
                        <button
                          key={u.id}
                          onClick={() => handleAssign(u.id)}
                          className="w-full px-3 py-1.5 text-left text-xs hover:bg-muted transition-colors flex items-center justify-between"
                        >
                          <span>{u.full_name}</span>
                          <span className="text-muted-foreground">{u.role_label}</span>
                        </button>
                      ))}
                    </div>
                  </>
                )}
              </div>
            )}
          </div>
        )}
      </div>

      {/* Contacts — collapsible, default closed */}
      <div>
        <button
          onClick={() => setContactsOpen(!contactsOpen)}
          className="flex items-center gap-1.5 w-full text-left -mx-1.5 px-1.5 py-1 rounded hover:bg-muted/50 transition-colors"
        >
          <ChevronDown className={`h-3.5 w-3.5 text-muted-foreground transition-transform ${contactsOpen ? "" : "-rotate-90"}`} />
          <h3 className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">
            Contacts
          </h3>
          <span className="text-[11px] text-muted-foreground tabular-nums ml-auto">{incident.contacts.length}</span>
        </button>

        {contactsOpen && (
          <div className="mt-2 ml-5">
            {incident.contacts.length === 0 && !can_manage_contacts ? (
              <p className="text-muted-foreground text-xs">No contacts added.</p>
            ) : (
              <>
                {incident.contacts.length > 0 && (
                  <div className="space-y-2">
                    {incident.contacts.map((c) => (
                      <div key={c.id} className="flex items-start justify-between pl-2 border-l-2 border-border">
                        <div>
                          <div className="text-xs font-medium text-foreground">
                            {c.name}
                            {c.title && <span className="text-muted-foreground font-normal"> &middot; {c.title}</span>}
                          </div>
                          <div className="flex items-center gap-2 text-[11px] text-muted-foreground mt-0.5">
                            {c.email && (
                              <span className="flex items-center gap-1">
                                <Mail className="h-2.5 w-2.5" />
                                {c.email}
                              </span>
                            )}
                            {c.phone && (
                              <span className="flex items-center gap-1">
                                <Phone className="h-2.5 w-2.5" />
                                {c.phone}
                              </span>
                            )}
                          </div>
                        </div>
                        {c.remove_path && (
                          <button
                            onClick={() => handleRemoveContact(c.remove_path!)}
                            className="text-muted-foreground hover:text-destructive transition-colors mt-0.5"
                            title={`Remove ${c.name}`}
                          >
                            <X className="h-3 w-3" />
                          </button>
                        )}
                      </div>
                    ))}
                  </div>
                )}

                {can_manage_contacts && (
                  <div className="mt-2">
                    {contactFormOpen ? (
                      <form onSubmit={handleAddContact} className="space-y-2 rounded-md border border-border p-3">
                        <Input
                          type="text"
                          placeholder="Name *"
                          value={contactName}
                          onChange={(e) => setContactName(e.target.value)}
                          required
                          className="h-8 text-xs"
                        />
                        <Input
                          type="text"
                          placeholder="Title"
                          value={contactTitle}
                          onChange={(e) => setContactTitle(e.target.value)}
                          className="h-8 text-xs"
                        />
                        <div className="flex gap-2">
                          <Input
                            type="email"
                            placeholder="Email"
                            value={contactEmail}
                            onChange={(e) => setContactEmail(e.target.value)}
                            className="flex-1 h-8 text-xs"
                          />
                          <Input
                            type="tel"
                            placeholder="Phone"
                            value={contactPhone}
                            onChange={(e) => setContactPhone(e.target.value)}
                            className="flex-1 h-8 text-xs"
                          />
                        </div>
                        <div className="flex gap-2">
                          <Button type="submit" size="sm" className="h-7 text-xs">Add Contact</Button>
                          <Button type="button" variant="ghost" size="sm" className="h-7 text-xs" onClick={() => setContactFormOpen(false)}>Cancel</Button>
                        </div>
                      </form>
                    ) : (
                      <Button variant="outline" size="sm" className="h-7 text-xs" onClick={() => setContactFormOpen(true)}>
                        <Plus className="h-3 w-3 mr-1" />
                        Add Contact
                      </Button>
                    )}
                  </div>
                )}
              </>
            )}
          </div>
        )}
      </div>
    </div>
  );
}

function DetailSection({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div>
      <h3 className="text-xs font-semibold uppercase tracking-wide text-muted-foreground mb-1.5">
        {title}
      </h3>
      {children}
    </div>
  );
}
