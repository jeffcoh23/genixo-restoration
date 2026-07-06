import { useForm, usePage } from "@inertiajs/react";
import { useEffect, useMemo, useRef, useState } from "react";
import AppLayout from "@/layout/AppLayout";
import InlineActionFeedback from "@/components/InlineActionFeedback";
import PageHeader from "@/components/PageHeader";
import DataTable, { Column, LinkCell, MutedCell } from "@/components/DataTable";
import FormField from "@/components/FormField";
import FormDialog from "@/components/FormDialog";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Checkbox } from "@/components/ui/checkbox";
import { SharedProps } from "@/types";
import useInertiaAction from "@/hooks/useInertiaAction";

interface UserRow {
  id: number;
  path: string;
  full_name: string;
  email: string;
  phone: string | null;
  title: string | null;
  role_label: string;
  display_role: string;
  organization_name: string;
}

interface PendingInvitation {
  id: number;
  display_name: string;
  email: string;
  role_label: string;
  organization_name: string;
  expired: boolean;
  resend_path: string;
  cancel_path: string;
}

interface LoginRequestRow {
  id: number;
  full_name: string;
  email: string;
  first_name: string;
  last_name: string;
  company_name: string | null;
  phone: string | null;
  message: string | null;
  status: string;
  requested_at: string;
  has_user: boolean;
  has_pending_invitation: boolean;
  approve_path: string;
  reject_path: string;
}

interface RoleOption {
  value: string;
  label: string;
}

interface OrgOption {
  id: number;
  name: string;
  is_mitigation: boolean;
  role_options: RoleOption[];
}

interface PermissionOption {
  value: string;
  label: string;
}

interface NotificationOption {
  key: string;
  label: string;
  description: string;
}

