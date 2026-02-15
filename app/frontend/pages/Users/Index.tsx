import { useForm, usePage, router } from "@inertiajs/react";
import { useState } from "react";
import AppLayout from "@/layout/AppLayout";
import PageHeader from "@/components/PageHeader";
import DataTable, { Column, LinkCell, MutedCell } from "@/components/DataTable";
import FormField from "@/components/FormField";
import { Button } from "@/components/ui/button";
import { SharedProps } from "@/types";

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

const userColumns: Column<UserRow>[] = [
  { header: "Name", render: (u) => <LinkCell href={u.path}>{u.full_name}</LinkCell> },
  { header: "Email", render: (u) => <MutedCell>{u.email}</MutedCell> },
  { header: "Role", render: (u) => <MutedCell>{u.role_label}</MutedCell> },
  { header: "Organization", render: (u) => <MutedCell>{u.organization_name}</MutedCell> },
  { header: "Phone", render: (u) => <MutedCell>{u.phone || "—"}</MutedCell> },
];

const deactivatedColumns: Column<UserRow>[] = [
  { header: "Name", render: (u) => <LinkCell href={u.path}>{u.full_name}</LinkCell> },
  { header: "Email", render: (u) => <MutedCell>{u.email}</MutedCell> },
  { header: "Role", render: (u) => <MutedCell>{u.role_label}</MutedCell> },
  { header: "Organization", render: (u) => <MutedCell>{u.organization_name}</MutedCell> },
];

export default function UsersIndex() {
  const { active_users, deactivated_users, pending_invitations, org_options, routes } = usePage<SharedProps & {
    active_users: UserRow[];
    deactivated_users: UserRow[];
    pending_invitations: PendingInvitation[];
    org_options: OrgOption[];
  }>().props;

  const [showDeactivated, setShowDeactivated] = useState(false);
  const [showInviteForm, setShowInviteForm] = useState(false);

  const form = useForm({
    email: "",
    user_type: "",
    first_name: "",
    last_name: "",
    phone: "",
    organization_id: org_options[0]?.id?.toString() || "",
  });

  const selectedOrg = org_options.find((o) => o.id.toString() === form.data.organization_id);

  function handleInvite(e: React.FormEvent) {
    e.preventDefault();
    form.post(routes.invitations, {
      onSuccess: () => { form.reset(); setShowInviteForm(false); },
    });
  }

  return (
    <AppLayout>
      <PageHeader
        title="Users"
        action={{ label: showInviteForm ? "Cancel" : "Invite User", onClick: () => setShowInviteForm(!showInviteForm) }}
      />

      {/* Invite User Form */}
      {showInviteForm && (
        <div className="rounded border p-6 mb-6 bg-muted">
          <h2 className="text-lg font-semibold text-foreground mb-4">Invite User</h2>
          <form onSubmit={handleInvite} className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <FormField id="invite_email" label="Email" type="email" value={form.data.email}
                onChange={(v) => form.setData("email", v)} error={form.errors.email} required />

              {org_options.length > 1 && (
                <div className="space-y-2">
                  <label htmlFor="invite_org" className="text-sm font-medium">Organization</label>
                  <select id="invite_org" value={form.data.organization_id}
                    onChange={(e) => { form.setData("organization_id", e.target.value); form.setData("user_type", ""); }}
                    className="flex h-9 w-full rounded border border-input bg-transparent px-3 py-1 text-sm shadow-sm">
                    {org_options.map((o) => <option key={o.id} value={o.id}>{o.name}</option>)}
                  </select>
                </div>
              )}

              <div className="space-y-2">
                <label htmlFor="invite_role" className="text-sm font-medium">Role</label>
                <select id="invite_role" value={form.data.user_type}
                  onChange={(e) => form.setData("user_type", e.target.value)}
                  className="flex h-9 w-full rounded border border-input bg-transparent px-3 py-1 text-sm shadow-sm" required>
                  <option value="">Select a role...</option>
                  {selectedOrg?.role_options.map((r) => <option key={r.value} value={r.value}>{r.label}</option>)}
                </select>
                {form.errors.user_type && <p className="text-sm text-destructive mt-1">{form.errors.user_type}</p>}
              </div>
            </div>

            <div className="grid grid-cols-3 gap-4">
              <FormField id="invite_first" label="First Name" hint="optional" value={form.data.first_name}
                onChange={(v) => form.setData("first_name", v)} />
              <FormField id="invite_last" label="Last Name" hint="optional" value={form.data.last_name}
                onChange={(v) => form.setData("last_name", v)} />
              <FormField id="invite_phone" label="Phone" hint="optional" type="tel" value={form.data.phone}
                onChange={(v) => form.setData("phone", v)} />
            </div>

            <div className="flex justify-end">
              <Button type="submit" disabled={form.processing}>
                {form.processing ? "Sending..." : "Send Invitation"}
              </Button>
            </div>
          </form>
        </div>
      )}

      {/* Pending Invitations */}
      {pending_invitations.length > 0 && (
        <div className="mb-6">
          <h2 className="text-sm font-medium text-muted-foreground mb-2">
            Pending Invitations ({pending_invitations.length})
          </h2>
          <DataTable
            columns={[
              { header: "Name", render: (inv) => inv.display_name },
              { header: "Email", render: (inv) => <MutedCell>{inv.email}</MutedCell> },
              { header: "Role", render: (inv) => <MutedCell>{inv.role_label}</MutedCell> },
              { header: "Organization", render: (inv) => <MutedCell>{inv.organization_name}</MutedCell> },
              { header: "", align: "right", render: (inv) => (
                <div className="flex items-center gap-2 justify-end">
                  {inv.expired
                    ? <span className="text-xs text-destructive">Expired</span>
                    : <span className="text-xs text-muted-foreground">Pending</span>
                  }
                  <Button variant="ghost" size="sm" onClick={() => router.patch(inv.resend_path)} className="text-xs text-primary hover:underline h-auto py-0 px-1">
                    Resend
                  </Button>
                </div>
              )},
            ]}
            rows={pending_invitations}
            keyFn={(inv) => inv.id}
          />
        </div>
      )}

      {/* Active Users */}
      <DataTable columns={userColumns} rows={active_users} keyFn={(u) => u.id} emptyMessage="No team members yet." />

      {/* Deactivated Users */}
      {deactivated_users.length > 0 && (
        <div className="mt-6">
          <Button variant="ghost" onClick={() => setShowDeactivated(!showDeactivated)}
            className="text-sm text-muted-foreground hover:text-foreground flex items-center gap-1 h-auto px-0 py-1">
            <span className="text-xs">{showDeactivated ? "▼" : "▶"}</span>
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
