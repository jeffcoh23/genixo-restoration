import { useState } from "react";
import { router } from "@inertiajs/react";
import { Building2, Mail, Phone, Plus, Timer, Wrench, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import type { IncidentDetail, AssignableUser, Contact } from "../types";

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
    <div className="flex-1 lg:w-[65%] lg:max-w-[65%] space-y-6 lg:overflow-y-auto lg:pr-4">
      <DetailSection title="Description">
        <p className="text-foreground whitespace-pre-wrap">{incident.description}</p>
      </DetailSection>

      {incident.cause && (
        <DetailSection title="Cause">
          <p className="text-foreground whitespace-pre-wrap">{incident.cause}</p>
        </DetailSection>
      )}

      {incident.requested_next_steps && (
        <DetailSection title="Requested Next Steps">
          <p className="text-foreground whitespace-pre-wrap">{incident.requested_next_steps}</p>
        </DetailSection>
      )}

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

      <DetailSection title="Assigned Team">
        {incident.assigned_team.length === 0 ? (
          <p className="text-muted-foreground text-sm">No users assigned yet.</p>
        ) : (
          <div className="space-y-4">
            {incident.assigned_team.map((group) => (
              <div key={group.organization_name}>
                <div className="flex items-center gap-2 mb-2">
                  <Building2 className="h-4 w-4 text-muted-foreground" />
                  <span className="font-medium text-sm">{group.organization_name}</span>
                </div>
                <div className="space-y-1 ml-6">
                  {group.users.map((u) => (
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

        {can_assign && assignable_users.length > 0 && (
          <div className="relative mt-3">
            <Button variant="outline" size="sm" onClick={() => setAssignOpen(!assignOpen)}>
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

      <ContactsSection
        contacts={incident.contacts}
        can_manage_contacts={can_manage_contacts}
        contactFormOpen={contactFormOpen}
        setContactFormOpen={setContactFormOpen}
        contactName={contactName}
        setContactName={setContactName}
        contactTitle={contactTitle}
        setContactTitle={setContactTitle}
        contactEmail={contactEmail}
        setContactEmail={setContactEmail}
        contactPhone={contactPhone}
        setContactPhone={setContactPhone}
        onAddContact={handleAddContact}
        onRemoveContact={handleRemoveContact}
      />

      {incident.show_stats && (
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
          {incident.stats.show_removed_equipment && (
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

interface ContactsSectionProps {
  contacts: Contact[];
  can_manage_contacts: boolean;
  contactFormOpen: boolean;
  setContactFormOpen: (open: boolean) => void;
  contactName: string;
  setContactName: (v: string) => void;
  contactTitle: string;
  setContactTitle: (v: string) => void;
  contactEmail: string;
  setContactEmail: (v: string) => void;
  contactPhone: string;
  setContactPhone: (v: string) => void;
  onAddContact: (e: React.FormEvent) => void;
  onRemoveContact: (path: string) => void;
}

function ContactsSection({
  contacts, can_manage_contacts,
  contactFormOpen, setContactFormOpen,
  contactName, setContactName,
  contactTitle, setContactTitle,
  contactEmail, setContactEmail,
  contactPhone, setContactPhone,
  onAddContact, onRemoveContact
}: ContactsSectionProps) {
  return (
    <DetailSection title="Contacts">
      {contacts.length === 0 && !can_manage_contacts ? (
        <p className="text-muted-foreground text-sm">No contacts added.</p>
      ) : (
        <>
          {contacts.length > 0 && (
            <div className="space-y-3">
              {contacts.map((c) => (
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
                      onClick={() => onRemoveContact(c.remove_path!)}
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
                <form onSubmit={onAddContact} className="space-y-2 rounded-md border border-border p-3">
                  <Input
                    type="text"
                    placeholder="Name *"
                    value={contactName}
                    onChange={(e) => setContactName(e.target.value)}
                    required
                  />
                  <Input
                    type="text"
                    placeholder="Title"
                    value={contactTitle}
                    onChange={(e) => setContactTitle(e.target.value)}
                  />
                  <div className="flex gap-2">
                    <Input
                      type="email"
                      placeholder="Email"
                      value={contactEmail}
                      onChange={(e) => setContactEmail(e.target.value)}
                      className="flex-1"
                    />
                    <Input
                      type="tel"
                      placeholder="Phone"
                      value={contactPhone}
                      onChange={(e) => setContactPhone(e.target.value)}
                      className="flex-1"
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
  );
}
