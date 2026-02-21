import { Link, useForm, usePage } from "@inertiajs/react";
import { FormEvent, useState } from "react";
import { AlertTriangle, Building2, ChevronDown, ChevronUp, Plus, Trash2 } from "lucide-react";
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
  const [showAdvanced, setShowAdvanced] = useState(false);

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
  const errorEntries = Object.entries(errors);

  const isEmergency = data.project_type === "emergency_response";

  const currentUsers: NewIncidentAssignableUser[] = data.property_id ? (property_users[data.property_id] || []) : [];
  const mitigationUsers = currentUsers.filter((u) => u.org_type === "mitigation");
  const pmUsers = currentUsers.filter((u) => u.org_type === "pm");

  const handleOrgChange = (orgId: string) => {
    setSelectedOrgId(orgId);
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
    const current = data.additional_user_ids;
    if (current.includes(userId)) {
      setData("additional_user_ids", current.filter((id) => id !== userId));
    } else {
      setData("additional_user_ids", [...current, userId]);
    }
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

      <form onSubmit={handleSubmit} className="mx-auto max-w-3xl space-y-5 pb-8">
        {errorEntries.length > 0 && (
          <div className="rounded-md border border-destructive/40 bg-destructive/10 px-4 py-3">
            <p className="text-sm font-semibold text-destructive">Please fix the highlighted fields.</p>
            <ul className="mt-1 text-sm text-destructive/90">
              {errorEntries.slice(0, 4).map(([field, message]) => (
                <li key={field}>{message}</li>
              ))}
            </ul>
          </div>
        )}

        <section className="rounded-lg border border-border bg-card p-5 space-y-4 shadow-sm">
          <h2 className="text-base font-semibold text-foreground">Incident Basics</h2>

          {organizations.length > 1 && (
            <div className="space-y-2">
              <Label>Organization *</Label>
              <Select value={selectedOrgId} onValueChange={handleOrgChange}>
                <SelectTrigger className="h-11 sm:h-10">
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

          <div className="space-y-2">
            <Label>Property *</Label>
            <Select value={data.property_id} onValueChange={handlePropertyChange}>
              <SelectTrigger className="h-11 sm:h-10">
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

          <FormField
            id="job_id"
            label="Job ID"
            value={data.job_id}
            onChange={(v) => setData("job_id", v)}
            error={errors.job_id}
            hint="Optional reference number"
          />

          <fieldset className="space-y-2">
            <Label asChild><legend>Project Type *</legend></Label>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
              {project_types.map((pt) => (
                <label
                  key={pt.value}
                  className={`flex items-center gap-2 rounded border px-3 py-3 text-sm cursor-pointer transition-colors ${
                    data.project_type === pt.value
                      ? "border-primary bg-accent text-accent-foreground"
                      : "border-input bg-background text-foreground hover:bg-muted/50"
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
                  <span className={`h-4 w-4 rounded-full border-2 flex items-center justify-center flex-shrink-0 ${
                    data.project_type === pt.value ? "border-primary" : "border-muted-foreground"
                  }`}>
                    {data.project_type === pt.value && (
                      <span className="h-2 w-2 rounded-full bg-primary" />
                    )}
                  </span>
                  {pt.label}
                </label>
              ))}
            </div>
            {errors.project_type && <p className="text-sm text-destructive">{errors.project_type}</p>}
          </fieldset>

          {isEmergency && (
            <div className="rounded-md border border-amber-300 bg-amber-50 px-4 py-3 text-sm text-amber-900">
              <div className="flex items-start gap-2">
                <AlertTriangle className="h-4 w-4 mt-0.5 flex-shrink-0 text-amber-700" />
                <div>
                  <p className="font-semibold">Emergency escalation is enabled.</p>
                  <p className="mt-0.5">Submitting this request immediately notifies the on-call chain and starts time-based escalation.</p>
                </div>
              </div>
            </div>
          )}
        </section>

        <section className="rounded-lg border border-border bg-card p-5 space-y-4 shadow-sm">
          <h2 className="text-base font-semibold text-foreground">Situation Details</h2>

          <div className="space-y-2">
            <Label>Damage Type *</Label>
            <Select value={data.damage_type} onValueChange={(v) => setData("damage_type", v)}>
              <SelectTrigger className="h-11 sm:h-10">
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

          <Button
            type="button"
            variant="outline"
            size="sm"
            className="h-11 sm:h-10 gap-1.5"
            onClick={() => setShowAdvanced((prev) => !prev)}
          >
            {showAdvanced ? <ChevronUp className="h-4 w-4" /> : <ChevronDown className="h-4 w-4" />}
            {showAdvanced ? "Hide Optional Details" : "Show Optional Details"}
          </Button>

          {showAdvanced && (
            <div className="space-y-4 rounded-md border border-border bg-muted/35 p-4">
              <FormField
                id="do_not_exceed_limit"
                label="Emergency Do Not Exceed Limit"
                value={data.do_not_exceed_limit}
                onChange={(v) => setData("do_not_exceed_limit", v)}
                error={errors.do_not_exceed_limit}
                hint="Dollar amount, if applicable"
              />

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

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
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
            </div>
          )}
        </section>

        {can_assign && data.property_id && currentUsers.length > 0 && (
          <section className="rounded-lg border border-border bg-card p-5 space-y-4 shadow-sm">
            <h2 className="text-base font-semibold text-foreground">Team Assignment</h2>
            <p className="text-sm text-muted-foreground">
              Assigned members are notified immediately. Uncheck anyone who should not be added to this incident.
            </p>

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

            <p className="text-sm text-muted-foreground">{data.additional_user_ids.length} member{data.additional_user_ids.length !== 1 ? "s" : ""} selected</p>
          </section>
        )}

        {can_manage_contacts && (
          <section className="rounded-lg border border-border bg-card p-5 space-y-3 shadow-sm">
            <h2 className="text-base font-semibold text-foreground">Contacts</h2>
            <p className="text-sm text-muted-foreground">Add on-site or property contacts who should be visible to the response team.</p>

            {contacts.map((contact, index) => (
              <div key={index} className="rounded-md border border-border bg-muted/20 p-3 space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-sm font-medium text-foreground">Contact {index + 1}</span>
                  <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    className="h-10 w-10 sm:h-8 sm:w-8 p-0 text-muted-foreground hover:text-destructive"
                    onClick={() => removeContact(index)}
                    aria-label={`Remove contact ${index + 1}`}
                  >
                    <Trash2 className="h-4 w-4" />
                  </Button>
                </div>
                <Input
                  type="text"
                  placeholder="Name *"
                  value={contact.name}
                  onChange={(e) => updateContact(index, "name", e.target.value)}
                  className="h-11 sm:h-10"
                />
                <Input
                  type="text"
                  placeholder="Title"
                  value={contact.title}
                  onChange={(e) => updateContact(index, "title", e.target.value)}
                  className="h-11 sm:h-10"
                />
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                  <Input
                    type="email"
                    placeholder="Email"
                    value={contact.email}
                    onChange={(e) => updateContact(index, "email", e.target.value)}
                    className="h-11 sm:h-10"
                  />
                  <Input
                    type="tel"
                    placeholder="Phone"
                    value={contact.phone}
                    onChange={(e) => updateContact(index, "phone", e.target.value)}
                    className="h-11 sm:h-10"
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
            <Button type="button" variant="outline" size="sm" className="h-11 sm:h-10" onClick={addContactRow}>
              <Plus className="h-4 w-4 mr-1" />
              Add Contact
            </Button>
          </section>
        )}

        <div className="sticky bottom-0 rounded-md border border-border bg-card/95 backdrop-blur px-4 py-3 shadow-sm">
          <div className="flex gap-3">
            <Button variant="outline" className="h-11 sm:h-10" asChild>
              <Link href={routes.incidents}>Cancel</Link>
            </Button>
            <Button type="submit" className="h-11 sm:h-10" disabled={processing}>
              {processing ? "Creating..." : "Create Request"}
            </Button>
          </div>
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
    <fieldset className="space-y-2">
      <legend className="flex items-center gap-1.5 text-sm font-semibold text-foreground">
        <Building2 className="h-4 w-4 text-muted-foreground" />
        {label}
      </legend>
      <div className="rounded-md border border-input bg-background overflow-hidden">
        {users.map((u) => {
          const selected = selectedIds.includes(u.id);
          const fieldId = `assign-${label.toLowerCase().replace(/\s+/g, "-")}-${u.id}`;
          return (
            <label
              key={u.id}
              htmlFor={fieldId}
              className={`flex items-center gap-3 px-3 py-3 text-sm cursor-pointer transition-colors border-b border-input last:border-b-0 hover:bg-muted/35 ${
                selected ? "bg-accent/70" : ""
              }`}
            >
              <Checkbox
                id={fieldId}
                checked={selected}
                onCheckedChange={() => onToggle(u.id)}
                aria-label={`Assign ${u.full_name}`}
              />
              <span className="text-foreground">{u.full_name}</span>
              <span className="text-muted-foreground text-sm ml-auto">{u.role_label}</span>
            </label>
          );
        })}
      </div>
    </fieldset>
  );
}
