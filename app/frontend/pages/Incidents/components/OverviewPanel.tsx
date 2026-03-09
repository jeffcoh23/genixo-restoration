import { useState } from "react";
import { router, useForm } from "@inertiajs/react";
import { Bell, ChevronDown, Mail, Pencil, Phone, Plus, UserPlus, X } from "lucide-react";
import InlineActionFeedback from "@/components/InlineActionFeedback";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { extractInertiaErrorMessage } from "@/hooks/useInertiaAction";
import useInertiaAction from "@/hooks/useInertiaAction";
import type { Contact, IncidentDetail, AssignableUser, TeamUser, GuestUser } from "../types";

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
  const teamAction = useInertiaAction();
  const contactAction = useInertiaAction();

  const handleAssign = (userId: number) => {
    if (teamAction.processing) return;
    teamAction.runPost(incident.assignments_path, { user_id: userId }, {
      errorMessage: "Could not assign user to this incident.",
    });
  };

  const handleRemove = () => {
    if (!confirmRemoveUser) return;
    teamAction.runDelete(confirmRemoveUser.path, undefined, {
      errorMessage: "Could not remove user from this incident.",
      onSuccess: () => setConfirmRemoveUser(null),
    });
  };

  const handleRemoveContact = (removePath: string) => {
    if (contactAction.processing) return;
    contactAction.runDelete(removePath, undefined, {
      errorMessage: "Could not remove contact.",
    });
  };

  return (
    <div className="overflow-y-auto h-full p-4 bg-background">
      <div className="mx-auto grid max-w-[1800px] grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4 items-start">
        {/* Column 1: Mitigation Team */}
        <section className="rounded-xl border border-border bg-card shadow-sm p-4 space-y-3">
            <div className="flex items-center gap-2">
              <h3 className="text-sm font-semibold text-foreground flex-1 whitespace-nowrap">
                Mitigation Team <span className="text-muted-foreground tabular-nums">{incident.mitigation_team.length}</span>
              </h3>
              {can_assign && assignable_mitigation_users.length > 0 && (
                <AssignSelect users={assignable_mitigation_users} onAssign={handleAssign} disabled={teamAction.processing} />
              )}
            </div>
            <InlineActionFeedback error={teamAction.error} onDismiss={teamAction.clearFeedback} />

            {incident.mitigation_team.length === 0 ? (
              <p className="text-muted-foreground text-sm">No team members assigned.</p>
            ) : (
                <UserList
                  users={incident.mitigation_team}
                  onRemove={(name, path) => setConfirmRemoveUser({ name, path })}
                  actionsDisabled={teamAction.processing}
                />
              )}
        </section>

        {/* Column 2: Property Management */}
        <section className="rounded-xl border border-border bg-card shadow-sm p-4 space-y-3">
          <div className="flex items-center gap-2">
            <h3 className="text-sm font-semibold text-foreground flex-1 whitespace-nowrap">
              Property Management <span className="text-muted-foreground tabular-nums">{incident.pm_team.length}</span>
            </h3>
            {can_assign && assignable_pm_users.length > 0 && (
              <AssignSelect users={assignable_pm_users} onAssign={handleAssign} disabled={teamAction.processing} />
            )}
          </div>
          <InlineActionFeedback error={teamAction.error} onDismiss={teamAction.clearFeedback} />

          {incident.pm_team.length === 0 ? (
            <p className="text-muted-foreground text-sm">No PM team members assigned.</p>
          ) : (
            <UserList
              users={incident.pm_team}
              onRemove={(name, path) => setConfirmRemoveUser({ name, path })}
              actionsDisabled={teamAction.processing}
            />
          )}
        </section>

        {/* Column 3: Contacts */}
        <section className="rounded-xl border border-border bg-card shadow-sm p-4 space-y-3">
          <div className="flex items-center gap-2">
            <h3 className="text-sm font-semibold text-foreground flex-1 whitespace-nowrap">
              Contacts <span className="text-muted-foreground tabular-nums">{incident.contacts.length}</span>
            </h3>
            {can_manage_contacts && (
              <Button variant="outline" size="sm" className="h-10 sm:h-8 text-sm sm:text-xs gap-1.5" onClick={() => setContactFormOpen(true)}>
                <Plus className="h-3 w-3" />
                Add
              </Button>
            )}
          </div>
          <InlineActionFeedback error={contactAction.error} onDismiss={contactAction.clearFeedback} />

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
                          disabled={contactAction.processing}
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
                          disabled={contactAction.processing}
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

        {/* Column 4: External Guests */}
        <section className="rounded-xl border border-border bg-card shadow-sm p-4 space-y-3">
          <div className="flex items-center gap-2">
            <h3 className="text-sm font-semibold text-foreground flex-1 whitespace-nowrap">
              External <span className="text-muted-foreground tabular-nums">{incident.guest_team.length}</span>
            </h3>
            {can_assign && (
              <InviteGuestButton
                guestAssignmentsPath={incident.guest_assignments_path}
                processing={teamAction.processing}
              />
            )}
          </div>
          <InlineActionFeedback error={teamAction.error} onDismiss={teamAction.clearFeedback} />

          {incident.guest_team.length === 0 ? (
            <p className="text-muted-foreground text-sm">No external guests.</p>
          ) : (
            <GuestList
              guests={incident.guest_team}
              onRemove={(name, path) => setConfirmRemoveUser({ name, path })}
              actionsDisabled={teamAction.processing}
            />
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
            <Button variant="destructive" size="sm" onClick={handleRemove} disabled={teamAction.processing}>
              {teamAction.processing ? "Removing..." : "Remove"}
            </Button>
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

function AssignSelect({ users, onAssign, disabled = false }: {
  users: AssignableUser[];
  onAssign: (userId: number) => void;
  disabled?: boolean;
}) {
  const [value, setValue] = useState("");

  return (
    <Select
      value={value}
      disabled={disabled}
      onValueChange={(next) => {
        if (disabled) return;
        setValue("");
        onAssign(Number(next));
      }}
    >
      <SelectTrigger className="h-10 sm:h-8 w-[190px] text-sm sm:text-xs bg-background" disabled={disabled}>
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

function NotificationOverridesDialog({ user, onClose }: { user: TeamUser; onClose: () => void }) {
  const path = user.notification_overrides_path!;
  const overrides = user.notification_overrides;
  const global = user.global_preferences;

  const hasStatusOverride = "status_change" in overrides;
  const hasMessageOverride = "new_message" in overrides;

  const effectiveStatus = hasStatusOverride ? overrides.status_change : global.status_change;
  const effectiveMessage = hasMessageOverride ? overrides.new_message : global.new_message;

  const [statusChange, setStatusChange] = useState(effectiveStatus);
  const [newMessage, setNewMessage] = useState(effectiveMessage);
  const [submitting, setSubmitting] = useState(false);

  const hasOverrides = hasStatusOverride || hasMessageOverride;

  const handleSave = () => {
    setSubmitting(true);
    router.patch(path, {
      status_change: statusChange ? "1" : "0",
      new_message: newMessage ? "1" : "0",
    }, {
      preserveScroll: true,
      onFinish: () => { setSubmitting(false); onClose(); },
    });
  };

  const handleReset = () => {
    setSubmitting(true);
    router.patch(path, {}, {
      preserveScroll: true,
      onFinish: () => { setSubmitting(false); onClose(); },
    });
  };

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="sm:max-w-sm">
        <DialogHeader>
          <DialogTitle>Notification Preferences</DialogTitle>
        </DialogHeader>
        <p className="text-xs text-muted-foreground -mt-1">
          Override your global notification settings for this incident.
        </p>
        <div className="space-y-3 pt-1">
          <label className="flex items-center gap-2.5 cursor-pointer">
            <Checkbox
              checked={statusChange}
              onCheckedChange={(checked) => setStatusChange(checked === true)}
            />
            <span className="text-sm">
              Status changes
              {!hasStatusOverride && <span className="text-muted-foreground ml-1">(default)</span>}
            </span>
          </label>
          <label className="flex items-center gap-2.5 cursor-pointer">
            <Checkbox
              checked={newMessage}
              onCheckedChange={(checked) => setNewMessage(checked === true)}
            />
            <span className="text-sm">
              New messages
              {!hasMessageOverride && <span className="text-muted-foreground ml-1">(default)</span>}
            </span>
          </label>
        </div>
        <div className="flex items-center justify-between pt-2">
          {hasOverrides ? (
            <Button variant="ghost" size="sm" onClick={handleReset} disabled={submitting} className="text-muted-foreground text-xs">
              Reset to defaults
            </Button>
          ) : <div />}
          <div className="flex gap-2">
            <Button variant="ghost" size="sm" onClick={onClose} disabled={submitting}>Cancel</Button>
            <Button size="sm" onClick={handleSave} disabled={submitting}>
              {submitting ? "Saving..." : "Save"}
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}

function UserList({ users, onRemove, actionsDisabled = false }: {
  users: TeamUser[];
  onRemove: (name: string, path: string) => void;
  actionsDisabled?: boolean;
}) {
  const [expandedId, setExpandedId] = useState<number | null>(null);
  const [notifUser, setNotifUser] = useState<TeamUser | null>(null);

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
          <div className="space-y-1">
            {group.users.map((u) => {
              const isExpanded = expandedId === u.id;
              const hasContact = !!(u.email || u.phone);

              return (
                <div key={u.id} className="rounded-md border border-border bg-background overflow-hidden">
                  <div
                    className={`flex items-center gap-2 px-2 py-1.5 text-sm ${hasContact ? "cursor-pointer hover:bg-muted/25 transition-colors" : ""}`}
                    onClick={() => hasContact && setExpandedId(isExpanded ? null : u.id)}
                  >
                    <div className="h-6 w-6 rounded-full bg-muted/70 flex items-center justify-center text-xs font-medium text-muted-foreground shrink-0">
                      {u.initials}
                    </div>
                    <span className="text-foreground truncate flex-1">{u.full_name}</span>
                    {hasContact && (
                      <ChevronDown className={`h-3 w-3 text-muted-foreground shrink-0 transition-transform duration-150 ${isExpanded ? "rotate-180" : ""}`} />
                    )}
                    <div className="flex items-center gap-0.5 shrink-0">
                      {u.notification_overrides_path && (
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => setNotifUser(u)}
                          className="h-8 w-8 sm:h-7 sm:w-7 p-0 text-muted-foreground hover:text-foreground transition-colors"
                          title="Notification preferences"
                        >
                          <Bell className="h-3 w-3" />
                        </Button>
                      )}
                      {u.remove_path && (
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => onRemove(u.full_name, u.remove_path!)}
                          disabled={actionsDisabled}
                          className="h-8 w-8 sm:h-7 sm:w-7 p-0 text-muted-foreground hover:text-destructive transition-colors"
                          title={`Remove ${u.full_name}`}
                        >
                          <X className="h-3 w-3" />
                        </Button>
                      )}
                    </div>
                  </div>

                  {isExpanded && hasContact && (
                    <div className="flex flex-wrap items-center gap-x-4 gap-y-1 px-2 pb-2 ml-8 text-xs text-muted-foreground">
                      {u.email && (
                        <a href={`mailto:${u.email}`} className="flex items-center gap-1.5 hover:text-foreground transition-colors">
                          <Mail className="h-3 w-3" />
                          {u.email}
                        </a>
                      )}
                      {u.phone && (
                        <a href={`tel:${u.phone_raw}`} className="flex items-center gap-1.5 hover:text-foreground transition-colors">
                          <Phone className="h-3 w-3" />
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

      {notifUser && (
        <NotificationOverridesDialog user={notifUser} onClose={() => setNotifUser(null)} />
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
  const [submitError, setSubmitError] = useState<string | null>(null);
  const form = useForm({
    name: contact?.name ?? "",
    title: contact?.title ?? "",
    email: contact?.email ?? "",
    phone: contact?.phone ?? "",
    onsite: contact?.onsite ?? false,
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitError(null);
    if (editing && contact?.update_path) {
      form.clearErrors();
      form.transform((data) => ({ contact: data }));
      form.patch(contact.update_path, {
        preserveScroll: true,
        onSuccess: onClose,
        onError: (errors: Record<string, unknown>) => setSubmitError(extractInertiaErrorMessage(errors, "Could not save contact.")),
      });
    } else {
      form.clearErrors();
      form.transform((data) => ({ contact: data }));
      form.post(contacts_path, {
        preserveScroll: true,
        onSuccess: onClose,
        onError: (errors: Record<string, unknown>) => setSubmitError(extractInertiaErrorMessage(errors, "Could not add contact.")),
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
          <InlineActionFeedback error={submitError} onDismiss={() => setSubmitError(null)} />
          <div>
            <label className="text-xs font-medium text-muted-foreground">
              Name <span className="text-destructive">*</span>
            </label>
            <Input
              value={form.data.name}
              onChange={(e) => { if (submitError) setSubmitError(null); form.setData("name", e.target.value); }}
              placeholder="Contact name"
              className="mt-1"
              required
            />
            {form.errors.name && <p className="text-xs text-destructive mt-1">{form.errors.name}</p>}
          </div>

          <div>
            <label className="text-xs font-medium text-muted-foreground">
              Title <span className="text-muted-foreground font-normal">(optional)</span>
            </label>
            <Input
              value={form.data.title}
              onChange={(e) => { if (submitError) setSubmitError(null); form.setData("title", e.target.value); }}
              placeholder="e.g. Property Manager"
              className="mt-1"
            />
            {form.errors.title && <p className="text-xs text-destructive mt-1">{form.errors.title}</p>}
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-xs font-medium text-muted-foreground">
                Email <span className="text-muted-foreground font-normal">(optional)</span>
              </label>
              <Input
                type="email"
                value={form.data.email}
                onChange={(e) => { if (submitError) setSubmitError(null); form.setData("email", e.target.value); }}
                className="mt-1"
              />
              {form.errors.email && <p className="text-xs text-destructive mt-1">{form.errors.email}</p>}
            </div>
            <div>
              <label className="text-xs font-medium text-muted-foreground">
                Phone <span className="text-muted-foreground font-normal">(optional)</span>
              </label>
              <Input
                type="tel"
                value={form.data.phone}
                onChange={(e) => { if (submitError) setSubmitError(null); form.setData("phone", e.target.value); }}
                className="mt-1"
              />
              {form.errors.phone && <p className="text-xs text-destructive mt-1">{form.errors.phone}</p>}
            </div>
          </div>

          <label className="flex items-center gap-2 text-xs cursor-pointer">
            <Checkbox
              checked={form.data.onsite}
              onCheckedChange={(checked) => {
                if (submitError) setSubmitError(null);
                form.setData("onsite", checked === true);
              }}
            />
            Onsite contact
          </label>
          {form.errors.onsite && <p className="text-xs text-destructive -mt-2">{form.errors.onsite}</p>}

          <div className="flex justify-end gap-2 pt-2">
            <Button type="button" variant="ghost" size="sm" onClick={onClose} disabled={form.processing}>Cancel</Button>
            <Button type="submit" size="sm" disabled={form.processing}>
              {form.processing ? "Saving..." : editing ? "Save" : "Add Contact"}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}

function InviteGuestButton({ guestAssignmentsPath, processing }: {
  guestAssignmentsPath: string;
  processing: boolean;
}) {
  const [open, setOpen] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const form = useForm({
    email: "",
    first_name: "",
    last_name: "",
    title: "",
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitError(null);
    form.post(guestAssignmentsPath, {
      preserveScroll: true,
      onSuccess: () => { setOpen(false); form.reset(); },
      onError: (errors: Record<string, unknown>) => setSubmitError(extractInertiaErrorMessage(errors, "Could not invite guest.")),
    });
  };

  return (
    <>
      <Button variant="outline" size="sm" className="h-10 sm:h-8 text-sm sm:text-xs gap-1.5" onClick={() => setOpen(true)}>
        <UserPlus className="h-3 w-3" />
        Invite
      </Button>
      <Dialog open={open} onOpenChange={(o) => { if (!o) { setOpen(false); setSubmitError(null); } }}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Invite External Guest</DialogTitle>
          </DialogHeader>
          <form onSubmit={handleSubmit} className="space-y-3">
            <InlineActionFeedback error={submitError} onDismiss={() => setSubmitError(null)} />
            <div>
              <label className="text-xs font-medium text-muted-foreground">
                Email <span className="text-destructive">*</span>
              </label>
              <Input
                type="email"
                value={form.data.email}
                onChange={(e) => form.setData("email", e.target.value)}
                placeholder="adjuster@insurance.com"
                className="mt-1"
                required
              />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-xs font-medium text-muted-foreground">
                  First Name <span className="text-destructive">*</span>
                </label>
                <Input
                  value={form.data.first_name}
                  onChange={(e) => form.setData("first_name", e.target.value)}
                  className="mt-1"
                  required
                />
              </div>
              <div>
                <label className="text-xs font-medium text-muted-foreground">
                  Last Name <span className="text-destructive">*</span>
                </label>
                <Input
                  value={form.data.last_name}
                  onChange={(e) => form.setData("last_name", e.target.value)}
                  className="mt-1"
                  required
                />
              </div>
            </div>
            <div>
              <label className="text-xs font-medium text-muted-foreground">
                Title <span className="text-muted-foreground font-normal">(optional)</span>
              </label>
              <Input
                value={form.data.title}
                onChange={(e) => form.setData("title", e.target.value)}
                placeholder="e.g. Insurance Adjuster, Building Owner"
                className="mt-1"
              />
            </div>
            <div className="flex justify-end gap-2 pt-2">
              <Button type="button" variant="ghost" size="sm" onClick={() => setOpen(false)} disabled={form.processing}>Cancel</Button>
              <Button type="submit" size="sm" disabled={form.processing || processing}>
                {form.processing ? "Inviting..." : "Invite Guest"}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>
    </>
  );
}

function GuestList({ guests, onRemove, actionsDisabled = false }: {
  guests: GuestUser[];
  onRemove: (name: string, path: string) => void;
  actionsDisabled?: boolean;
}) {
  const [expandedId, setExpandedId] = useState<number | null>(null);

  return (
    <div className="space-y-1">
      {guests.map((g) => {
        const isExpanded = expandedId === g.id;
        const hasContact = !!(g.email || g.phone);

        return (
          <div key={g.id} className="rounded-md border border-border bg-background overflow-hidden">
            <div
              className={`flex items-center gap-2 px-2 py-1.5 text-sm ${hasContact ? "cursor-pointer hover:bg-muted/25 transition-colors" : ""}`}
              onClick={() => hasContact && setExpandedId(isExpanded ? null : g.id)}
            >
              <div className="h-6 w-6 rounded-full bg-muted/70 flex items-center justify-center text-xs font-medium text-muted-foreground shrink-0">
                {g.initials}
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-1.5">
                  <span className="text-foreground truncate">{g.full_name}</span>
                  {g.pending && <span className="text-xs font-medium text-amber-600 bg-amber-50 px-1.5 py-0.5 rounded">Pending</span>}
                </div>
                {g.title && <span className="text-xs text-muted-foreground">{g.title}</span>}
              </div>
              {hasContact && (
                <ChevronDown className={`h-3 w-3 text-muted-foreground shrink-0 transition-transform duration-150 ${isExpanded ? "rotate-180" : ""}`} />
              )}
              {g.remove_path && (
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={(e) => { e.stopPropagation(); onRemove(g.full_name, g.remove_path!); }}
                  disabled={actionsDisabled}
                  className="h-8 w-8 sm:h-7 sm:w-7 p-0 text-muted-foreground hover:text-destructive transition-colors shrink-0"
                  title={`Remove ${g.full_name}`}
                >
                  <X className="h-3 w-3" />
                </Button>
              )}
            </div>

            {isExpanded && hasContact && (
              <div className="flex flex-wrap items-center gap-x-4 gap-y-1 px-2 pb-2 ml-8 text-xs text-muted-foreground">
                {g.email && (
                  <a href={`mailto:${g.email}`} className="flex items-center gap-1.5 hover:text-foreground transition-colors">
                    <Mail className="h-3 w-3" />
                    {g.email}
                  </a>
                )}
                {g.phone && (
                  <a href={`tel:${g.phone_raw}`} className="flex items-center gap-1.5 hover:text-foreground transition-colors">
                    <Phone className="h-3 w-3" />
                    {g.phone}
                  </a>
                )}
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
}
