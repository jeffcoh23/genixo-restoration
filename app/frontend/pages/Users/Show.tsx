import { useState } from "react";
import { Link, usePage, router } from "@inertiajs/react";
import AppLayout from "@/layout/AppLayout";
import PageHeader from "@/components/PageHeader";
import DetailList, { DetailRow } from "@/components/DetailList";
import StatusBadge from "@/components/StatusBadge";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
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
  first_name: string;
  last_name: string;
  email: string;
  phone: string | null;
  role_label: string;
  organization_name: string;
  timezone: string;
  active: boolean;
  is_pm_user: boolean;
  deactivate_path: string;
  reactivate_path: string;
  assigned_properties?: AssignedProperty[];
  assigned_incidents: AssignedIncident[];
}

export default function UserShow() {
  const { user, can_deactivate, routes } = usePage<SharedProps & {
    user: UserDetail;
    can_deactivate: boolean;
  }>().props;
  const [confirmDeactivate, setConfirmDeactivate] = useState(false);

  function handleDeactivate() {
    setConfirmDeactivate(false);
    router.patch(user.deactivate_path);
  }

  function handleReactivate() {
    router.patch(user.reactivate_path);
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
          {can_deactivate && user.active && (
            <Button variant="outline" onClick={() => setConfirmDeactivate(true)}>Deactivate</Button>
          )}
          {!user.active && (
            <Button variant="outline" onClick={handleReactivate}>Reactivate</Button>
          )}
        </div>
      </div>

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
          <p className="text-sm">
            Deactivate <span className="font-medium">{user.full_name}</span>? They will no longer be able to log in.
          </p>
          <div className="flex justify-end gap-2 pt-2">
            <Button variant="ghost" size="sm" onClick={() => setConfirmDeactivate(false)}>Cancel</Button>
            <Button variant="destructive" size="sm" onClick={handleDeactivate}>Deactivate</Button>
          </div>
        </DialogContent>
      </Dialog>
    </AppLayout>
  );
}
