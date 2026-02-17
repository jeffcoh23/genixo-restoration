import { useState } from "react";
import { router } from "@inertiajs/react";
import { Building2, ChevronDown, Mail, Pencil, Phone, Plus, UserPlus, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import { Input } from "@/components/ui/input";
import type { Contact, IncidentDetail, AssignableUser } from "../types";

interface OverviewPanelProps {
  incident: IncidentDetail;
  can_assign: boolean;
  can_manage_contacts: boolean;
  assignable_users: AssignableUser[];
}

export default function OverviewPanel({ incident, can_assign, can_manage_contacts, assignable_users }: OverviewPanelProps) {
  const [assignOpen, setAssignOpen] = useState(false);
  const [contactFormOpen, setContactFormOpen] = useState(false);
  const [editingContact, setEditingContact] = useState<Contact | null>(null);
  const [confirmRemoveUser, setConfirmRemoveUser] = useState<{ name: string; path: string } | null>(null);
  const [teamOpen, setTeamOpen] = useState(true);
  const [contactsOpen, setContactsOpen] = useState(true);

  const handleAssign = (userId: number) => {
    setAssignOpen(false);
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
    <div className="overflow-y-auto h-full px-3 py-3 space-y-4">
      {/* Assigned Team — collapsible, default open */}
      <div>
        <div className="flex items-center">
          <Button
            variant="ghost"
            onClick={() => setTeamOpen(!teamOpen)}
            className="flex items-center gap-1.5 flex-1 justify-start -mx-1.5 px-1.5 py-1 h-auto rounded hover:bg-muted transition-colors"
          >
            <ChevronDown className={`h-3.5 w-3.5 text-muted-foreground transition-transform ${teamOpen ? "" : "-rotate-90"}`} />
            <h3 className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">
              Assigned Team
            </h3>
            <span className="text-xs text-muted-foreground tabular-nums ml-auto">{incident.assigned_summary.count}</span>
          </Button>
          {can_assign && assignable_users.length > 0 && (
            <div className="relative">
              <Button variant="ghost" size="sm" className="h-6 text-xs gap-1 text-muted-foreground" onClick={() => setAssignOpen(!assignOpen)}>
                <UserPlus className="h-3 w-3" />
                Assign
              </Button>
              {assignOpen && (
                <>
                  <div className="fixed inset-0 z-10" onClick={() => setAssignOpen(false)} />
                  <div className="absolute right-0 top-full mt-1 z-20 bg-popover border border-border rounded shadow-md py-1 min-w-[220px] max-h-[200px] overflow-y-auto">
                    {assignable_users.map((u) => (
                      <Button
                        key={u.id}
                        variant="ghost"
                        onClick={() => handleAssign(u.id)}
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
          )}
        </div>

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
                        <div key={u.id} className="flex items-center gap-1.5 text-xs -mx-1 px-1 py-0.5 rounded hover:bg-muted transition-colors">
                          <div className="h-5 w-5 rounded-full bg-muted flex items-center justify-center text-xs font-medium text-muted-foreground shrink-0">
                            {u.initials}
                          </div>
                          <span className="text-foreground">{u.full_name}</span>
                          <span className="text-muted-foreground">&middot; {u.role_label}</span>
                          {u.remove_path && (
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => setConfirmRemoveUser({ name: u.full_name, path: u.remove_path! })}
                              className="h-5 w-5 p-0 ml-1 text-muted-foreground hover:text-destructive transition-colors"
                              title={`Remove ${u.full_name}`}
                            >
                              <X className="h-3 w-3" />
                            </Button>
                          )}
                        </div>
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}
      </div>

      {/* Contacts — collapsible, default open */}
      <div>
        <div className="flex items-center">
          <Button
            variant="ghost"
            onClick={() => setContactsOpen(!contactsOpen)}
            className="flex items-center gap-1.5 flex-1 justify-start -mx-1.5 px-1.5 py-1 h-auto rounded hover:bg-muted transition-colors"
          >
            <ChevronDown className={`h-3.5 w-3.5 text-muted-foreground transition-transform ${contactsOpen ? "" : "-rotate-90"}`} />
            <h3 className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">
              Contacts
            </h3>
            <span className="text-xs text-muted-foreground tabular-nums ml-auto">{incident.contacts.length}</span>
          </Button>
          {can_manage_contacts && (
            <Button variant="ghost" size="sm" className="h-6 text-xs gap-1 text-muted-foreground" onClick={() => setContactFormOpen(true)}>
              <Plus className="h-3 w-3" />
              Add
            </Button>
          )}
        </div>

        {contactsOpen && (
          <div className="mt-2 ml-5">
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
        )}
      </div>

      {/* Confirm remove user */}
      {confirmRemoveUser && (
        <div className="fixed inset-0 z-50 flex items-center justify-center">
          <div className="fixed inset-0 bg-black opacity-40" onClick={() => setConfirmRemoveUser(null)} />
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
      <div className="fixed inset-0 bg-black opacity-40" onClick={onClose} />
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
