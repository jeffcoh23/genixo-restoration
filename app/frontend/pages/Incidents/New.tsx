import { Link, useForm, usePage } from "@inertiajs/react";
import { FormEvent, useRef, useState } from "react";
import { AlertTriangle, Building2, Check, Plus, Trash2 } from "lucide-react";
import AppLayout from "@/layout/AppLayout";
import PageHeader from "@/components/PageHeader";
import FormField from "@/components/FormField";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { SharedProps } from "@/types";
import type { NewIncidentProps, NewIncidentAssignableUser } from "./types";

interface ContactRow {
  name: string;
  title: string;
  email: string;
  phone: string;
  onsite: boolean;
}

export default function NewIncident() {
  const { properties, organizations = [], project_types, damage_types, can_assign, can_manage_contacts, property_users = {}, routes } =
    usePage<SharedProps & NewIncidentProps>().props;

  const [selectedOrgId, setSelectedOrgId] = useState(() => {
    if (organizations.length === 1) return String(organizations[0].id);
    if (properties.length === 1) return String(properties[0].organization_id);
    return "";
  });

  const filteredProperties = selectedOrgId
    ? properties.filter((p) => String(p.organization_id) === selectedOrgId)
    : properties;

  const { data, setData, post, processing, errors, transform } = useForm({
    property_id: properties.length === 1 ? String(properties[0].id) : "",
    job_id: "",
    project_type: "",
    damage_type: "",
    description: "",
    cause: "",
    requested_next_steps: "",
    units_affected: "",
    affected_room_numbers: "",
    location_of_damage: "",
    do_not_exceed_limit: "",
    additional_user_ids: [] as number[],
  });

  const [contacts, setContacts] = useState<ContactRow[]>([]);
  const scrollLockRef = useRef(false);

  const isEmergency = data.project_type === "emergency_response";

  // Users for the currently selected property, split by org type
  const currentUsers: NewIncidentAssignableUser[] = data.property_id ? (property_users[data.property_id] || []) : [];
  const mitigationUsers = currentUsers.filter((u) => u.org_type === "mitigation");
  const pmUsers = currentUsers.filter((u) => u.org_type === "pm");

  const handleOrgChange = (orgId: string) => {
    setSelectedOrgId(orgId);
    // Clear property selection when org changes
    setData((prev) => ({
      ...prev,
      property_id: "",
      additional_user_ids: [],
      location_of_damage: "",
    }));
  };

  const handlePropertyChange = (propertyId: string) => {
    const users = propertyId ? (property_users[propertyId] || []) : [];
    const autoIds = users.filter((u) => u.auto_assign).map((u) => u.id);
    const property = properties.find((p) => String(p.id) === propertyId);
    setData((prev) => ({
      ...prev,
      property_id: propertyId,
      additional_user_ids: autoIds,
      location_of_damage: property?.address || "",
    }));
  };

  const toggleUser = (userId: number) => {
    scrollLockRef.current = true;
    const scrollY = window.scrollY;
    const current = data.additional_user_ids;
    if (current.includes(userId)) {
      setData("additional_user_ids", current.filter((id) => id !== userId));
    } else {
      setData("additional_user_ids", [...current, userId]);
    }
    requestAnimationFrame(() => {
      window.scrollTo(0, scrollY);
      scrollLockRef.current = false;
    });
  };

  const addContactRow = () => {
    setContacts([...contacts, { name: "", title: "", email: "", phone: "", onsite: false }]);
  };

  const updateContact = (index: number, field: keyof ContactRow, value: string) => {
    const updated = [...contacts];
    updated[index] = { ...updated[index], [field]: value };
    setContacts(updated);
  };

  const removeContact = (index: number) => {
    setContacts(contacts.filter((_, i) => i !== index));
  };

  function handleSubmit(e: FormEvent) {
    e.preventDefault();
    transform((formData) => ({
      ...formData,
      contacts: contacts.filter((c) => c.name.trim() !== ""),
    }));
    post(routes.incidents);
  }

  return (
    <AppLayout>
      <PageHeader title="Create Request" backLink={{ href: routes.incidents, label: "Incidents" }} />

      <form onSubmit={handleSubmit} className="max-w-2xl mx-auto bg-card border border-border rounded shadow-sm p-6 space-y-5">
        {/* Organization */}
        {organizations.length > 1 && (
          <div className="space-y-2">
            <Label>Organization *</Label>
            <Select value={selectedOrgId} onValueChange={handleOrgChange}>
              <SelectTrigger>
                <SelectValue placeholder="Select an organization..." />
              </SelectTrigger>
              <SelectContent>
                {organizations.map((o) => (
                  <SelectItem key={o.id} value={String(o.id)}>{o.name}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        )}

        {/* Property */}
        <div className="space-y-2">
          <Label>Property *</Label>
          <Select value={data.property_id} onValueChange={handlePropertyChange}>
            <SelectTrigger>
              <SelectValue placeholder="Select a property..." />
            </SelectTrigger>
            <SelectContent>
              {filteredProperties.map((p) => (
                <SelectItem key={p.id} value={String(p.id)}>{p.name}</SelectItem>
              ))}
            </SelectContent>
          </Select>
          {errors.property_id && <p className="text-sm text-destructive">{errors.property_id}</p>}
        </div>

        {/* Job ID */}
        <FormField
          id="job_id"
          label="Job ID"
          value={data.job_id}
          onChange={(v) => setData("job_id", v)}
          error={errors.job_id}
          hint="Optional reference number"
        />

        {/* Project Type — radio cards */}
        <fieldset className="space-y-2">
          <Label asChild><legend>Project Type *</legend></Label>
          <div className="grid grid-cols-2 gap-2">
            {project_types.map((pt) => (
              <label
                key={pt.value}
                className={`flex items-center gap-2 rounded border px-3 py-2.5 text-sm cursor-pointer transition-colors ${
                  data.project_type === pt.value
                    ? "border-primary bg-accent text-accent-foreground"
                    : "border-input bg-background text-foreground hover:bg-muted"
                }`}
              >
                <Input
                  type="radio"
                  name="project_type"
                  value={pt.value}
                  checked={data.project_type === pt.value}
                  onChange={(e) => setData("project_type", e.target.value)}
                  className="sr-only"
                />
                <span className={`h-3.5 w-3.5 rounded-full border-2 flex items-center justify-center flex-shrink-0 ${
                  data.project_type === pt.value ? "border-primary" : "border-muted-foreground"
                }`}>
                  {data.project_type === pt.value && (
                    <span className="h-1.5 w-1.5 rounded-full bg-primary" />
                  )}
                </span>
                {pt.label}
              </label>
            ))}
          </div>
          {errors.project_type && <p className="text-sm text-destructive">{errors.project_type}</p>}
        </fieldset>

        {/* Emergency warning */}
        {isEmergency && (
          <div className="flex items-start gap-3 rounded border border-status-warning/40 bg-status-warning/10 p-3 text-sm text-status-warning-foreground">
            <AlertTriangle className="h-5 w-5 flex-shrink-0 text-status-warning mt-0.5" />
            <p>This will trigger the emergency escalation chain and notify the on-call team immediately.</p>
          </div>
        )}

        {/* Damage Type */}
        <div className="space-y-2">
          <Label>Damage Type *</Label>
          <Select value={data.damage_type} onValueChange={(v) => setData("damage_type", v)}>
            <SelectTrigger>
              <SelectValue placeholder="Select damage type..." />
            </SelectTrigger>
            <SelectContent>
              {damage_types.map((dt) => (
                <SelectItem key={dt.value} value={dt.value}>{dt.label}</SelectItem>
              ))}
            </SelectContent>
          </Select>
          {errors.damage_type && <p className="text-sm text-destructive">{errors.damage_type}</p>}
        </div>

        {/* Location of Damage */}
        <div className="space-y-2">
          <Label htmlFor="location_of_damage">Location of Damage</Label>
          <Textarea
            id="location_of_damage"
            rows={2}
            value={data.location_of_damage}
            onChange={(e) => setData("location_of_damage", e.target.value)}
            placeholder="Address and area affected..."
          />
          {errors.location_of_damage && <p className="text-sm text-destructive">{errors.location_of_damage}</p>}
        </div>

        {/* Emergency Do Not Exceed Limit */}
        <FormField
          id="do_not_exceed_limit"
          label="Emergency Do Not Exceed Limit"
          value={data.do_not_exceed_limit}
          onChange={(v) => setData("do_not_exceed_limit", v)}
          error={errors.do_not_exceed_limit}
          hint="Dollar amount, if applicable"
        />

        {/* Description */}
        <div className="space-y-2">
          <Label htmlFor="description">Description *</Label>
          <Textarea
            id="description"
            rows={6}
            value={data.description}
            onChange={(e) => setData("description", e.target.value)}
            placeholder="Describe the damage and situation..."
          />
          {errors.description && <p className="text-sm text-destructive">{errors.description}</p>}
        </div>

        {/* Cause */}
        <div className="space-y-2">
          <Label htmlFor="cause">Cause</Label>
          <Textarea
            id="cause"
            rows={4}
            value={data.cause}
            onChange={(e) => setData("cause", e.target.value)}
            placeholder="Known cause of the damage, if any..."
          />
          {errors.cause && <p className="text-sm text-destructive">{errors.cause}</p>}
        </div>

        {/* Requested Next Steps */}
        <div className="space-y-2">
          <Label htmlFor="requested_next_steps">Requested Next Steps</Label>
          <Textarea
            id="requested_next_steps"
            rows={4}
            value={data.requested_next_steps}
            onChange={(e) => setData("requested_next_steps", e.target.value)}
            placeholder="What would you like us to do first?"
          />
          {errors.requested_next_steps && <p className="text-sm text-destructive">{errors.requested_next_steps}</p>}
        </div>

        {/* Units + Room Numbers side by side */}
        <div className="grid grid-cols-2 gap-4">
          <FormField
            id="units_affected"
            label="Units Affected"
            type="number"
            value={data.units_affected}
            onChange={(v) => setData("units_affected", v)}
            error={errors.units_affected}
          />
          <FormField
            id="affected_room_numbers"
            label="Room Numbers"
            value={data.affected_room_numbers}
            onChange={(v) => setData("affected_room_numbers", v)}
            error={errors.affected_room_numbers}
            hint="e.g. 101, 102, 205"
          />
        </div>

        {/* Assign Team Members — only shown after property is selected */}
        {can_assign && data.property_id && currentUsers.length > 0 && (
          <fieldset className="space-y-3">
            <Label asChild><legend>Assign Team Members</legend></Label>
            <p className="text-xs text-muted-foreground">Checked members will be auto-assigned. Uncheck to remove, or check additional people.</p>

            {mitigationUsers.length > 0 && (
              <UserChecklistSection
                label="Mitigation Team"
                users={mitigationUsers}
                selectedIds={data.additional_user_ids}
                onToggle={toggleUser}
              />
            )}

            {pmUsers.length > 0 && (
              <UserChecklistSection
                label="Property Management Team"
                users={pmUsers}
                selectedIds={data.additional_user_ids}
                onToggle={toggleUser}
              />
            )}

            <p className="text-xs text-muted-foreground">{data.additional_user_ids.length} member{data.additional_user_ids.length !== 1 ? "s" : ""} selected</p>
          </fieldset>
        )}

        {/* Contacts */}
        {can_manage_contacts && (
          <fieldset className="space-y-2">
            <Label asChild><legend>Contacts</legend></Label>
            {contacts.map((contact, index) => (
              <div key={index} className="rounded border border-input p-3 space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-medium text-muted-foreground">Contact {index + 1}</span>
                  <Button type="button" variant="ghost" size="sm" className="h-8 w-8 sm:h-6 sm:w-6 p-0 text-muted-foreground hover:text-destructive" onClick={() => removeContact(index)} aria-label={`Remove contact ${index + 1}`}>
                    <Trash2 className="h-3.5 w-3.5 sm:h-3 sm:w-3" />
                  </Button>
                </div>
                <Input
                  type="text"
                  placeholder="Name *"
                  value={contact.name}
                  onChange={(e) => updateContact(index, "name", e.target.value)}
                  className="h-8 text-sm"
                />
                <Input
                  type="text"
                  placeholder="Title"
                  value={contact.title}
                  onChange={(e) => updateContact(index, "title", e.target.value)}
                  className="h-8 text-sm"
                />
                <div className="flex gap-2">
                  <Input
                    type="email"
                    placeholder="Email"
                    value={contact.email}
                    onChange={(e) => updateContact(index, "email", e.target.value)}
                    className="flex-1 h-8 text-sm"
                  />
                  <Input
                    type="tel"
                    placeholder="Phone"
                    value={contact.phone}
                    onChange={(e) => updateContact(index, "phone", e.target.value)}
                    className="flex-1 h-8 text-sm"
                  />
                </div>
                <label className="flex items-center gap-2 text-sm cursor-pointer">
                  <Checkbox
                    checked={contact.onsite}
                    onCheckedChange={(checked) => {
                      const updated = [...contacts];
                      updated[index] = { ...updated[index], onsite: checked === true };
                      setContacts(updated);
                    }}
                  />
                  Onsite contact
                </label>
              </div>
            ))}
            <Button type="button" variant="outline" size="sm" className="text-xs" onClick={addContactRow}>
              <Plus className="h-3 w-3 mr-1" />
              Add Contact
            </Button>
          </fieldset>
        )}

        {/* Actions */}
        <div className="flex gap-3 pt-2">
          <Button variant="outline" asChild>
            <Link href={routes.incidents}>Cancel</Link>
          </Button>
          <Button type="submit" disabled={processing}>
            {processing ? "Creating..." : "Create Request"}
          </Button>
        </div>
      </form>
    </AppLayout>
  );
}

function UserChecklistSection({
  label,
  users,
  selectedIds,
  onToggle,
}: {
  label: string;
  users: NewIncidentAssignableUser[];
  selectedIds: number[];
  onToggle: (id: number) => void;
}) {
  return (
    <div>
      <div className="flex items-center gap-1.5 mb-1">
        <Building2 className="h-3 w-3 text-muted-foreground" />
        <span className="text-xs font-semibold text-muted-foreground">{label}</span>
      </div>
      <div className="rounded border border-input">
        {users.map((u) => {
          const selected = selectedIds.includes(u.id);
          return (
            <div
              key={u.id}
              role="checkbox"
              aria-checked={selected}
              tabIndex={0}
              onClick={() => onToggle(u.id)}
              onKeyDown={(e) => { if (e.key === " " || e.key === "Enter") { e.preventDefault(); onToggle(u.id); } }}
              className={`flex items-center gap-2 px-3 py-1.5 text-sm cursor-pointer hover:bg-muted transition-colors border-b border-input last:border-b-0 select-none ${
                selected ? "bg-accent" : ""
              }`}
            >
              <div className={`h-4 w-4 rounded border flex items-center justify-center shrink-0 ${
                selected ? "bg-primary border-primary" : "border-input"
              }`}>
                {selected && <Check className="h-3 w-3 text-primary-foreground" />}
              </div>
              <span className="text-foreground">{u.full_name}</span>
              <span className="text-muted-foreground text-xs ml-auto">{u.role_label}</span>
            </div>
          );
        })}
      </div>
    </div>
  );
}