export default function UsersIndex() {
  const { active_users, deactivated_users, pending_invitations, login_requests, org_options, permissions_options, role_defaults, notification_options, routes } = usePage<SharedProps & {
    active_users: UserRow[];
    deactivated_users: UserRow[];
    pending_invitations: PendingInvitation[];
    login_requests: LoginRequestRow[];
    org_options: OrgOption[];
    permissions_options: PermissionOption[];
    role_defaults: Record<string, string[]>;
    notification_options: NotificationOption[];
  }>().props;

  const [showDeactivated, setShowDeactivated] = useState(false);
  const [showInviteModal, setShowInviteModal] = useState(false);
  const resendInviteAction = useInertiaAction();
  const cancelInviteAction = useInertiaAction();

  const form = useForm({
    email: "",
    user_type: "",
    first_name: "",
    last_name: "",
    phone: "",
    title: "",
    permissions: [] as string[],
    notification_preferences: {} as Record<string, boolean>,
    organization_id: org_options[0]?.id?.toString() || "",
  });

  const selectedOrg = org_options.find((o) => o.id.toString() === form.data.organization_id);

  // Auto-fill permissions when role changes
  const prevUserType = useRef(form.data.user_type);
  useEffect(() => {
    if (form.data.user_type !== prevUserType.current) {
      prevUserType.current = form.data.user_type;
      if (form.data.user_type && role_defaults[form.data.user_type]) {
        form.setData("permissions", role_defaults[form.data.user_type]);
      }
    }
  }, [form.data.user_type, form, role_defaults]);

  const groupedActiveUsers = useMemo(
    () => active_users.reduce<Record<string, UserRow[]>>((groups, user) => {
      const org = user.organization_name;
      if (!groups[org]) groups[org] = [];
      groups[org].push(user);
      return groups;
    }, {}),
    [active_users]
  );

  function handleInvite(e: React.FormEvent) {
    e.preventDefault();
    form.post(routes.invitations, {
      onSuccess: () => {
        form.reset();
        setShowInviteModal(false);
      },
    });
  }

  // Approving a request reuses the whole invitation flow: prefill the invite
  // modal from the request. The admin still picks org/role and sends it.
  function openPrefilledInvite(req: LoginRequestRow) {
    form.setData((data) => ({
      ...data,
      email: req.email,
      first_name: req.first_name,
      last_name: req.last_name,
      phone: req.phone || "",
    }));
    setShowInviteModal(true);
  }

  const reviewAction = useInertiaAction();

  function handleApproveRequest(req: LoginRequestRow) {
    reviewAction.runPatch(req.approve_path, {}, {
      errorMessage: "Could not approve the request.",
      onSuccess: () => openPrefilledInvite(req),
    });
  }

  function handleRejectRequest(req: LoginRequestRow) {
    const reason = prompt(`Reject the request from ${req.email}? Optional reason:`);
    if (reason === null) return; // cancelled
    reviewAction.runPatch(req.reject_path, { reason }, { errorMessage: "Could not reject the request." });
  }

  const userColumns: Column<UserRow>[] = [
    {
      header: "Name",
      render: (u) => <LinkCell href={u.path}>{u.full_name}</LinkCell>,
    },
    { header: "Email", render: (u) => <MutedCell>{u.email}</MutedCell> },
    { header: "Role", render: (u) => <MutedCell>{u.display_role}</MutedCell> },
    { header: "Phone", render: (u) => <MutedCell>{u.phone || "—"}</MutedCell> },
  ];

  const deactivatedColumns: Column<UserRow>[] = [
    {
      header: "Name",
      render: (u) => <LinkCell href={u.path}>{u.full_name}</LinkCell>,
    },
    { header: "Email", render: (u) => <MutedCell>{u.email}</MutedCell> },
    { header: "Role", render: (u) => <MutedCell>{u.role_label}</MutedCell> },
    { header: "Organization", render: (u) => <MutedCell>{u.organization_name}</MutedCell> },
  ];

  return (
    <AppLayout wide>
      <PageHeader
        title="Users"
        action={{ label: "Invite User", onClick: () => setShowInviteModal(true) }}
      />

      <FormDialog
        open={showInviteModal}
        onOpenChange={setShowInviteModal}
        title="Invite User"
        description="Choose the organization first, then select one of the roles available for that organization."
        size="xl"
        onSubmit={handleInvite}
        submitLabel="Send Invitation"
        submitProcessingLabel="Sending..."
        processing={form.processing}
      >
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <FormField id="invite_email" label="Email" type="email" value={form.data.email}
            onChange={(v) => form.setData("email", v)} error={form.errors.email} required />

          {org_options.length > 1 && (
            <div className="space-y-2">
              <label className="text-sm font-medium">Organization</label>
              <Select value={form.data.organization_id} onValueChange={(v) => { form.setData("organization_id", v); form.setData("user_type", ""); }}>
                <SelectTrigger className="h-11 sm:h-10">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {org_options.map((o) => <SelectItem key={o.id} value={String(o.id)}>{o.name}</SelectItem>)}
                </SelectContent>
              </Select>
            </div>
          )}
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="space-y-2">
            <label className="text-sm font-medium">Role</label>
            <Select value={form.data.user_type} onValueChange={(v) => form.setData("user_type", v)}>
              <SelectTrigger className="h-11 sm:h-10">
                <SelectValue placeholder="Select a role..." />
              </SelectTrigger>
              <SelectContent>
                {selectedOrg?.role_options.map((r) => <SelectItem key={r.value} value={r.value}>{r.label}</SelectItem>)}
              </SelectContent>
            </Select>
            {form.errors.user_type && <p className="text-sm text-destructive mt-1">{form.errors.user_type}</p>}
            {!form.errors.user_type && (
              <p className="text-sm text-muted-foreground">Role options are scoped to the selected organization.</p>
            )}
          </div>
          <FormField id="invite_title" label="Title" value={form.data.title}
            onChange={(v) => form.setData("title", v)} />
        </div>

        <div className="grid grid-cols-2 gap-4">
          <FormField id="invite_first" label="First Name" value={form.data.first_name}
            onChange={(v) => form.setData("first_name", v)} />
          <FormField id="invite_last" label="Last Name" value={form.data.last_name}
            onChange={(v) => form.setData("last_name", v)} />
        </div>

        <FormField id="invite_phone" label="Phone" type="tel" value={form.data.phone}
          onChange={(v) => form.setData("phone", v)} />

        {form.data.user_type && selectedOrg?.is_mitigation && (
          <div className="space-y-3">
            <label className="text-sm font-medium">Permissions</label>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
              {permissions_options.map((p) => (
                <div key={p.value} className="flex items-center gap-2">
                  <Checkbox
                    id={`perm_${p.value}`}
                    checked={form.data.permissions.includes(p.value)}
                    onCheckedChange={(checked) => {
                      const next = checked
                        ? [...form.data.permissions, p.value]
                        : form.data.permissions.filter((v) => v !== p.value);
                      form.setData("permissions", next);
                    }}
                  />
                  <label htmlFor={`perm_${p.value}`} className="text-sm cursor-pointer">{p.label}</label>
                </div>
              ))}
            </div>
          </div>
        )}

        {form.data.user_type && (
          <div className="space-y-3">
            <label className="text-sm font-medium">Notification Preferences</label>
            <div className="rounded-md border border-border divide-y divide-border">
              {notification_options.map((n) => (
                <div key={n.key} className="flex items-start gap-3 px-3 py-2.5">
                  <Checkbox
                    id={`notif_${n.key}`}
                    checked={form.data.notification_preferences[n.key] || false}
                    onCheckedChange={(checked) => {
                      form.setData("notification_preferences", {
                        ...form.data.notification_preferences,
                        [n.key]: checked === true,
                      });
                    }}
                    className="mt-0.5"
                  />
                  <label htmlFor={`notif_${n.key}`} className="cursor-pointer">
                    <div className="text-sm font-medium text-foreground">{n.label}</div>
                    <div className="text-xs text-muted-foreground">{n.description}</div>
                  </label>
                </div>
              ))}
            </div>
          </div>
        )}
      </FormDialog>

      {/* Login Requests */}
      {login_requests.length > 0 && (
        <div className="mb-6">
          <h2 className="text-sm font-medium text-muted-foreground mb-2">
            Login Requests ({login_requests.length})
          </h2>
          <InlineActionFeedback error={reviewAction.error} onDismiss={reviewAction.clearFeedback} className="mb-3" />
          <DataTable
            columns={[
              { header: "Name", render: (req: LoginRequestRow) => (
                <div>
                  <div>{req.full_name}</div>
                  {req.message && (
                    <div className="text-xs text-muted-foreground max-w-[280px] truncate" title={req.message}>
                      {req.message}
                    </div>
                  )}
                </div>
              )},
              { header: "Email", render: (req) => <MutedCell>{req.email}</MutedCell> },
              { header: "Company", render: (req) => <MutedCell>{req.company_name || "—"}</MutedCell> },
              { header: "Phone", render: (req) => <MutedCell>{req.phone || "—"}</MutedCell> },
              { header: "Requested", render: (req) => <MutedCell>{req.requested_at}</MutedCell> },
              { header: "", align: "right", render: (req) => (
                <div className="flex items-center gap-2 justify-end">
                  {req.has_user ? (
                    <span className="text-sm text-muted-foreground">Already has an account</span>
                  ) : req.has_pending_invitation ? (
                    <span className="text-sm text-muted-foreground">Invitation pending</span>
                  ) : req.status === "approved" ? (
                    <>
                      <span className="text-sm text-muted-foreground">Approved</span>
                      <Button
                        variant="outline"
                        size="sm"
                        data-testid={`login-request-invite-${req.id}`}
                        onClick={() => openPrefilledInvite(req)}
                        className="h-9 sm:h-8 text-sm sm:text-xs"
                      >
                        Invite
                      </Button>
                    </>
                  ) : (
                    <>
                      <Button
                        variant="outline"
                        size="sm"
                        data-testid={`login-request-approve-${req.id}`}
                        onClick={() => handleApproveRequest(req)}
                        disabled={reviewAction.processing}
                        className="h-9 sm:h-8 text-sm sm:text-xs"
                      >
                        {reviewAction.processing ? "Working..." : "Approve"}
                      </Button>
                      <Button
                        variant="ghost"
                        size="sm"
                        data-testid={`login-request-reject-${req.id}`}
                        onClick={() => handleRejectRequest(req)}
                        disabled={reviewAction.processing}
                        className="h-9 sm:h-8 text-sm sm:text-xs text-destructive hover:text-destructive"
                      >
                        Reject
                      </Button>
                    </>
                  )}
                </div>
              )},
            ]}
            rows={login_requests}
            keyFn={(req) => req.id}
          />
        </div>
      )}

      {/* Pending Invitations */}
      {pending_invitations.length > 0 && (
        <div className="mb-6">
          <h2 className="text-sm font-medium text-muted-foreground mb-2">
            Pending Invitations ({pending_invitations.length})
          </h2>
          <InlineActionFeedback error={resendInviteAction.error || cancelInviteAction.error} onDismiss={() => { resendInviteAction.clearFeedback(); cancelInviteAction.clearFeedback(); }} className="mb-3" />
          <DataTable
            columns={[
              { header: "Name", render: (inv) => inv.display_name },
              { header: "Email", render: (inv) => <MutedCell>{inv.email}</MutedCell> },
              { header: "Role", render: (inv) => <MutedCell>{inv.role_label}</MutedCell> },
              { header: "Organization", render: (inv) => <MutedCell>{inv.organization_name}</MutedCell> },
              { header: "", align: "right", render: (inv) => (
                <div className="flex items-center gap-2 justify-end">
                  {inv.expired
                    ? <span className="text-sm text-destructive">Expired</span>
                    : <span className="text-sm text-muted-foreground">Pending</span>
                  }
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => resendInviteAction.runPatch(inv.resend_path, {}, { errorMessage: "Could not resend invitation." })}
                    disabled={resendInviteAction.processing || cancelInviteAction.processing}
                    className="h-9 sm:h-8 text-sm sm:text-xs"
                  >
                    {resendInviteAction.processing ? "Resending..." : "Resend"}
                  </Button>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => { if (confirm("Cancel this invitation?")) cancelInviteAction.runDelete(inv.cancel_path, undefined, { errorMessage: "Could not cancel invitation." }); }}
                    disabled={cancelInviteAction.processing || resendInviteAction.processing}
                    className="h-9 sm:h-8 text-sm sm:text-xs text-destructive hover:text-destructive"
                  >
                    {cancelInviteAction.processing ? "Cancelling..." : "Cancel"}
                  </Button>
                </div>
              )},
            ]}
            rows={pending_invitations}
            keyFn={(inv) => inv.id}
          />
        </div>
      )}

      {/* Active Users — grouped by organization */}
      {Object.entries(groupedActiveUsers).map(([orgName, users]) => (
        <div key={orgName} className="mb-6">
          <h2 className="text-sm font-medium text-muted-foreground mb-2">{orgName}</h2>
          <DataTable columns={userColumns} rows={users} keyFn={(u) => u.id} emptyMessage="No team members yet." />
        </div>
      ))}

      {/* Deactivated Users */}
      {deactivated_users.length > 0 && (
        <div className="mt-6">
          <Button variant="ghost" onClick={() => setShowDeactivated(!showDeactivated)}
            className="text-sm text-muted-foreground hover:text-foreground flex items-center gap-1 h-10 sm:h-8 px-2">
            <span className="text-sm">{showDeactivated ? "▼" : "▶"}</span>
            Deactivated Users ({deactivated_users.length})
          </Button>
          {showDeactivated && (
            <div className="mt-2">
              <DataTable columns={deactivatedColumns} rows={deactivated_users} keyFn={(u) => u.id} />
            </div>
          )}
        </div>
      )}

    </AppLayout>
  );
}
