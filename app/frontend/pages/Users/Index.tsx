import { useForm, usePage } from "@inertiajs/react";
import { useMemo, useState } from "react";
import AppLayout from "@/layout/AppLayout";
import InlineActionFeedback from "@/components/InlineActionFeedback";
import PageHeader from "@/components/PageHeader";
import DataTable, { Column, LinkCell, MutedCell } from "@/components/DataTable";
import FormField from "@/components/FormField";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { SharedProps } from "@/types";
import useInertiaAction from "@/hooks/useInertiaAction";

interface UserRow {
  id: number;
  path: string;
  full_name: string;
  email: string;
  phone: string | null;
  role_label: string;
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

interface RoleOption {
  value: string;
  label: string;
}

interface OrgOption {
  id: number;
  name: string;
  role_options: RoleOption[];
}

export default function UsersIndex() {
  const { active_users, deactivated_users, pending_invitations, org_options, routes } = usePage<SharedProps & {
    active_users: UserRow[];
    deactivated_users: UserRow[];
    pending_invitations: PendingInvitation[];
    org_options: OrgOption[];
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
    organization_id: org_options[0]?.id?.toString() || "",
  });

  const selectedOrg = org_options.find((o) => o.id.toString() === form.data.organization_id);

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

  const userColumns: Column<UserRow>[] = [
    {
      header: "Name",
      render: (u) => <LinkCell href={u.path}>{u.full_name}</LinkCell>,
    },
    { header: "Email", render: (u) => <MutedCell>{u.email}</MutedCell> },
    { header: "Role", render: (u) => <MutedCell>{u.role_label}</MutedCell> },
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

      <Dialog open={showInviteModal} onOpenChange={setShowInviteModal}>
        <DialogContent className="max-w-3xl p-0 gap-0 overflow-hidden">
          <DialogHeader className="px-6 pt-5 pb-4 border-b border-border bg-muted/30">
            <DialogTitle>Invite User</DialogTitle>
            <p className="text-sm text-muted-foreground">
              Choose the organization first, then select one of the roles available for that organization.
            </p>
          </DialogHeader>

          <form onSubmit={handleInvite} className="p-6 space-y-5">
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
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <FormField id="invite_first" label="First Name" hint="optional" value={form.data.first_name}
                onChange={(v) => form.setData("first_name", v)} />
              <FormField id="invite_last" label="Last Name" hint="optional" value={form.data.last_name}
                onChange={(v) => form.setData("last_name", v)} />
              <FormField id="invite_phone" label="Phone" hint="optional" type="tel" value={form.data.phone}
                onChange={(v) => form.setData("phone", v)} />
            </div>

            <div className="flex items-center justify-end gap-2 pt-1">
              <Button type="button" variant="outline" onClick={() => setShowInviteModal(false)}>
                Cancel
              </Button>
              <Button type="submit" disabled={form.processing}>
                {form.processing ? "Sending..." : "Send Invitation"}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>

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
