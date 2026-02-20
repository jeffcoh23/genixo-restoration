import { useState } from "react";
import { router } from "@inertiajs/react";
import { Mail, Pencil, Phone, Plus, UserPlus, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import { Input } from "@/components/ui/input";
import type { Contact, IncidentDetail, AssignableUser, TeamUser } from "../types";

interface OverviewPanelProps {
  incident: IncidentDetail;
  can_assign: boolean;
  can_manage_contacts: boolean;
  assignable_mitigation_users: AssignableUser[];
  assignable_pm_users: AssignableUser[];
}

export default function OverviewPanel({ incident, can_assign, can_manage_contacts, assignable_mitigation_users, assignable_pm_users }: OverviewPanelProps) {
  const [assignOpenFor, setAssignOpenFor] = useState<"mitigation" | "pm" | null>(null);
  const [contactFormOpen, setContactFormOpen] = useState(false);
  const [editingContact, setEditingContact] = useState<Contact | null>(null);
  const [confirmRemoveUser, setConfirmRemoveUser] = useState<{ name: string; path: string } | null>(null);
  const [expandedUserId, setExpandedUserId] = useState<number | null>(null);

  const handleAssign = (userId: number) => {
    setAssignOpenFor(null);
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
    <div className="overflow-y-auto h-full px-3 py-3">
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {/* Column 1: Mitigation Team */}
        <div>
          <div className="flex items-center mb-2">
            <h3 className="text-xs font-semibold uppercase tracking-wide text-muted-foreground flex-1">
              Mitigation Team
              <span className="text-muted-foreground tabular-nums ml-1.5">{incident.mitigation_team.length}</span>
            </h3>
            {can_assign && assignable_mitigation_users.length > 0 && (
              <AssignDropdown
                users={assignable_mitigation_users}
                open={assignOpenFor === "mitigation"}
                onToggle={() => setAssignOpenFor(assignOpenFor === "mitigation" ? null : "mitigation")}
                onAssign={handleAssign}
                onClose={() => setAssignOpenFor(null)}
              />
            )}
          </div>

          {incident.mitigation_team.length === 0 ? (
            <p className="text-muted-foreground text-xs">No team members assigned.</p>
          ) : (
            <UserList
              users={incident.mitigation_team}
              expandedUserId={expandedUserId}
              onToggleExpand={setExpandedUserId}
              onRemove={(name, path) => setConfirmRemoveUser({ name, path })}
            />
          )}
        </div>

        {/* Column 2: Property Management */}
        <div>
          <div className="flex items-center mb-2">
            <h3 className="text-xs font-semibold uppercase tracking-wide text-muted-foreground flex-1">
              Property Management
              <span className="text-muted-foreground tabular-nums ml-1.5">{incident.pm_team.length}</span>
            </h3>
            {can_assign && assignable_pm_users.length > 0 && (
              <AssignDropdown
                users={assignable_pm_users}
                open={assignOpenFor === "pm"}
                onToggle={() => setAssignOpenFor(assignOpenFor === "pm" ? null : "pm")}
                onAssign={handleAssign}
                onClose={() => setAssignOpenFor(null)}
              />
            )}
          </div>

          {incident.pm_team.length === 0 && incident.pm_contacts.length === 0 ? (
            <p className="text-muted-foreground text-xs">No PM team members.</p>
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
                    <div className="text-xs font-medium text-muted-foreground uppercase tracking-wide pt-1">Contacts</div>
                  )}
                  {incident.pm_contacts.map((c) => (
                    <div key={c.id} className="flex items-start gap-2 pl-2 border-l-2 border-border">
                      <div className="flex-1 min-w-0">
                        <div className="text-xs font-medium text-foreground">
                          {c.name}
                          {c.title && <span className="text-muted-foreground font-normal"> &middot; {c.title}</span>}
                        </div>
                        <div className="flex items-center gap-2 text-xs text-muted-foreground mt-0.5">
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
        </div>

        {/* Column 3: Contacts */}
        <div>
          <div className="flex items-center mb-2">
            <h3 className="text-xs font-semibold uppercase tracking-wide text-muted-foreground flex-1">
              Contacts
              <span className="text-muted-foreground tabular-nums ml-1.5">{incident.contacts.length}</span>
            </h3>
            {can_manage_contacts && (
              <Button variant="ghost" size="sm" className="h-6 text-xs gap-1 text-muted-foreground" onClick={() => setContactFormOpen(true)}>
                <Plus className="h-3 w-3" />
                Add
              </Button>
            )}
          </div>

          {incident.contacts.length === 0 ? (
            <p className="text-muted-foreground text-xs">No contacts added.</p>
          ) : (
            <div className="space-y-2">
              {incident.contacts.map((c) => (
                <div key={c.id} className="flex items-start gap-2 pl-2 border-l-2 border-border">
                  <div className="flex-1 min-w-0">
                    <div className="text-xs font-medium text-foreground">
                      {c.name}
                      {c.title && <span className="text-muted-foreground font-normal"> &middot; {c.title}</span>}
                      {c.onsite && <span className="ml-1.5 inline-flex items-center rounded bg-emerald-100 px-1.5 py-0.5 text-xs font-medium text-emerald-700">Onsite</span>}
                    </div>
                    <div className="flex items-center gap-2 text-xs text-muted-foreground mt-0.5">
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
                          className="h-5 w-5 p-0 text-muted-foreground hover:text-foreground transition-colors"
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
                          className="h-5 w-5 p-0 text-muted-foreground hover:text-destructive transition-colors"
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
        </div>
      </div>

      {/* Confirm remove user */}
      {confirmRemoveUser && (
        <div className="fixed inset-0 z-50 flex items-center justify-center">
          <div className="fixed inset-0 bg-black opacity-40" />
          <div className="relative bg-background border border-border rounded w-full max-w-sm p-4 shadow-lg">
            <p className="text-sm">
              Remove <span className="font-medium">{confirmRemoveUser.name}</span> from this incident?
            </p>
            <div className="flex justify-end gap-2 mt-4">
              <Button variant="ghost" size="sm" onClick={() => setConfirmRemoveUser(null)}>Cancel</Button>
              <Button variant="destructive" size="sm" onClick={handleRemove}>Remove</Button>
            </div>
          </div>
        </div>
      )}

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

function AssignDropdown({ users, open, onToggle, onAssign, onClose }: {
  users: AssignableUser[];
  open: boolean;
  onToggle: () => void;
  onAssign: (userId: number) => void;
  onClose: () => void;
}) {
  return (
    <div className="relative">
      <Button variant="ghost" size="sm" className="h-6 text-xs gap-1 text-muted-foreground" onClick={onToggle}>
        <UserPlus className="h-3 w-3" />
        Assign
      </Button>
      {open && (
        <>
          <div className="fixed inset-0 z-10" onClick={onClose} />
          <div className="absolute right-0 top-full mt-1 z-20 bg-popover border border-border rounded shadow-md py-1 min-w-[220px] max-h-[200px] overflow-y-auto">
            {users.map((u) => (
              <Button
                key={u.id}
                variant="ghost"
                onClick={() => onAssign(u.id)}
                className="w-full justify-between px-3 py-1.5 h-auto text-xs hover:bg-muted transition-colors rounded-none"
              >
                <span>{u.full_name}</span>
                <span className="text-muted-foreground">{u.role_label}</span>
              </Button>
            ))}
          </div>
        </>
      )}
    </div>
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
          <div className="text-xs font-medium text-muted-foreground mb-0.5">{group.role}s</div>
          <div className="space-y-0.5">
            {group.users.map((u) => {
              const isExpanded = expandedUserId === u.id;
              const hasContact = u.email || u.phone;
              return (
                <div key={u.id}>
                  <div
                    className={`flex items-center gap-1.5 text-xs -mx-1 px-1 py-0.5 rounded hover:bg-muted transition-colors ${hasContact ? "cursor-pointer" : ""}`}
                    onClick={hasContact ? () => onToggleExpand(isExpanded ? null : u.id) : undefined}
                  >
                    <div className="h-5 w-5 rounded-full bg-muted flex items-center justify-center text-xs font-medium text-muted-foreground shrink-0">
                      {u.initials}
                    </div>
                    <span className="text-foreground">{u.full_name}</span>
                    {u.remove_path && (
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={(e) => { e.stopPropagation(); onRemove(u.full_name, u.remove_path!); }}
                        className="h-5 w-5 p-0 ml-1 text-muted-foreground hover:text-destructive transition-colors"
                        title={`Remove ${u.full_name}`}
                      >
                        <X className="h-3 w-3" />
                      </Button>
                    )}
                  </div>
                  {isExpanded && (
                    <div className="flex items-center gap-3 text-xs text-muted-foreground ml-6 mt-0.5 mb-1 pl-1">
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
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center">
      <div className="fixed inset-0 bg-black opacity-40" />
      <div className="relative bg-background border border-border rounded-t sm:rounded w-full sm:max-w-md p-4 shadow-lg">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-sm font-semibold">{editing ? "Edit Contact" : "Add Contact"}</h3>
          <Button variant="ghost" size="sm" className="h-7 w-7 p-0" onClick={onClose}>
            <X className="h-4 w-4" />
          </Button>
        </div>

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
      </div>
    </div>
  );
}
