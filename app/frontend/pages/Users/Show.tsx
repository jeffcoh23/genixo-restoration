import { Link, usePage, router, useForm } from "@inertiajs/react";
import { useState } from "react";
import AppLayout from "@/layout/AppLayout";
import PageHeader from "@/components/PageHeader";
import DetailList, { DetailRow } from "@/components/DetailList";
import StatusBadge from "@/components/StatusBadge";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { SharedProps } from "@/types";

interface AssignedProperty {
  id: number;
  name: string;
  path: string;
}

interface AssignedIncident {
  id: number;
  summary: string;
  status: string;
  status_label: string;
  property_name: string;
  path: string;
}

interface UserDetail {
  id: number;
  path: string;
  full_name: string;
  user_type: string;
  first_name: string;
  last_name: string;
  email: string;
  phone: string | null;
  role_label: string;
  organization_name: string;
  timezone: string;
  active: boolean;
  is_pm_user: boolean;
  update_path: string;
  deactivate_path: string;
  reactivate_path: string;
  assigned_properties?: AssignedProperty[];
  assigned_incidents: AssignedIncident[];
}

export default function UserShow() {
  const { user, can_edit, can_edit_role, can_deactivate, role_options, routes } = usePage<SharedProps & {
    user: UserDetail;
    can_edit: boolean;
    can_edit_role: boolean;
    can_deactivate: boolean;
    role_options: { value: string; label: string }[];
  }>().props;
  const [editing, setEditing] = useState(false);
  const [confirmDeactivate, setConfirmDeactivate] = useState(false);
  const editForm = useForm({
    first_name: user.first_name,
    last_name: user.last_name,
    email_address: user.email,
    phone: user.phone || "",
    timezone: user.timezone,
    user_type: user.user_type,
  });

  function startEdit() {
    editForm.setData({
      first_name: user.first_name,
      last_name: user.last_name,
      email_address: user.email,
      phone: user.phone || "",
      timezone: user.timezone,
      user_type: user.user_type,
    });
    setEditing(true);
  }

  function handleDeactivate() {
    setConfirmDeactivate(true);
  }

  function handleReactivate() {
    router.patch(user.reactivate_path);
  }

  function confirmAndDeactivate() {
    router.patch(user.deactivate_path, {}, { onSuccess: () => setConfirmDeactivate(false) });
  }

  function handleSaveEdit(e: React.FormEvent) {
    e.preventDefault();
    editForm.patch(user.update_path, {
      onSuccess: () => setEditing(false),
    });
  }

  return (
    <AppLayout>
      <PageHeader title={user.full_name} backLink={{ href: routes.users, label: "Users" }} />

      <div className="flex items-center justify-between mb-6">
        <div>
          <div className="flex items-center gap-3">
            {!user.active && (
              <Badge variant="destructive">Deactivated</Badge>
            )}
          </div>
          <p className="text-muted-foreground mt-1">{user.role_label} at {user.organization_name}</p>
          <div className="flex gap-4 text-sm text-muted-foreground mt-1">
            <span>{user.email}</span>
            {user.phone && <span>{user.phone}</span>}
            <span>{user.timezone}</span>
          </div>
        </div>
        <div className="flex gap-2">
          {can_edit && <Button variant="outline" onClick={startEdit}>Edit</Button>}
          {can_deactivate && user.active && (
            <Button variant="outline" onClick={handleDeactivate}>Deactivate</Button>
          )}
          {!user.active && (
            <Button variant="outline" onClick={handleReactivate}>Reactivate</Button>
          )}
        </div>
      </div>

      <Dialog open={editing} onOpenChange={setEditing}>
        <DialogContent className="sm:max-w-xl">
          <DialogHeader>
            <DialogTitle>Edit User</DialogTitle>
          </DialogHeader>
          <form onSubmit={handleSaveEdit} className="space-y-4">
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="space-y-2">
                <label htmlFor="first_name" className="text-sm font-medium">First Name</label>
                <Input
                  id="first_name"
                  value={editForm.data.first_name}
                  onChange={(e) => editForm.setData("first_name", e.target.value)}
                  className="h-10"
                />
                {editForm.errors.first_name && <p className="text-sm text-destructive">{editForm.errors.first_name}</p>}
              </div>
              <div className="space-y-2">
                <label htmlFor="last_name" className="text-sm font-medium">Last Name</label>
                <Input
                  id="last_name"
                  value={editForm.data.last_name}
                  onChange={(e) => editForm.setData("last_name", e.target.value)}
                  className="h-10"
                />
                {editForm.errors.last_name && <p className="text-sm text-destructive">{editForm.errors.last_name}</p>}
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="space-y-2">
                <label htmlFor="email_address" className="text-sm font-medium">Email</label>
                <Input
                  id="email_address"
                  type="email"
                  value={editForm.data.email_address}
                  onChange={(e) => editForm.setData("email_address", e.target.value)}
                  className="h-10"
                />
                {editForm.errors.email_address && <p className="text-sm text-destructive">{editForm.errors.email_address}</p>}
              </div>
              <div className="space-y-2">
                <label htmlFor="phone" className="text-sm font-medium">Phone</label>
                <Input
                  id="phone"
                  value={editForm.data.phone}
                  onChange={(e) => editForm.setData("phone", e.target.value)}
                  className="h-10"
                />
                {editForm.errors.phone && <p className="text-sm text-destructive">{editForm.errors.phone}</p>}
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="space-y-2">
                <label className="text-sm font-medium">Role</label>
                {can_edit_role ? (
                  <>
                    <Select value={editForm.data.user_type} onValueChange={(v) => editForm.setData("user_type", v)}>
                      <SelectTrigger className="h-10">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        {role_options.map((role) => (
                          <SelectItem key={role.value} value={role.value}>{role.label}</SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    {editForm.errors.user_type && <p className="text-sm text-destructive">{editForm.errors.user_type}</p>}
                  </>
                ) : (
                  <Input value={user.role_label} disabled className="h-10" />
                )}
              </div>
              <div className="space-y-2">
                <label htmlFor="timezone" className="text-sm font-medium">Timezone</label>
                <Input
                  id="timezone"
                  value={editForm.data.timezone}
                  onChange={(e) => editForm.setData("timezone", e.target.value)}
                  className="h-10"
                />
                {editForm.errors.timezone && <p className="text-sm text-destructive">{editForm.errors.timezone}</p>}
              </div>
            </div>

            <div className="flex justify-end gap-2 pt-1">
              <Button type="button" variant="ghost" onClick={() => setEditing(false)}>Cancel</Button>
              <Button type="submit" disabled={editForm.processing}>
                {editForm.processing ? "Saving..." : "Save Changes"}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>

      {/* Property Assignments (PM users only) */}
      <section className="mb-8">
        <h2 className="text-lg font-semibold text-foreground mb-3">Property Assignments</h2>
        {!user.is_pm_user ? (
          <p className="text-sm text-muted-foreground">Not applicable — mitigation user.</p>
        ) : (
          <DetailList isEmpty={!user.assigned_properties?.length} emptyMessage="No properties assigned.">
            {user.assigned_properties?.map((p) => (
              <DetailRow key={p.id}>
                <Link href={p.path} className="font-medium text-primary hover:underline">{p.name}</Link>
              </DetailRow>
            ))}
          </DetailList>
        )}
      </section>

      {/* Active Incidents */}
      <section>
        <h2 className="text-lg font-semibold text-foreground mb-3">Active Incidents</h2>
        <DetailList isEmpty={user.assigned_incidents.length === 0} emptyMessage="No active incidents assigned.">
          {user.assigned_incidents.map((i) => (
            <DetailRow key={i.id}>
              <div>
                <Link href={i.path} className="font-medium text-primary hover:underline">{i.summary}</Link>
                <span className="text-sm text-muted-foreground ml-2">{i.property_name}</span>
              </div>
              <StatusBadge status={i.status} label={i.status_label} />
            </DetailRow>
          ))}
        </DetailList>
      </section>

      <Dialog open={confirmDeactivate} onOpenChange={setConfirmDeactivate}>
        <DialogContent className="sm:max-w-sm">
          <DialogHeader>
            <DialogTitle>Deactivate User</DialogTitle>
          </DialogHeader>
          <p className="text-sm text-muted-foreground">
            Deactivate <span className="font-medium text-foreground">{user.full_name}</span>? They will no longer be able to sign in.
          </p>
          <div className="flex justify-end gap-2 pt-2">
            <Button type="button" variant="ghost" onClick={() => setConfirmDeactivate(false)}>Cancel</Button>
            <Button type="button" variant="destructive" onClick={confirmAndDeactivate}>Deactivate</Button>
          </div>
        </DialogContent>
      </Dialog>
    </AppLayout>
  );
}
