import { Link, usePage, router } from "@inertiajs/react";
import { useState } from "react";
import AppLayout from "@/layout/AppLayout";
import PageHeader from "@/components/PageHeader";
import DetailList, { DetailRow } from "@/components/DetailList";
import StatusBadge from "@/components/StatusBadge";
import { Button } from "@/components/ui/button";
import { SharedProps } from "@/types";

interface AssignedUser {
  id: number;
  assignment_id: number;
  full_name: string;
  email: string;
  role_label: string;
  path: string;
  remove_path: string;
}

interface AssignableUser {
  id: number;
  full_name: string;
  role_label: string;
}

interface PropertyIncident {
  id: number;
  summary: string;
  status_label: string;
  path: string;
}

interface PropertyDetail {
  id: number;
  name: string;
  path: string;
  edit_path: string;
  assignments_path: string;
  address: string;
  unit_summary: string | null;
  pm_org: { id: number; name: string; path: string };
  mitigation_org: { id: number; name: string };
  assigned_users: AssignedUser[];
  incidents: PropertyIncident[];
}

export default function PropertyShow() {
  const { property, can_edit, can_assign, assignable_users, routes } = usePage<SharedProps & {
    property: PropertyDetail;
    can_edit: boolean;
    can_assign: boolean;
    assignable_users: AssignableUser[];
  }>().props;

  const [showAssignForm, setShowAssignForm] = useState(false);
  const [selectedUserId, setSelectedUserId] = useState("");

  function handleAssign() {
    if (!selectedUserId) return;
    router.post(property.assignments_path, { user_id: selectedUserId }, {
      onSuccess: () => { setSelectedUserId(""); setShowAssignForm(false); }
    });
  }

  function handleRemove(user: AssignedUser) {
    if (!confirm(`Remove ${user.full_name} from this property?`)) return;
    router.delete(user.remove_path);
  }

  return (
    <AppLayout>
      <PageHeader
        title={property.name}
        backLink={{ href: routes.properties, label: "Properties" }}
        action={can_edit ? { href: property.edit_path, label: "Edit" } : undefined}
      />

      {property.address && <p className="text-muted-foreground -mt-4 mb-2">{property.address}</p>}
      {property.unit_summary && <p className="text-sm text-muted-foreground mb-4">{property.unit_summary}</p>}

      <div className="flex gap-6 text-sm text-muted-foreground mb-8">
        <div>
          <span className="font-medium text-foreground">PM Organization:</span>{" "}
          <Link href={property.pm_org.path} className="text-primary hover:underline">{property.pm_org.name}</Link>
        </div>
        <div>
          <span className="font-medium text-foreground">Mitigation:</span> {property.mitigation_org.name}
        </div>
      </div>

      {/* Assigned Users */}
      <section className="mb-8">
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-lg font-semibold text-foreground">Assigned Users</h2>
          {can_assign && assignable_users.length > 0 && (
            <Button variant="outline" size="sm" onClick={() => setShowAssignForm(!showAssignForm)}>
              {showAssignForm ? "Cancel" : "+ Assign"}
            </Button>
          )}
        </div>

        {showAssignForm && (
          <div className="flex gap-2 mb-4">
            <select
              value={selectedUserId}
              onChange={(e) => setSelectedUserId(e.target.value)}
              className="flex h-9 w-full max-w-xs rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-xs"
            >
              <option value="">Select a user...</option>
              {assignable_users.map((u) => (
                <option key={u.id} value={u.id}>{u.full_name} ({u.role_label})</option>
              ))}
            </select>
            <Button size="sm" onClick={handleAssign} disabled={!selectedUserId}>Assign</Button>
          </div>
        )}

        <DetailList isEmpty={property.assigned_users.length === 0} emptyMessage="No users assigned to this property.">
          {property.assigned_users.map((user) => (
            <DetailRow key={user.id}>
              <div>
                <Link href={user.path} className="font-medium text-primary hover:underline">{user.full_name}</Link>
                <span className="text-sm text-muted-foreground ml-2">{user.email}</span>
              </div>
              <div className="flex items-center gap-3">
                <span className="text-sm text-muted-foreground">{user.role_label}</span>
                {can_assign && (
                  <button onClick={() => handleRemove(user)} className="text-xs text-muted-foreground hover:text-destructive transition-colors">
                    Remove
                  </button>
                )}
              </div>
            </DetailRow>
          ))}
        </DetailList>
      </section>

      {/* Incidents */}
      <section>
        <h2 className="text-lg font-semibold text-foreground mb-3">Incidents</h2>
        <DetailList isEmpty={property.incidents.length === 0} emptyMessage="No incidents for this property.">
          {property.incidents.map((incident) => (
            <DetailRow key={incident.id}>
              <Link href={incident.path} className="font-medium text-primary hover:underline">{incident.summary}</Link>
              <StatusBadge label={incident.status_label} />
            </DetailRow>
          ))}
        </DetailList>
      </section>
    </AppLayout>
  );
}
