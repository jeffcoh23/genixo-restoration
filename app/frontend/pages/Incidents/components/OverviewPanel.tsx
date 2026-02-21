import { useState } from "react";
import { router } from "@inertiajs/react";
import { Mail, Pencil, Phone, Plus, UserPlus, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import type { Contact, IncidentDetail, AssignableUser, TeamUser } from "../types";

interface OverviewPanelProps {
  incident: IncidentDetail;
  can_assign: boolean;
  can_manage_contacts: boolean;
  assignable_mitigation_users: AssignableUser[];
  assignable_pm_users: AssignableUser[];
}

export default function OverviewPanel({ incident, can_assign, can_manage_contacts, assignable_mitigation_users, assignable_pm_users }: OverviewPanelProps) {
  const [contactFormOpen, setContactFormOpen] = useState(false);
  const [editingContact, setEditingContact] = useState<Contact | null>(null);
  const [confirmRemoveUser, setConfirmRemoveUser] = useState<{ name: string; path: string } | null>(null);
  const [expandedUserId, setExpandedUserId] = useState<number | null>(null);

  const handleAssign = (userId: number) => {
    router.post(incident.assignments_path, { user_id: userId }, { preserveScroll: true });
  };

  const handleRemove = () => {
    if (!confirmRemoveUser) return;
    router.delete(confirmRemoveUser.path, { preserveScroll: true });
    setConfirmRemoveUser(null);
  };

  const handleRemoveContact = (removePath: string) => {
    router.delete(removePath, { preserveScroll: true });
  };

  return (
    <div className="overflow-y-auto h-full p-4 bg-background">
      <div className="mx-auto grid max-w-[1500px] grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4 items-start">
        {/* Column 1: Mitigation Team */}
        <section className="rounded-xl border border-border bg-card shadow-sm p-4 space-y-3">
          <div className="flex items-center gap-2">
            <h3 className="text-sm font-semibold text-foreground flex-1">
              Mitigation Team <span className="text-muted-foreground tabular-nums">{incident.mitigation_team.length}</span>
            </h3>
            {can_assign && assignable_mitigation_users.length > 0 && (
              <AssignSelect users={assignable_mitigation_users} onAssign={handleAssign} />
            )}
          </div>

          {incident.mitigation_team.length === 0 ? (
            <p className="text-muted-foreground text-sm">No team members assigned.</p>
          ) : (
            <UserList
              users={incident.mitigation_team}
              expandedUserId={expandedUserId}
              onToggleExpand={setExpandedUserId}
              onRemove={(name, path) => setConfirmRemoveUser({ name, path })}
            />
          )}
        </section>

        {/* Column 2: Property Management */}
        <section className="rounded-xl border border-border bg-card shadow-sm p-4 space-y-3">
          <div className="flex items-center gap-2">
            <h3 className="text-sm font-semibold text-foreground flex-1">
              Property Management <span className="text-muted-foreground tabular-nums">{incident.pm_team.length}</span>
            </h3>
            {can_assign && assignable_pm_users.length > 0 && (
              <AssignSelect users={assignable_pm_users} onAssign={handleAssign} />
            )}
          </div>

          {incident.pm_team.length === 0 && incident.pm_contacts.length === 0 ? (
            <p className="text-muted-foreground text-sm">No PM team members.</p>
          ) : (
            <div className="space-y-3">
              {incident.pm_team.length > 0 && (
                <UserList
                  users={incident.pm_team}
                  expandedUserId={expandedUserId}
                  onToggleExpand={setExpandedUserId}
                  onRemove={(name, path) => setConfirmRemoveUser({ name, path })}
                />
              )}

              {incident.pm_contacts.length > 0 && (
                <div className="space-y-2">
                  {incident.pm_team.length > 0 && (
                    <div className="text-xs font-semibold text-muted-foreground uppercase tracking-wide pt-1">Contacts</div>
                  )}
                  {incident.pm_contacts.map((c) => (
                    <div key={c.id} className="rounded-md border border-border bg-background p-2.5">
                      <div className="flex-1 min-w-0">
                        <div className="text-sm font-medium text-foreground">
                          {c.name}
                          {c.title && <span className="text-muted-foreground font-normal"> &middot; {c.title}</span>}
                        </div>
                        <div className="flex flex-wrap items-center gap-2 text-xs text-muted-foreground mt-1">
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
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}
        </section>

        {/* Column 3: Contacts */}
        <section className="rounded-xl border border-border bg-card shadow-sm p-4 space-y-3">
          <div className="flex items-center gap-2">
            <h3 className="text-sm font-semibold text-foreground flex-1">
              Contacts <span className="text-muted-foreground tabular-nums">{incident.contacts.length}</span>
            </h3>
            {can_manage_contacts && (
              <Button variant="outline" size="sm" className="h-10 sm:h-8 text-sm sm:text-xs gap-1.5" onClick={() => setContactFormOpen(true)}>
                <Plus className="h-3 w-3" />
                Add
              </Button>
            )}
          </div>

          {incident.contacts.length === 0 ? (
            <p className="text-muted-foreground text-sm">No contacts added.</p>
          ) : (
            <div className="space-y-2">
              {incident.contacts.map((c) => (
                <div key={c.id} className="flex items-start gap-2 rounded-md border border-border bg-background p-2.5">
                  <div className="flex-1 min-w-0">
                    <div className="text-sm font-medium text-foreground">
                      {c.name}
                      {c.title && <span className="text-muted-foreground font-normal"> &middot; {c.title}</span>}
                      {c.onsite && <span className="ml-1.5 inline-flex items-center rounded bg-status-success/15 px-1.5 py-0.5 text-xs font-medium text-status-success">Onsite</span>}
                    </div>
                    <div className="flex flex-wrap items-center gap-2 text-xs text-muted-foreground mt-1">
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
                  {can_manage_contacts && (
                    <div className="flex items-center gap-0.5 shrink-0">
                      {c.update_path && (
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => setEditingContact(c)}
                          className="h-8 w-8 sm:h-6 sm:w-6 p-0 text-muted-foreground hover:text-foreground transition-colors"
                          title={`Edit ${c.name}`}
                        >
                          <Pencil className="h-3 w-3" />
                        </Button>
                      )}
                      {c.remove_path && (
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => handleRemoveContact(c.remove_path!)}
                          className="h-8 w-8 sm:h-6 sm:w-6 p-0 text-muted-foreground hover:text-destructive transition-colors"
                          title={`Remove ${c.name}`}
                        >
                          <X className="h-3 w-3" />
                        </Button>
                      )}
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </section>
      </div>

      {/* Confirm remove user */}
      <Dialog open={!!confirmRemoveUser} onOpenChange={(open) => !open && setConfirmRemoveUser(null)}>
        <DialogContent className="sm:max-w-sm">
          <DialogHeader>
            <DialogTitle>Remove Team Member</DialogTitle>
          </DialogHeader>
          <p className="text-sm">
            Remove <span className="font-medium">{confirmRemoveUser?.name}</span> from this incident?
          </p>
          <div className="flex justify-end gap-2 pt-2">
            <Button variant="ghost" size="sm" onClick={() => setConfirmRemoveUser(null)}>Cancel</Button>
            <Button variant="destructive" size="sm" onClick={handleRemove}>Remove</Button>
          </div>
        </DialogContent>
      </Dialog>

      {/* Add contact modal */}
      {contactFormOpen && (
        <ContactFormModal
          contacts_path={incident.contacts_path}
          onClose={() => setContactFormOpen(false)}
        />
      )}

      {/* Edit contact modal */}
      {editingContact && editingContact.update_path && (
        <ContactFormModal
          contact={editingContact}
          contacts_path={incident.contacts_path}
          onClose={() => setEditingContact(null)}
        />
      )}
    </div>
  );
}

function AssignSelect({ users, onAssign }: {
  users: AssignableUser[];
  onAssign: (userId: number) => void;
}) {
  const [value, setValue] = useState("");

  return (
    <Select
      value={value}
      onValueChange={(next) => {
        setValue("");
        onAssign(Number(next));
      }}
    >
      <SelectTrigger className="h-10 sm:h-8 w-[190px] text-sm sm:text-xs bg-background">
        <div className="flex items-center gap-1">
          <UserPlus className="h-3 w-3" />
          <SelectValue placeholder="Assign User" />
        </div>
      </SelectTrigger>
      <SelectContent>
        {users.map((u) => (
          <SelectItem key={u.id} value={String(u.id)}>
            {u.full_name} ({u.role_label})
          </SelectItem>
        ))}
      </SelectContent>
    </Select>
  );
}

function UserList({ users, expandedUserId, onToggleExpand, onRemove }: {
  users: TeamUser[];
  expandedUserId: number | null;
  onToggleExpand: (id: number | null) => void;
  onRemove: (name: string, path: string) => void;
}) {
  // Group users by role, preserving backend sort order
  const groups: { role: string; users: TeamUser[] }[] = [];
  for (const u of users) {
    const last = groups[groups.length - 1];
    if (last && last.role === u.role_label) {
      last.users.push(u);
    } else {
      groups.push({ role: u.role_label, users: [u] });
    }
  }

  return (
    <div className="space-y-2">
      {groups.map((group) => (
        <div key={group.role}>
          <div className="text-xs font-semibold uppercase tracking-wide text-muted-foreground mb-1">{group.role}s</div>
          <div className="space-y-1.5">
            {group.users.map((u) => {
              const isExpanded = expandedUserId === u.id;
              const hasContact = u.email || u.phone;
              return (
                <div key={u.id}>
                  <div className="flex items-center gap-2 text-sm rounded-md border border-border bg-background px-2 py-1.5 hover:bg-muted/25 transition-colors">
                    <div className="h-6 w-6 rounded-full bg-muted/70 flex items-center justify-center text-xs font-medium text-muted-foreground shrink-0">
                      {u.initials}
                    </div>
                    {hasContact ? (
                      <button
                        type="button"
                        className="text-foreground text-left hover:underline"
                        onClick={() => onToggleExpand(isExpanded ? null : u.id)}
                      >
                        {u.full_name}
                      </button>
                    ) : (
                      <span className="text-foreground">{u.full_name}</span>
                    )}
                    {u.remove_path && (
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={(e) => { e.stopPropagation(); onRemove(u.full_name, u.remove_path!); }}
                        className="h-8 w-8 sm:h-7 sm:w-7 p-0 ml-auto text-muted-foreground hover:text-destructive transition-colors"
                        title={`Remove ${u.full_name}`}
                      >
                        <X className="h-3 w-3" />
                      </Button>
                    )}
                  </div>
                  {isExpanded && (
                    <div className="flex flex-wrap items-center gap-3 text-xs text-muted-foreground ml-8 mt-1 mb-1 pl-1">
                      {u.email && (
                        <a href={`mailto:${u.email}`} className="flex items-center gap-1 hover:text-foreground transition-colors" onClick={(e) => e.stopPropagation()}>
                          <Mail className="h-2.5 w-2.5" />
                          {u.email}
                        </a>
                      )}
                      {u.phone && (
                        <a href={`tel:${u.phone}`} className="flex items-center gap-1 hover:text-foreground transition-colors" onClick={(e) => e.stopPropagation()}>
                          <Phone className="h-2.5 w-2.5" />
                          {u.phone}
                        </a>
                      )}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>
      ))}
    </div>
  );
}

function ContactFormModal({ contact, contacts_path, onClose }: {
  contact?: Contact;
  contacts_path: string;
  onClose: () => void;
}) {
  const editing = !!contact;
  const [name, setName] = useState(contact?.name ?? "");
  const [title, setTitle] = useState(contact?.title ?? "");
  const [email, setEmail] = useState(contact?.email ?? "");
  const [phone, setPhone] = useState(contact?.phone ?? "");
  const [onsite, setOnsite] = useState(contact?.onsite ?? false);
  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    const payload = { contact: { name, title, email, phone, onsite } };

    if (editing && contact?.update_path) {
      router.patch(contact.update_path, payload, {
        preserveScroll: true,
        onSuccess: onClose,
        onFinish: () => setSubmitting(false),
      });
    } else {
      router.post(contacts_path, payload, {
        preserveScroll: true,
        onSuccess: onClose,
        onFinish: () => setSubmitting(false),
      });
    }
  };

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>{editing ? "Edit Contact" : "Add Contact"}</DialogTitle>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-3">
          <div>
            <label className="text-xs font-medium text-muted-foreground">
              Name <span className="text-destructive">*</span>
            </label>
            <Input
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Contact name"
              className="mt-1"
              required
            />
          </div>

          <div>
            <label className="text-xs font-medium text-muted-foreground">
              Title <span className="text-muted-foreground font-normal">(optional)</span>
            </label>
            <Input
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="e.g. Property Manager"
              className="mt-1"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-xs font-medium text-muted-foreground">
                Email <span className="text-muted-foreground font-normal">(optional)</span>
              </label>
              <Input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="mt-1"
              />
            </div>
            <div>
              <label className="text-xs font-medium text-muted-foreground">
                Phone <span className="text-muted-foreground font-normal">(optional)</span>
              </label>
              <Input
                type="tel"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                className="mt-1"
              />
            </div>
          </div>

          <label className="flex items-center gap-2 text-xs cursor-pointer">
            <Checkbox
              checked={onsite}
              onCheckedChange={(checked) => setOnsite(checked === true)}
            />
            Onsite contact
          </label>

          <div className="flex justify-end gap-2 pt-2">
            <Button type="button" variant="ghost" size="sm" onClick={onClose}>Cancel</Button>
            <Button type="submit" size="sm" disabled={submitting}>
              {submitting ? "Saving..." : editing ? "Save" : "Add Contact"}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}
